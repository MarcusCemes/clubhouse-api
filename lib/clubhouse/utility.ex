defmodule Clubhouse.Utility do
  @moduledoc """
  Generic utility functions that are not specific to a context.
  """

  @doc """
  Wrap a payload with an expiry date. The payload can then be
  unwrapped with `unwrap_payload()`, which returns an :ok tuple
  or an :error tuple if the expiry date has passed.any()

  This is like a "poor man's JWT", requiring the wrapped payload to
  be stored somewhere where it cannot be tampered with, such as a signed
  session cookie.
  """
  def wrap_payload(payload, exp) do
    {DateTime.to_iso8601(exp), payload}
  end

  @doc """
  Unwraps the payload, returning an :ok/:error tuple based on
  whether the expiry date has passed.
  """
  def unwrap_payload({exp, payload}) do
    with {:ok, datetime, _} <- DateTime.from_iso8601(exp),
         :gt <- DateTime.compare(datetime, DateTime.utc_now()) do
      {:ok, payload}
    else
      {:error, _} -> {:error, :invalid_datetime}
      _ -> {:error, :expired}
    end
  end
end
