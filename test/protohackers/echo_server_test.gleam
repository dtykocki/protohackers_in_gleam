import gleeunit
import gleeunit/should
import gleam/erlang/charlist
import protohackers/tcp.{Active, Binary, Mode}

pub fn main() {
  gleeunit.main()
}

pub fn test_echo_back() {
  assert Ok(socket) =
    tcp.connect(
      charlist.from_string("localhost"),
      5001,
      [Mode(Binary), Active(False)],
    )

  socket
  |> tcp.send(<<"foo":utf8>>)
  |> should.be_ok()

  socket
  |> tcp.send(<<"bar":utf8>>)
  |> should.be_ok()

  socket
  |> tcp.shutdown()
  |> should.be_ok()

  assert Ok(data) = tcp.receive(socket, 0, 5000)
  should.equal(data, <<"foobar":utf8>>)
}
