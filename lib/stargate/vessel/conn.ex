defmodule Stargate.Vessel.Conn do
  @moduledoc """
  The connection struct for the `Stargate` Webserver.
  """

  alias Stargate.Errors

  @type body :: binary
  @type headers :: [{binary, binary}]
  @type http_version :: :"HTTP/0.9" | :"HTTP/1.0" | :"HTTP/1.1" | :"HTTP/2.0" | :"HTTP/3.0"
  @type query :: map
  @type method :: :GET | :HEAD | :POST | :PUT | :DELETE | :CONNECT | :OPTIONS | :TRACE | :PATCH

  @http_versions %{
    "HTTP/0.9" => :"HTTP/0.9",
    "HTTP/1.0" => :"HTTP/1.0",
    "HTTP/1.1" => :"HTTP/1.1",
    "HTTP/2.0" => :"HTTP/2.0",
    "HTTP/3.0" => :"HTTP/3.0"
  }

  @http_methods %{
    "GET" => :GET,
    "HEAD" => :HEAD,
    "POST" => :POST,
    "PUT" => :PUT,
    "DELETE" => :DELETE,
    "CONNECT" => :CONNECT,
    "OPTIONS" => :OPTIONS,
    "TRACE" => :TRACE,
    "PATCH" => :PATCH
  }

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

  @spec http_version!(binary) :: atom | no_return
  def http_version!(version) do
    try do
      v = Map.fetch!(@http_versions, version)

      if valid_http_version?(v) do
        v
      else
        raise Errors.UnsupportedHttpVersionError, v
      end
    rescue
      KeyError ->
        stacktrace = System.stacktrace()
        reraise Errors.UnsupportedHttpVersionError, version, stacktrace
    end
  end

  @spec valid_http_version?(atom) :: boolean
  defp valid_http_version?(:"HTTP/1.1"), do: true
  defp valid_http_version?(:"HTTP/1.0"), do: true
  defp valid_http_version?(:"HTTP/0.9"), do: true
  defp valid_http_version?(_), do: false

  @spec http_method!(binary) :: atom | no_return
  def http_method!(method) do
    try do
      Map.fetch!(@http_methods, method)
    rescue
      KeyError ->
        stacktrace = System.stacktrace()
        reraise Errors.UnsupportedHttpMethodError, method, stacktrace
    end
  end
end
