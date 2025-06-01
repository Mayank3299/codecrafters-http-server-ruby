# frozen_string_literal: true

require 'socket'
# require 'byebug'

# You can use print statements as follows for debugging, they'll be visible when running tests.
print('Logs from your program will appear here!')

# Uncomment this to pass the first stage
#
server = TCPServer.new('localhost', 4221)

def handle_request(socket)
  request = []
  while (line = socket.gets)
    break if line == "\r\n"

    request << line.chomp
  end
  request.join.split("\r\n")
  # debugger
  request_line = request.first.split(' ')
  path = request_line[1]
  if path.start_with?('/echo')
    body = path[6..]
    socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{body.length}\r\n\r\n#{body}"
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
end

while (client_socket = server.accept)
  Thread.new(client_socket) do |socket|
    handle_request(socket)
  end
end
