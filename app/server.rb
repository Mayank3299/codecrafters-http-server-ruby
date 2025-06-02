# frozen_string_literal: true

require 'socket'
require 'zlib'

server = TCPServer.new('localhost', 4221)

def get_encoding(request)
  encodings = request.find { |header| header.start_with?('Accept-Encoding:') }&.split(': ', 2)&.last
  'gzip' if encodings&.split(', ')&.include?('gzip')
end

def connection_type(request)
  header = request.find { |h| h.downcase.start_with?('connection:') }
  value = header&.split(':', 2)&.last&.strip&.downcase
  value == 'close' ? 'close' : 'keep-alive'
end

def handle_request(socket)
  request = []
  while (line = socket.gets)
    line = line.chomp
    break if line.empty?

    request << line
  end

  return false if request.empty?

  request_line = request.first.split(' ')
  request_method = request_line[0]
  path = request_line[1]
  conn_type = connection_type(request)

  response_headers = []
  response_headers << "Connection: #{conn_type}"

  if request_method == 'GET'
    if path.start_with?('/echo')
      body = path[6..] || ''
      encoding = get_encoding(request)
      if encoding
        compressed_body = Zlib.gzip(body)
        response_headers << 'Content-Type: text/plain'
        response_headers << "Content-Encoding: #{encoding}"
        response_headers << "Content-Length: #{compressed_body.bytesize}"
        socket.write "HTTP/1.1 200 OK\r\n#{response_headers.join("\r\n")}\r\n\r\n#{compressed_body}"
      else
        response_headers << 'Content-Type: text/plain'
        response_headers << "Content-Length: #{body.bytesize}"
        socket.write "HTTP/1.1 200 OK\r\n#{response_headers.join("\r\n")}\r\n\r\n#{body}"
      end
    elsif path.start_with?('/user-agent')
      ua = request.find { |ele| ele.start_with?('User-Agent:') }&.split(': ', 2)&.last || ''
      response_headers << 'Content-Type: text/plain'
      response_headers << "Content-Length: #{ua.bytesize}"
      socket.write "HTTP/1.1 200 OK\r\n#{response_headers.join("\r\n")}\r\n\r\n#{ua}"
    elsif path.start_with?('/files')
      begin
        filename = path.split('/').last
        directory = ARGV[1]
        file_path = File.join(directory.to_s, filename)
        content = File.read(file_path)
        response_headers << 'Content-Type: application/octet-stream'
        response_headers << "Content-Length: #{content.bytesize}"
        socket.write "HTTP/1.1 200 OK\r\n#{response_headers.join("\r\n")}\r\n\r\n#{content}"
      rescue Errno::ENOENT
        socket.write "HTTP/1.1 404 Not Found\r\n#{response_headers.join("\r\n")}\r\n\r\n"
      end
    elsif path == '/'
      socket.write "HTTP/1.1 200 OK\r\n#{response_headers.join("\r\n")}\r\n\r\n"
    else
      socket.write "HTTP/1.1 404 Not Found\r\n#{response_headers.join("\r\n")}\r\n\r\n"
    end
  elsif request_method == 'POST' && path.start_with?('/files')
    filename = path.split('/').last
    content_length = request.find { |h| h.start_with?('Content-Length:') }&.split(': ', 2)&.last.to_i
    body = socket.read(content_length)
    directory = ARGV[1]
    file_path = File.join(directory.to_s, filename)
    File.write(file_path, body)
    socket.write "HTTP/1.1 201 Created\r\n#{response_headers.join("\r\n")}\r\n\r\n"
  else
    socket.write "HTTP/1.1 400 Bad Request\r\n#{response_headers.join("\r\n")}\r\n\r\n"
  end

  conn_type != 'close' # keep connection alive only if not "close"
end

# Accept and handle multiple connections with keep-alive logic
while (client_socket = server.accept)
  Thread.new(client_socket) do |socket|
    while handle_request(socket)
      # continue processing requests
    end
  rescue StandardError => e
    puts "Error: #{e.class} - #{e.message}"
  ensure
    socket.close
  end
end
