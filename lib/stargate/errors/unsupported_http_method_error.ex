defmodule Stargate.Errors.UnsupportedHttpMethodError do
  @moduledoc """
  The error that is raised when an unsupported HTTP Method is used in a request
  to the `Stargate` Webserver.
  """
  defexception [:message]

  @impl true
  @spec exception(http_method :: binary) :: Exception.t()
  def exception(http_method) do
    message = """
    The request was made using the #{http_method} HTTP Method,
    which is currently unsupported by the Stargate Webserver.

    The currently supported HTTP Methods are:
      - GET
      - HEAD
      - POST
      - PUT
      - DELETE
      - CONNECT
      - OPTIONS
      - TRACE
      - PATCH
    """

    %__MODULE__{message: message}
  end
end
