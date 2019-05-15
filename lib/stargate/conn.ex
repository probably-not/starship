defmodule Stargate.Conn do
  @type body :: String.t()
  @type headers :: [{binary, binary}]
  @type http_ver :: String.t()
  @type query :: map
  @type type :: String.t()

  @type t :: %__MODULE__{
          body: body,
          headers: headers,
          http_ver: http_ver,
          path: String.t(),
          query: query,
          type: type
        }

  defstruct body: "",
            headers: [],
            http_ver: "HTTP/1.1",
            path: "/",
            query: %{},
            type: "GET"
end
