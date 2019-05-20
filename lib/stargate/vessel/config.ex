defmodule Stargate.Vessel.Config do
  @type t :: %__MODULE__{
          buf: binary,
          hosts: map,
          ip: tuple,
          listen_socket: Port.t(),
          port: non_neg_integer,
          socket: Port.t(),
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
