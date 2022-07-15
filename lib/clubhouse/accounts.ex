defmodule Clubhouse.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query

  alias Clubhouse.Accounts.{User, UserToken, UserNotifier}
  alias Clubhouse.Repo
  alias Clubhouse.Discourse
  alias ClubhouseWeb.Endpoint

  ## Database getters

  @doc """
  Gets a single user.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user by their email.
  """
  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  ## User registration

  @doc """
  Creates a new user. Only the email is necessary, but most attributes
  are accepted. The username is not cast, as it should be added
  lazily on-demand.

  ## Examples

      iex> register_user(%{email: email})
      {:ok, %User{}}

      iex> register_user(%{})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert(on_conflict: :nothing)
  end

  @doc """
  Update a user's profile, such as their name and SCIPER number.
  """
  def update_user_profile!(user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update!()
  end

  @doc """
  Check whether the username is already taken by another user.
  """
  def username_available?(username) do
    User
    |> where(username: ^username)
    |> Repo.exists?()
    |> Kernel.not()
  end

  ## Session

  @doc """
  Generate a `session` user token for the given user, inserting it
  into the database and returning the unique token value.
  """
  def generate_user_session_token!(user) do
    user_token = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    user_token.token
  end

  @doc """
  Returns the user associated with a given `session` user token, or nil
  if the session token is not valid.
  """
  def get_user_by_session_token(token) do
    query = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes a `session` user token.
  """
  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the welcome email to the given user.
  """
  def deliver_user_welcome(%User{} = user) do
    UserNotifier.deliver_welcome(user)
  end

  ## Suspension

  @doc """
  Invalidates all user sessions and emails them a suspension notice.
  """
  def suspend_user(user, reason \\ "Unknown") do
    user =
      user
      |> User.suspended_changeset(%{suspended: true})
      |> Repo.update!()

    invalidate_sessions(user)
    disconnect_all_live_views(user)
    UserNotifier.deliver_suspension_notice(user, reason)
    Discourse.log_out(user)
  end

  @doc """
  Removes the suspension status and emails them a reinstatement notice.
  """
  def reinstate_user(user) do
    user
    |> User.suspended_changeset(%{suspended: false})
    |> Repo.update!()
    |> UserNotifier.deliver_reinstatement_notice()
  end

  defp invalidate_sessions(user) do
    UserToken
    |> where(user_id: ^user.id)
    |> Repo.update_all(set: [inserted_at: ~U[1970-01-01 00:00:00Z]])
  end

  defp disconnect_all_live_views(user) do
    Repo.transaction(
      fn ->
        disconnect_all_live_views_stream(user)
      end,
      timeout: :infinity
    )
  end

  defp disconnect_all_live_views_stream(user) do
    UserToken
    |> where(user_id: ^user.id)
    |> Repo.stream()
    |> Stream.map(&disconnect_live_view/1)
    |> Stream.run()
  end

  defp disconnect_live_view(user_token) do
    Endpoint.broadcast("users_sessions:#{user_token.token}", "disconnect", %{})
  end
end
