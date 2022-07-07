defmodule Clubhouse.Accounts.UserToken do
  @moduledoc """
  A variable user token entity, used to store unique session
  tokens for example.
  """

  use Ecto.Schema
  import Ecto.Query
  alias Clubhouse.Accounts.UserToken

  @session_validity_in_days 60

  schema "users_tokens" do
    field :token, :string, redact: true
    field :context, :string

    belongs_to :user, Clubhouse.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Generates a token that is used to authenticate a user.
  Storing tokens in the database allows them to be expired
  or immediately revoked.
  """
  def build_session_token(user) do
    token = %{token: Nanoid.generate(), context: "session", user_id: user.id}
    Ecto.build_assoc(user, :user_tokens, token)
  end

  @doc """
  A query to check if the session token is valid, returning the associated user.
  """
  def verify_session_token_query(token) do
    from token in token_and_context_query(token, "session"),
      join: user in assoc(token, :user),
      where: token.inserted_at > ago(@session_validity_in_days, "day"),
      select: user
  end

  @doc """
  Returns the token struct for the given token value and context.
  """
  def token_and_context_query(token, context) do
    from UserToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  def user_and_contexts_query(user, :all) do
    from t in UserToken, where: t.user_id == ^user.id
  end

  def user_and_contexts_query(user, [_ | _] = contexts) do
    from t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts
  end
end
