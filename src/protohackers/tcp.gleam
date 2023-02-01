pub type SocketMode {
  Binary
}

pub opaque type ListenSocket {
  ListenSocket
}

pub opaque type Socket {
  Socket
}

pub type Reason {
  Closed
  Timeout
  Badarg
  Terminated
  Overflow
}

pub type TcpOption {
  Mode(SocketMode)
  Reuseaddr(Bool)
  Active(Bool)
  ExitOnClose(Bool)
}

pub external fn listen(
  port: Int,
  options: List(TcpOption),
) -> Result(ListenSocket, Reason) =
  "gen_tcp" "listen"

pub external fn accept(socket: ListenSocket) -> Result(Socket, Reason) =
  "gen_tcp" "accept"

pub external fn receive(
  socket: Socket,
  length: Int,
  timeout: Int,
) -> Result(BitString, Reason) =
  "gen_tcp" "recv"

pub external fn send(socket: Socket, data: BitString) -> Result(Nil, Reason) =
  "tcp_ffi" "send"

pub external fn close(socket: Socket) -> Result(Nil, Reason) =
  "tcp_ffi" "close"
