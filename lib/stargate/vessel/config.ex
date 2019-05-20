defmodule Stargate.Vessel.Config do
  @moduledoc """
  The configuration struct for the `Stargate` Webserver.
  """

  @type t :: %__MODULE__{
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
