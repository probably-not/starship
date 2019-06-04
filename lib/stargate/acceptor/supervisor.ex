defmodule Stargate.Acceptor.Supervisor do
  @moduledoc """
  The TCP Acceptor supervisor, which spawns and supervises `Stargate.Acceptor`
  processes to handle the requests to the `Stargate` Webserver.
  """

  require Logger

  @spec start(map) :: no_return
  def start(config) do
    Process.flag(:trap_exit, true)
    loop(config)
  end

  @spec loop(map) :: no_return
  def loop(config) do
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
        Logger.warn(["Exit from Stargate.Acceptor ", inspect(pid), ", Reason: ", inspect(reason)])
        loop(config)

      unknown ->
        throw({__MODULE__, :unknown_message, unknown})
    end
  end
end
