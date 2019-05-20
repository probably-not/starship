defmodule Stargate.Acceptor do
  @moduledoc false

  require Logger

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
        Logger.error("INET Async Error: #{inspect(error)}")
        loop(config)

      unknown ->
        throw({__MODULE__, :unknown_message, unknown})
    end
  end
end
