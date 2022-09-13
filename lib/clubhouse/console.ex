defmodule Clubhouse.Console do
  @moduledoc """
  Contains useful operations that can be run from a remote console
  session to a running Clubhouse API application.
  """

  alias ClubhouseWeb.UserAuth

  @doc """
  Generates a custom attributes token that can be used to create an account,
  for examples to allow a non-Tequila user to sign in.
  """
  # @spec gen_confirm_token(String.t(), String.t()) :: map(token: String.t())
  def gen_confirm_token(email, first_name, last_name) do
    %{
      token:
        UserAuth.encrypt_token(%{
          email: email,
          first_name: first_name,
          last_name: last_name
        })
    }
  end
end
