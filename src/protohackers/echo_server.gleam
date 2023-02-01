import gleam/io
import gleam/int
import gleam/string
import gleam/bit_builder
import gleam/function
import gleam/order.{Gt}
import gleam/otp/actor
import gleam/erlang/process.{Subject}
import protohackers/tcp.{
  Active, Binary, Closed, ExitOnClose, ListenSocket, Mode, Overflow, Reason,
  Reuseaddr, Socket,
}

type State {
  State(socket: ListenSocket, subject: Subject(AcceptMessage))
}

pub type AcceptMessage {
  AcceptMessage
}

pub fn start(_args) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let subject = process.new_subject()
      let selector =
        process.selecting(process.new_selector(), subject, function.identity)

      let options = [
        Mode(Binary),
        Reuseaddr(True),
        Active(False),
        ExitOnClose(False),
      ]
      let port = 5001

      ["Echo server listening on localhost:", int.to_string(port), " ✨"]
      |> string.concat()
      |> io.println()

      case tcp.listen(port, options) {
        Ok(socket) -> {
          process.send(subject, AcceptMessage)
          actor.Ready(State(socket, subject), selector)
        }
        Error(err) -> actor.Failed(string.inspect(err))
      }
    },
    init_timeout: 1000,
    loop: fn(message, state) {
      case message {
        AcceptMessage ->
          case tcp.accept(state.socket) {
            Ok(socket) -> {
              handle_connection(socket)
              process.send(state.subject, AcceptMessage)
              actor.Continue(state)
            }
            Error(err) -> actor.Stop(process.Abnormal(string.inspect(err)))
          }

        _message -> actor.Stop(process.Abnormal("Unknown message type"))
      }
    },
  ))
}

fn handle_connection(socket: Socket) {
  case recv_until_closed(socket, <<"":utf8>>, 0) {
    Ok(data) -> {
      assert Ok(Nil) = tcp.send(socket, data)
      assert Ok(Nil) = tcp.close(socket)
    }
    Error(err) -> Error(err)
  }
}

fn recv_until_closed(socket, buffer, buffered_size) -> Result(BitString, Reason) {
  case tcp.receive(socket, 0, 10_000) {
    Ok(data) -> {
      let data_size =
        data
        |> bit_builder.from_bit_string()
        |> bit_builder.byte_size()
      let buffered_size = buffered_size + data_size

      case int.compare(buffered_size, 104_400) {
        Gt -> Error(Overflow)
        _ -> {
          let new_buffer =
            data
            |> bit_builder.from_bit_string()
            |> bit_builder.prepend(buffer)
            |> bit_builder.to_bit_string
          recv_until_closed(socket, new_buffer, buffered_size)
        }
      }
    }

    Error(Closed) -> Ok(buffer)
    Error(err) -> Error(err)
  }
}
