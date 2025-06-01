# frozen_string_literal: true

require 'socket'
# require 'byebug'

# You can use print statements as follows for debugging, they'll be visible when running tests.
print('Logs from your program will appear here!')

# Uncomment this to pass the first stage
#
server = TCPServer.new('localhost', 4221)
while (client_socket = server.accept)
  Thread.new(client_socket) do |socket|
    request = []
    while (line = socket.gets)
      break if line == "\r\n"

      request << line.chomp
    end
    request.join.split("\r\n")
    # debugger
    request_line = request.first.split(' ')

    if request_line[1].start_with?('/echo')
      body = request_line[1][6..]
      socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{body.length}\r\n\r\n#{body}"
    elsif request_line[1].start_with?('/user-agent')
      ua = request.find { |ele| ele.start_with?('User-Agent') }.split(': ').last
      socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{ua.length}\r\n\r\n#{ua}"
    elsif request_line[1] == '/'
      socket.puts "HTTP/1.1 200 OK\r\n\r\n"
    else
      socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
    end
  end
end
