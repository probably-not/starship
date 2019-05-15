defmodule Stargate.Acceptor.Supervisor do
  def loop(config) do
    Process.flag(:trap_exit, true)
    loop_1(config)
  end

  def loop_1(config) do
    acceptors = Map.get(config, :acceptors, [])
    to_spawn = :erlang.system_info(:schedulers) - length(acceptors)

    acceptors =
      if to_spawn > 0 do
        pids =
          Enum.map(1..to_spawn, fn _ -> :erlang.spawn_link(Stargate.Acceptor, :loop, [config]) end)

        acceptors ++ pids
      else
        acceptors
      end

    config = Map.put(config, :acceptors, acceptors)

    receive do
      {:EXIT, pid, r} ->
        IO.inspect({:stargate_acceptor_died, pid, r})
        loop_1(config)

      ukn ->
        throw({__MODULE__, :ukn_msg, ukn})
    end
  end
end
