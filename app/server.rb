# frozen_string_literal: true

require 'socket'
require 'byebug'

# You can use print statements as follows for debugging, they'll be visible when running tests.
print('Logs from your program will appear here!')

# Uncomment this to pass the first stage
#
server = TCPServer.new('localhost', 4221)
client_socket, _client_address = server.accept
client_socket.puts "HTTP/1.1 200 OK\r\n\r\n"

request = client_socket.gets
request = request.split(' ')
if request[1] != '/'
  client.puts "HTTP/1.1 404 Not Found\r\n\r\n"
else
  client.puts "HTTP/1.1 200 OK\r\n\r\n"
end
