defmodule Stargate do
  @moduledoc """
  The Stargate Webserver.

  This module is the starting point for the Stargate Webserver.

  If you are an end user of Stargate, this is the only thing that you need to worry about.
  Here is where you will `warp_in` your configuration (or use the default configuration provided) and start the webserver.
  """

  alias Stargate.Errors

  @default_configuration %{
    ip: {0, 0, 0, 0},
    port: 4000,
    hosts: %{
      {:http, "*"} => {Stargate.Handler.Wildcard.Http, %{}},
      {:ws, "*"} => {Stargate.Handler.Wildcard.Websocket, %{}}
    }
  }

  @doc """
  Starts the Stargate webserver with the default configuration.

  The default configuration listens on port 4000, with wildcard handlers that receive requests for any host,
  `Stargate.Handler.Wildcard.Http` and `Stargate.Handler.Wildcard.Websocket`.

  ## Examples
      iex> pid = Stargate.warp_in()
      iex> is_pid(pid)
      true
  """
  @spec warp_in :: pid
  def warp_in, do: warp_in(@default_configuration)

  @doc ~S"""
  Starts the webserver with the desired configuration.

  The `config` passed to this function should be a map
  containing any configurations that you would like to
  start your webserver with.

  ## Examples
      iex(1)> config =
      ...(1)>  %{
      ...(1)>    ip: {0, 0, 0, 0},
      ...(1)>    port: 4000,
      ...(1)>    hosts: %{
      ...(1)>      {:http, "*"} => {Stargate.Handler.Wildcard.Http, %{}},
      ...(1)>      {:ws, "*"} => {Stargate.Handler.Wildcard.Websocket, %{}}
      ...(1)>    },
      ...(1)>    ssl_opts: nil
      ...(1)>  }
      %{
        ip: {0, 0, 0, 0},
        port: 4000,
        hosts: %{
          {:http, "*"} => {Stargate.Handler.Wildcard.Http, %{}},
          {:ws, "*"} => {Stargate.Handler.Wildcard.Websocket, %{}}
        },
        ssl_opts: nil
      }
      iex(2)> pid = Stargate.warp_in(config)
      iex(3)> is_pid(pid)
      true
  """
  @spec warp_in(config :: map) :: pid
  def warp_in(config) when is_map(config) do
    config = validate_config!(config)

    if config.ssl_opts != nil do
      :ssl.start()
    end

    if elem(config.ip, 0) == :local do
      path = elem(config.ip, 1)
      File.rm(path)
    end

    listen_args = Map.get(config, :listen_args, [])

    {:ok, lsocket} =
      :gen_tcp.listen(
        config.port,
        listen_args ++
          [
            {:ifaddr, config.ip},
            {:active, false},
            {:reuseaddr, true},
            {:nodelay, true},
            {:recbuf, 4096},
            {:exit_on_close, false},
            :binary
          ]
      )

    config = Map.merge(config, %{listen_socket: lsocket, buf: <<>>})

    :erlang.spawn(Stargate.Acceptor.Supervisor, :loop, [config])
  end

  @spec validate_config!(config :: map) :: map
  defp validate_config!(%{ip: ip, port: port, hosts: hosts} = config)
       when is_tuple(ip) and is_integer(port) and is_map(hosts) do
    config
    |> Map.put_new(:hosts, Map.merge(@default_configuration.hosts, hosts))
    |> Map.put_new(:ssl_opts, nil)
  end

  @spec validate_config!(config :: map) :: map
  defp validate_config!(%{ip: ip, port: port} = config)
       when is_tuple(ip) and is_integer(port) do
    config
    |> Map.put(:hosts, @default_configuration.hosts)
    |> Map.put_new(:ssl_opts, nil)
  end

  defp validate_config!(config) do
    raise Errors.InvalidConfigurationError,
      provided_config: config,
      default_config: @default_configuration
  end
end
