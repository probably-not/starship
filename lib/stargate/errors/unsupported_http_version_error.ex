defmodule Stargate.Errors.UnsupportedHttpVersionError do
  @moduledoc """
  The error that is raised when an unsupported HTTP Version is used in a request
  to the `Stargate` Webserver.
  """
  defexception [:message]

  @impl true
  @spec exception(http_version :: binary) :: map
  def exception(http_version) do
    message = """
    The request was made using #{http_version},
    which is currently unsupported by the Stargate Webserver.

    The currently supported HTTP Versions are: HTTP/1.1.
    """

    %__MODULE__{message: message}
  end
end