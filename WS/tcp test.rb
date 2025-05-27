require 'socket'
require 'test/unit'

class ServerTest< Test::Unit::TestCase
  def test_tcp_request_response
    server = TCPSocket.open('localhost', 4242)

    request = 'Hello, server!'
    server.puts(request)

    response = server.gets
    assert_equal "Hey, client!\n", response

    server.close
  end
end