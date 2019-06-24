defmodule Starship.Reactor.Config do
  @moduledoc """
  The configuration struct for the `Starship` Webserver.
  """

  alias Starship.Reactor.Config

  @typedoc """
  The configuration that is passed to the Webserver when started,
  and subsequently passed to every TCP process when spawned.

  The configuration contains both general server level configuration
  values (IP address, port, hosts, etc.) and TCP Socket level configuration
  values (socket process, socket state, socket handler, etc.)
  """
  @type t :: %Config{
          buf: binary,
          hosts: map,
          ip: tuple,
          listen_socket: port(),
          port: non_neg_integer,
          socket: port(),
          transport: atom,
          handler: module,
          state: :ws | :http_body | nil
        }

  defstruct buf: "",
            hosts: %{},
            ip: {},
            listen_socket: nil,
            port: 0,
            socket: nil,
            transport: :gen_tcp,
            handler: nil,
            state: nil
end
