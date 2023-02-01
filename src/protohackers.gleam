import gleam/erlang/process
import gleam/otp/supervisor.{add, worker}
import protohackers/echo_server

pub fn main() {
  assert Ok(_) =
    supervisor.start(fn(children) {
      children
      |> add(worker(echo_server.start))
    })

  process.sleep_forever()
}
