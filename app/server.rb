# frozen_string_literal: true

require 'socket'
# require 'byebug'

# You can use print statements as follows for debugging, they'll be visible when running tests.
print('Logs from your program will appear here!')

# Uncomment this to pass the first stage
#
server = TCPServer.new('localhost', 4221)

def get_encoding(request)
  encodings = request.find { |header| header.start_with?('Accept-Encoding:') }&.split(': ')&.last
  'gzip' if encodings&.split(', ')&.include?('gzip')
end

def handle_request(socket)
  request = []
  while (line = socket.gets)
    break if line == "\r\n"

    request << line.chomp
  end
  # debugger
  request.join.split("\r\n")
  request_line = request.first.split(' ')
  request_method = request_line[0]
  path = request_line[1]
  if request_method == 'GET'
    if path.start_with?('/echo')
      body = path[6..]
      encoding = get_encoding(request)
      if encoding
        socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Encoding: #{encoding}\r\nContent-Length: #{body.length}\r\n\r\n#{body}"
      else
        socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{body.length}\r\n\r\n#{body}"
      end
    elsif path.start_with?('/user-agent')
      ua = request.find { |ele| ele.start_with?('User-Agent') }.split(': ').last
      socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{ua.length}\r\n\r\n#{ua}"
    elsif path.start_with?('/files')
      begin
        filename = path.split('/').last
        directory = ARGV[1]
        file = File.open(File.join(directory.to_s, filename), 'r')
        socket.puts "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: #{file.size}\r\n\r\n#{file.read}"
      rescue Errno::ENOENT
        socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
      end
    elsif path == '/'
      socket.puts "HTTP/1.1 200 OK\r\n\r\n"
    else
      socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
    end
  elsif request_method == 'POST'
    if path.start_with?('/files')
      filename = path.split('/').last
      content_length = request.find { |header| header.start_with?('Content-Length:') }.split(' ').last.to_i
      body = socket.gets(content_length)
      directory = ARGV[1]
      file_path = File.join(directory.to_s, filename)
      File.write(file_path, body)
      socket.puts "HTTP/1.1 201 Created\r\n\r\n"
    end
  end
end

while (client_socket = server.accept)
  Thread.new(client_socket) do |socket|
    handle_request(socket)
  end
end
