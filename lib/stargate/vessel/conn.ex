defmodule Stargate.Vessel.Conn do
  @moduledoc """
  The connection struct for the `Stargate` Webserver.
  """

  alias Stargate.Errors

  @type body :: binary
  @type header :: {binary, binary}
  @type headers :: [header]
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

  @spec http_version!(binary) :: http_version | no_return
  def http_version!(version) do
    v = Map.fetch!(@http_versions, version)
    validate_http_version!(v)
  rescue
    KeyError ->
      stacktrace = System.stacktrace()
      reraise Errors.HttpVersionNotSupportedError, version, stacktrace
  end

  @spec validate_http_version!(http_version) :: http_version | no_return
  defp validate_http_version!(version) do
    if valid_http_version?(version) do
      version
    else
      raise Errors.HttpVersionNotSupportedError, version
    end
  end

  @spec valid_http_version?(http_version) :: boolean
  defp valid_http_version?(:"HTTP/1.1"), do: true
  defp valid_http_version?(:"HTTP/1.0"), do: true
  defp valid_http_version?(:"HTTP/0.9"), do: true
  # defp valid_http_version?(:"HTTP/2.0"), do: true
  # defp valid_http_version?(:"HTTP/3.0"), do: true
  defp valid_http_version?(_), do: false

  @spec http_method!(binary) :: method | no_return
  def http_method!(method) do
    Map.fetch!(@http_methods, method)
  rescue
    KeyError ->
      stacktrace = System.stacktrace()
      reraise Errors.MethodNotAllowedError, method, stacktrace
  end
end
