defmodule Stargate.Acceptor.Supervisor do
  @moduledoc false

  require Logger

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
      {:EXIT, pid, reason} ->
        Logger.warn("Exit from Stargate.Acceptor #{inspect(pid)}, Reason: #{inspect(reason)}")
        loop_1(config)

      unknown ->
        throw({__MODULE__, :unknown_message, unknown})
    end
  end
end
