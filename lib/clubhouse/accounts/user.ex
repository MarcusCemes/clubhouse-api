defmodule Clubhouse.Accounts.User do
  @moduledoc """
  The user entity, storing the user's credentials and profile.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @uid_alphabet "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  @uid_length 6

  schema "users" do
    field :uid, :string
    field :email, :string

    field :first_name, :string
    field :last_name, :string
    field :username, :string
    field :student_id, :integer

    field :suspended, :boolean, default: false

    has_many :user_tokens, Clubhouse.Accounts.UserToken

    timestamps(type: :utc_datetime)
  end

  @doc """
  Constructs a user's name, using their first and last name
  if available and defaulting to the email address.
  """
  def name(%{first_name: first_name, last_name: last_name})
      when is_binary(first_name) and is_binary(last_name),
      do: "#{first_name} #{last_name}"

  # EPFL addresses should be clean, without multiple "@" symbols
  def name(%{email: email}), do: email |> String.split("@") |> hd()

  @doc """
  A user changeset for registering a new user.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:uid, :email, :first_name, :last_name, :student_id])
    |> maybe_add_uid()
    |> validate_uid()
    |> validate_email()
    |> validate_profile()
    |> validate_required(:suspended)
  end

  defp maybe_add_uid(changeset) do
    case get_field(changeset, :uid) do
      nil -> put_change(changeset, :uid, generate_uid())
      _ -> changeset
    end
  end

  # As the UIDs are relatively short, there is a risk of collision.
  # Trying three randomly generated UIDs is simpler than using deterministic
  # IDs such as hashids, and makes it impossible to gain information
  # about the number of registered users (with a known salt), etc.
  defp generate_uid(retries \\ 3)
  defp generate_uid(0), do: raise("Unable to generate new user UID")

  defp generate_uid(retries) when retries > 0 do
    uid = Nanoid.generate(@uid_length, @uid_alphabet)

    Clubhouse.Accounts.User
    |> where(uid: ^uid)
    |> Clubhouse.Repo.exists?()
    |> if(do: generate_uid(retries - 1), else: uid)
  end

  defp validate_uid(changeset) do
    changeset
    |> validate_required(:uid)
    |> validate_length(:uid, is: @uid_length)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Clubhouse.Repo)
    |> unique_constraint(:email)
  end

  defp validate_profile(changeset) do
    changeset
    |> validate_length(:first_name, max: 100)
    |> validate_length(:last_name, max: 100)
    |> validate_number(:student_id, greater_than_or_equal: 0, less_than_or_equal: 999_999)
  end

  @doc """
  A user changeset for updating a user's profile, such as their name
  or student ID.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :student_id])
    |> validate_profile()
  end

  @doc """
  A user changeset for updating or setting the username.
  """
  def username_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:username])
    |> validate_length(:username, min: 4, max: 30, message: "must be between 4 and 30 characters")
    |> validate_format(:username, ~r/^[A-za-z\d_.]+$/,
      message: "must contain only contain letters, numbers, underscores and periods"
    )
    |> unique_constraint(:username)
  end

  @doc """
  A user changeset to change the suspension status.
  """
  def suspended_changeset(user, attrs) do
    user
    |> cast(attrs, [:suspended])
    |> validate_required(:suspended)
  end
end
