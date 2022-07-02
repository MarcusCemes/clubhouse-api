defmodule Clubhouse.Accounts.User do
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
  def set_profile(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :student_id])
    |> validate_profile()
  end

  @doc """
  A user changeset for updating or setting the username.
  """
  def username_changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_length(:username, min: 4, max: 30, message: "must be between 4 and 30 characters")
    |> validate_format(:username, ~r/^[A-za-z\d_.]+$/,
      message: "must contain only contain letters, numbers, underscores and periods"
    )
    |> unsafe_validate_unique(:username, Clubhouse.Repo)
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

  # defp validate_password(changeset, opts) do
  #   changeset
  #   |> validate_required([:password])
  #   |> validate_length(:password, min: 12, max: 72)
  #   # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
  #   # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
  #   # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
  #   |> maybe_hash_password(opts)
  # end

  # defp maybe_hash_password(changeset, opts) do
  #   hash_password? = Keyword.get(opts, :hash_password, true)
  #   password = get_change(changeset, :password)

  #   if hash_password? && password && changeset.valid? do
  #     changeset
  #     # If using Bcrypt, then further validate it is at most 72 bytes long
  #     |> validate_length(:password, max: 72, count: :bytes)
  #     |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
  #     |> delete_change(:password)
  #   else
  #     changeset
  #   end
  # end

  # @doc """
  # A user changeset for changing the email.

  # It requires the email to change otherwise an error is added.
  # """
  # def email_changeset(user, attrs) do
  #   user
  #   |> cast(attrs, [:email])
  #   |> validate_email()
  #   |> case do
  #     %{changes: %{email: _}} = changeset -> changeset
  #     %{} = changeset -> add_error(changeset, :email, "did not change")
  #   end
  # end

  # @doc """
  # A user changeset for changing the password.

  # ## Options

  #   * `:hash_password` - Hashes the password so it can be stored securely
  #     in the database and ensures the password field is cleared to prevent
  #     leaks in the logs. If password hashing is not needed and clearing the
  #     password field is not desired (like when using this changeset for
  #     validations on a LiveView form), this option can be set to `false`.
  #     Defaults to `true`.
  # """
  # def password_changeset(user, attrs, opts \\ []) do
  #   user
  #   |> cast(attrs, [:password])
  #   |> validate_confirmation(:password, message: "does not match password")
  #   |> validate_password(opts)
  # end

  # @doc """
  # Confirms the account by setting `confirmed_at`.
  # """
  # def confirm_changeset(user) do
  #   now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  #   change(user, confirmed_at: now)
  # end

  # @doc """
  # Verifies the password.

  # If there is no user or the user doesn't have a password, we call
  # `Bcrypt.no_user_verify/0` to avoid timing attacks.
  # """
  # def valid_password?(%Clubhouse.Accounts.User{hashed_password: hashed_password}, password)
  #     when is_binary(hashed_password) and byte_size(password) > 0 do
  #   Bcrypt.verify_pass(password, hashed_password)
  # end

  # def valid_password?(_, _) do
  #   Bcrypt.no_user_verify()
  #   false
  # end

  # @doc """
  # Validates the current password otherwise adds an error to the changeset.
  # """
  # def validate_current_password(changeset, password) do
  #   if valid_password?(changeset.data, password) do
  #     changeset
  #   else
  #     add_error(changeset, :current_password, "is not valid")
  #   end
  # end
end
