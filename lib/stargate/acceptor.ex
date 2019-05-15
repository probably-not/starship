defmodule Stargate.Acceptor do
  def loop(config) do
    {:ok, _} = :prim_inet.async_accept(config.listen_socket, -1)

    receive do
      {:inet_async, _ListenSocket, _, {:ok, csocket}} ->
        pid = :erlang.spawn(Stargate.Vessel, :loop, [config])

        :inet_db.register_socket(csocket, :inet_tcp)
        :ok = :gen_tcp.controlling_process(csocket, pid)
        send(pid, {:pass_socket, csocket})

        loop(config)

      {:inet_async, _, _, error} ->
        IO.inspect({:inet_async_error, error})
        loop(config)

      ukn ->
        throw({__MODULE__, :ukn_msg, ukn})
    end
  end
end
