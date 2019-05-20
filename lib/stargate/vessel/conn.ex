defmodule Stargate.Vessel.Conn do
  @moduledoc """
  The connection struct for the `Stargate` Webserver.
  """

  @type body :: binary
  @type headers :: [{binary, binary}]
  @type http_version :: :"HTTP/0.9" | :"HTTP/1.0" | :"HTTP/1.1" | :"HTTP/2.0" | :"HTTP/3.0"
  @type query :: map
  @type method :: :GET | :HEAD | :POST | :PUT | :DELETE | :CONNECT | :OPTIONS | :TRACE | :PATCH

  @type t :: %__MODULE__{
          body: body,
          headers: headers,
          http_version: http_version,
          path: binary,
          query: query,
          method: method
        }

  defstruct body: "",
            headers: [],
            http_version: :"HTTP/1.1",
            path: "/",
            query: %{},
            method: :GET
end
