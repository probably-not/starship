defmodule Stargate.Acceptor do
  @moduledoc """
  The TCP Acceptor used by the `Stargate` Webserver.

  A `Stargate.Acceptor` is started by the `Stargate.Acceptor.Supervisor` per open socket.
  """

  require Logger

  @doc """
  The main event loop for the `Stargate.Acceptor` process.

  This loop listens for messages and spawns a `Stargate.Vessel`
  process per request that arrives on the socket.
  """
  @spec loop(map) :: no_return
  def loop(config) do
    {:ok, _} = :prim_inet.async_accept(config.listen_socket, -1)

    receive do
      {:inet_async, _listen_socket, _, {:ok, csocket}} ->
        pid = :erlang.spawn(Stargate.Vessel, :loop, [config])

        :inet_db.register_socket(csocket, :inet_tcp)
        :ok = :gen_tcp.controlling_process(csocket, pid)
        send(pid, {:pass_socket, csocket})

        loop(config)

      {:inet_async, _, _, error} ->
        Logger.error(["INET Async Error: ", inspect(error)])
        loop(config)

      unknown ->
        throw({__MODULE__, :unknown_message, unknown})
    end
  end
end
