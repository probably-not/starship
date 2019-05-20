defmodule Stargate.Errors.InvalidHandlerTypeError do
  @moduledoc """
  The error that is raised when an invalid
  handler type is passed to `Stargate.Vessel.get_host_handler/4`.
  """
  defexception [:message]

  @impl true
  @spec exception(handler_type :: binary) :: Exception.t()
  def exception(handler_type) do
    message = """
    The request was made using the #{handler_type} handler type,
    which is currently unsupported by the Stargate Webserver.

    The current supported handler types are Websocket and HTTP.
    """

    %__MODULE__{message: message}
  end
end
