defmodule Stargate do
  @moduledoc """
  The Stargate Webserver.

  This module is the starting point for the Stargate Webserver.
  """

  @default_configuration %{
    ip: {0, 0, 0, 0},
    port: 4000,
    hosts: %{
      {:http, "*"} => {Stargate.Handler.Wildcard.Http, %{}},
      {:ws, "*"} => {Stargate.Handler.Wildcard.Websocket, %{}}
    },
    ssl_opts: nil
  }

  defmodule InvalidConfigurationError do
    defexception [:message, :provided_configuration, :default_configuration]

    @impl true
    def exception(attrs) do
      message = """
      Your configuration is invalid.
      Please see the default configuration
      and make sure that your configuration
      contains all of the necessary values.
      """

      %InvalidConfigurationError{
        message: message,
        provided_configuration: attrs[:provided_config],
        default_configuration: attrs[:default_config]
      }
    end
  end

  @doc """
  Starts the Stargate webserver with the default configuration.

  The default configuration listens on port 4000, with wildcard handlers that receive requests for any host,
  `Stargate.Handler.Wildcard.Http` and `Stargate.Handler.Wildcard.Websocket`.

  ## Examples
      iex> pid = Stargate.warp_in()
      iex> is_pid(pid)
      true
  """
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

  defp validate_config!(%{ip: ip, port: port, hosts: hosts} = config)
       when is_tuple(ip) and is_integer(port) and is_map(hosts) do
    Map.put_new(config, :hosts, @default_configuration.hosts)
  end

  defp validate_config!(config) do
    raise InvalidConfigurationError,
      provided_config: config,
      default_config: @default_configuration
  end
end
