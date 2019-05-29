defmodule Stargate do
  @moduledoc """
  The Stargate Webserver.

  This module is the starting point for the Stargate Webserver.

  If you are an end user of Stargate, this is the only thing that you need to worry about.
  Here is where you will `warp_in` your configuration (or use the default configuration provided) and start the webserver.

  ## A Note On SSL

  You may pass in options to the configuration of Stargate that allow you to use SSL secured connections to connect to the server.

  The SSL options are passed directly into the Erlang SSL Application when the webserver is started, and on all requests,
  an SSL handshake will be initiated using the certificates and keys that you provided in the initial configuration.

  The SSL options should look something like this:
  ```elixir
  ssl_opts = [{:cacertfile, "cacerts.pem"}, {:certfile, "cert.pem"}, {:keyfile, "key.pem"}]
  ```
  """

  alias Stargate.Errors

  @default_configuration %{
    ip: {0, 0, 0, 0},
    port: 4000,
    hosts: %{
      {:http, "*"} => {Stargate.Handler.Wildcard.Http, %{}},
      {:ws, "*"} => {Stargate.Handler.Wildcard.Websocket, %{}}
    },
    ssl_opts: nil
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

  @doc """
  Validates the configuration and adds any of the missing required information.

    ## Examples
      iex(1)> config = %{}
      %{}
      iex(2)> Stargate.validate_config!(config)
      %{
        hosts: %{
          {:http, "*"} => {Stargate.Handler.Wildcard.Http, %{}},
          {:ws, "*"} => {Stargate.Handler.Wildcard.Websocket, %{}}
        },
        ip: {0, 0, 0, 0},
        port: 4000,
        ssl_opts: nil
      }
      iex(3)> config =
      ...(3)>  %{
      ...(3)>    ip: {1, 2, 3, 4}
      ...(3)>  }
      %{
        ip: {1, 2, 3, 4}
      }
      iex(4)> Stargate.validate_config!(config)
      %{
        hosts: %{
          {:http, "*"} => {Stargate.Handler.Wildcard.Http, %{}},
          {:ws, "*"} => {Stargate.Handler.Wildcard.Websocket, %{}}
        },
        ip: {1, 2, 3, 4},
        port: 4000,
        ssl_opts: nil
      }
      iex(5)> config =
      ...(5)>  %{
      ...(5)>    ip: {1, 2, 3, 4},
      ...(5)>    port: 4001
      ...(5)>  }
      %{
        ip: {1, 2, 3, 4},
        port: 4001
      }
      iex(6)> Stargate.validate_config!(config)
      %{
        hosts: %{
          {:http, "*"} => {Stargate.Handler.Wildcard.Http, %{}},
          {:ws, "*"} => {Stargate.Handler.Wildcard.Websocket, %{}}
        },
        ip: {1, 2, 3, 4},
        port: 4001,
        ssl_opts: nil
      }
      iex(7)> config =
      ...(7)>  %{
      ...(7)>    ip: {1, 2, 3, 4},
      ...(7)>    port: 4001,
      ...(7)>    hosts: %{
      ...(7)>      {:http, "*"} => {A.Different.Handler, %{}}
      ...(7)>    }
      ...(7)>  }
      %{
        hosts: %{
          {:http, "*"} => {A.Different.Handler, %{}},
        },
        ip: {1, 2, 3, 4},
        port: 4001
      }
      iex(8)> Stargate.validate_config!(config)
      %{
        hosts: %{
          {:http, "*"} => {A.Different.Handler, %{}},
          {:ws, "*"} => {Stargate.Handler.Wildcard.Websocket, %{}}
        },
        ip: {1, 2, 3, 4},
        port: 4001,
        ssl_opts: nil
      }
      iex(9)> config =
      ...(9)>  %{
      ...(9)>    ip: {1, 2, 3, 4},
      ...(9)>    port: 4001,
      ...(9)>    hosts: %{
      ...(9)>      {:http, "wow"} => {A.Different.Handler, %{}}
      ...(9)>    }
      ...(9)>  }
      %{
        hosts: %{
          {:http, "wow"} => {A.Different.Handler, %{}},
        },
        ip: {1, 2, 3, 4},
        port: 4001
      }
      iex(10)> Stargate.validate_config!(config)
      %{
        hosts: %{
          {:http, "wow"} => {A.Different.Handler, %{}},
          {:http, "*"} => {Stargate.Handler.Wildcard.Http, %{}},
          {:ws, "*"} => {Stargate.Handler.Wildcard.Websocket, %{}}
        },
        ip: {1, 2, 3, 4},
        port: 4001,
        ssl_opts: nil
      }
  """
  @spec validate_config!(config :: map) :: map
  def validate_config!(%{ip: ip, port: port, hosts: hosts} = config)
      when is_tuple(ip) and is_integer(port) and is_map(hosts) do
    config
    |> Map.put(:hosts, Map.merge(@default_configuration.hosts, hosts))
    |> Map.put_new(:ssl_opts, @default_configuration.ssl_opts)
  end

  def validate_config!(%{ip: ip, port: port} = config)
      when is_tuple(ip) and is_integer(port) do
    config
    |> Map.put(:hosts, @default_configuration.hosts)
    |> Map.put_new(:ssl_opts, @default_configuration.ssl_opts)
  end

  def validate_config!(config) when is_map(config) do
    config
    |> Map.put_new(:ip, @default_configuration.ip)
    |> Map.put_new(:port, @default_configuration.port)
    |> Map.put(:hosts, @default_configuration.hosts)
    |> Map.put_new(:ssl_opts, @default_configuration.ssl_opts)
  end

  def validate_config!(config) do
    raise Errors.InvalidConfigurationError,
      provided_config: config,
      default_config: @default_configuration
  end
end
