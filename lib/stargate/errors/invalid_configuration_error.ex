defmodule Stargate.Errors.InvalidConfigurationError do
  @moduledoc """
  The error that is raised when an invalid
  configuration is passed to `Stargate.warp_in/1`.
  """
  defexception [:message]

  @impl true
  def exception(attrs) do
    message = """
    Your configuration is invalid.
    Please see the default configuration
    and make sure that your configuration
    contains all of the necessary values.

    Provided Configuration: #{inspect(attrs[:provided_config])}
    Default Configuration: #{inspect(attrs[:default_config])}
    """

    %__MODULE__{message: message}
  end
end
