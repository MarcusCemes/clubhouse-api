defmodule Clubhouse.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Clubhouse.Repo

  alias Clubhouse.Accounts.{User, UserToken, UserNotifier}

  ## Database getters

  @doc """
  Gets a user by email, returning the User struct or nil.

  ## Examples
      iex> get_user_by_email("user@epfl.ch")
      %User{}

      iex> get_user_by_email("unknown_user@epfl.ch")
      nil
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      # Raises Ecto.NoResultsError
  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user. Only the email is necessary, but all profile
  attributes are also accepted.

  The username is not cast, as it should be added lazily on-demand.

  ## Examples

      iex> register_user(%{email: email})
      {:ok, %User{}}

      iex> register_user(%{})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  ## Examples

      iex> change_user_registration(user, %{ email: "new.email@epfl.ch" })
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    user_token = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    user_token.token
  end

  @doc """
  Gets the user with the given session token. Returns the user
  struct or nil.
  """
  def get_user_by_session_token(token) do
    query = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes a session UserToken based on the token value.
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
    UserNotifier.deliver_welcome(user, extract_name(user))
  end

  defp extract_name(%User{first_name: first_name, last_name: last_name})
       when is_binary(first_name) and is_binary(last_name) do
    "#{first_name} #{last_name}"
  end

  defp extract_name(%User{email: email}), do: email
end
