defmodule Clubhouse.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query

  alias Clubhouse.Accounts.{User, UserToken, UserNotifier}
  alias Clubhouse.Repo
  alias Clubhouse.Discourse

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
  Creates a new user with the given attributes, storing them in the database
  and sending them the welcome email.

  Only the email is necessary, but other attributes are accepted as well
  apart from the username which should be set lazily on-demand.
  """
  @spec create_user(map(), boolean()) :: {:ok, User.t()} | {:error, :exists}
  def create_user(attrs, send_welcome_email? \\ true) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        if send_welcome_email?, do: deliver_user_welcome(user)
        {:ok, user}

      {:error, %Ecto.Changeset{}} ->
        {:error, :exists}
    end
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

  @doc """
  Changes the user's username to their desired value if their
  username is not already set and is not already taken.
  """
  @spec choose_username(User.t(), String.t()) ::
          :ok | {:error, :invalid | :taken | :already_chosen}
  def choose_username(user, username) do
    case Repo.transaction(fn -> set_username_if_nil(user, username) end) do
      {:ok, result} -> result
      {:error, :rollback} -> {:error, :taken}
    end
  end

  defp set_username_if_nil(user, username) do
    user = Repo.reload(user)

    if user.username == nil do
      user
      |> User.username_changeset(%{username: username})
      |> Repo.update()
      |> case do
        {:ok, %User{}} -> :ok
        {:error, %Ecto.Changeset{}} -> {:error, :invalid}
      end
    else
      {:error, :already_chosen}
    end
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
  @spec suspend_user(User.t(), String.t(), boolean()) :: User.t()
  def suspend_user(user, reason \\ "Unknown", deliver_email? \\ true) do
    user
    |> User.suspended_changeset(%{suspended: true})
    |> Repo.update!()
    |> tap(fn user ->
      invalidate_sessions(user)

      if deliver_email? do
        UserNotifier.deliver_suspension_notice(user, reason)
      end

      Discourse.log_out(user)
    end)
  end

  @doc """
  Removes the suspension status and emails them a reinstatement notice.
  """
  @spec reinstate_user(User.t(), boolean()) :: User.t()
  def reinstate_user(user, deliver_email? \\ true) do
    user
    |> User.suspended_changeset(%{suspended: false})
    |> Repo.update!()
    |> tap(fn user ->
      if deliver_email? do
        UserNotifier.deliver_reinstatement_notice(user)
      end
    end)
  end

  defp invalidate_sessions(user) do
    UserToken
    |> where(user_id: ^user.id)
    |> Repo.update_all(set: [inserted_at: ~U[1970-01-01 00:00:00Z]])
  end
end
