defmodule Stargate.Vessel.Websocket.ResponseCodes do
  @moduledoc """
  Response Codes to be returned by a Websocket close frame.
  """

  def normal_close, do: <<1000::integer-2>>
  def going_away, do: <<1001::integer-2>>
  def terminating_due_to_protocol_error, do: <<1002::integer-2>>
  def terminating_due_to_unacceptable_data, do: <<1003::integer-2>>
  def reserved_for_future_use, do: <<1004::integer-2>>
  def reserved_for_no_status_code_present, do: <<1005::integer-2>>
  def reserved_for_abnormal_closing, do: <<1006::integer-2>>
  def terminating_due_to_not_consistent_data, do: <<1007::integer-2>>
  def terminating_due_to_violated_policy, do: <<1008::integer-2>>
  def terminating_due_to_message_too_big_to_process, do: <<1009::integer-2>>
  def client_terminating_due_to_unnegotiated_extension, do: <<1010::integer-2>>
  def terminating_due_to_unexpected_condition, do: <<1011::integer-2>>
  def reserved_for_failed_tls_handshake, do: <<1015::integer-2>>
end
