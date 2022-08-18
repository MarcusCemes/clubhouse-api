defmodule ClubhouseWeb.UserAuth do
  @moduledoc """
  Common authentication logic that can be invoked from different
  controllers. Most functions take the connection struct and
  redirect the user as necessary for the action.
  """

  import Plug.Conn
  import Phoenix.Controller
  import Clubhouse.Utility, only: [service_env: 1]

  alias Clubhouse.Accounts
  alias Clubhouse.Accounts.User
  alias Clubhouse.Bridge
  alias Clubhouse.Utility
  alias ClubhouseWeb.Endpoint

  @session_cookie "clubhouse_session"
  @session_age_secs 2_630_000
  @token_age_secs 3600
  @token_namespace "new_user_attrs"
  @website_callback "/auth/callback"

  ## Plugs

  @doc """
  Plug that will require the user is authenticated, otherwise
  returning a 401 status code.
  """
  def ensure_authenticated(conn, _opts) do
    case conn.assigns[:current_user] do
      %User{} -> conn
      _ -> halt_unauthenticated(conn)
    end
  end

  @doc """
  Plug that requires that the user has chosen a username.
  """
  def ensure_has_username(conn, _opts) do
    case conn.assigns[:current_user] do
      %User{username: username} when is_binary(username) -> conn
      _ -> halt_no_username(conn)
    end
  end

  defp halt_unauthenticated(conn) do
    conn
    |> put_status(:unauthorized)
    |> put_view(ClubhouseWeb.SessionView)
    |> render("unauthenticated.json")
    |> halt()
  end

  defp halt_no_username(conn) do
    conn
    |> put_status(:precondition_required)
    |> put_view(ClubhouseWeb.SessionView)
    |> render("no-username.json")
    |> halt()
  end

  ## Functions

  @doc """
  Start the sign-in flow, requesting a sign-in key from the bridge
  and redirecting the user to the next step.

  If the bridge is being mocked, this will redirect to the internal
  completion route.
  """
  def initiate_authentication(then) do
    url = service_env(:website_url) <> @website_callback
    query = URI.encode_query(%{then: then})
    url |> Utility.append_query_string(query) |> Bridge.create_request()
  end

  @doc """
  Complete the authentication process. Creates or updates the user
  profile, generates a session and redirects to the appropriate
  completion endpoint.
  """
  @spec complete_authentication(Plug.Conn.t(), String.t(), String.t()) ::
          {:ok, Plug.Conn.t()} | {:error, :suspended | :bad_key} | {:error, :new_user, String.t()}
  def complete_authentication(conn, key, auth_check) do
    case Bridge.fetch_attributes(key, auth_check) do
      {:ok, tequila_attrs} ->
        attrs = Bridge.parse_attrs(tequila_attrs)
        user = Accounts.get_user_by_email(attrs.email)

        case user do
          %User{suspended: false} ->
            session_token =
              user
              |> Accounts.update_user_profile!(attrs)
              |> Accounts.generate_user_session_token!()

            conn =
              conn
              |> set_cookie(@session_cookie, session_token)
              |> assign(:current_user, user)

            {:ok, conn}

          %{suspended: true} ->
            {:error, :suspended}

          nil ->
            {:error, :new_user, encrypt(attrs)}
        end

      _ ->
        {:error, :bad_key}
    end
  end

  defp encrypt(data) do
    Phoenix.Token.encrypt(Endpoint, @token_namespace, data)
  end

  @doc """
  Complete the account creation, adding the user to the database,
  generating the user's first session token.

  ## Examples
      iex> confirm_account_creation(token)
      {:ok, %Plug.Conn{}}


      iex> confirm_account_creation("an_invalid_token")
      {:error, :bad_token}
  """
  @spec confirm_account_creation(Plug.Conn.t(), String.t()) ::
          {:ok, Plug.Conn.t(), User.t()} | {:error, :bad_token} | {:error, :expired}
  def confirm_account_creation(conn, token) do
    case decrypt(token) do
      {:ok, attrs} ->
        user =
          case Accounts.create_user(attrs) do
            {:ok, user} -> user
            # If the account is already confirmed, Ecto will return {:error, %Changeset{}}
            {:error, _} -> Accounts.get_user_by_email(attrs[:email])
          end

        session_token = Accounts.generate_user_session_token!(user)
        conn = set_cookie(conn, @session_cookie, session_token)
        {:ok, conn, user}

      {:error, :invalid} ->
        {:error, :bad_token}

      {:error, :expired} ->
        {:error, :expired}
    end
  end

  defp decrypt(token) do
    Phoenix.Token.decrypt(Endpoint, @token_namespace, token, max_age: @token_age_secs)
  end

  @doc """
  Check whether the username has already been taken by a user.
  """
  @spec username_available?(String.t()) :: boolean()
  def username_available?(username) do
    Accounts.username_available?(username)
  end

  # Set the user's username if it is nil, a.k.a. has not yet been
  # chosen, otherwise an error will be returned.
  @spec choose_username(User.t(), String.t()) ::
          :ok | {:error, :taken | :already_chosen | :invalid}
  def choose_username(user, username) do
    Accounts.choose_username(user, username)
  end

  @doc """
  Deletes the session token cookie and database entry.
  """
  @spec sign_out(Plug.Conn.t()) :: Plug.Conn.t()
  def sign_out(conn) do
    if session_token = conn.cookies[@session_cookie] do
      if user = Accounts.get_user_by_session_token(session_token) do
        %{"action" => "sign_out", "id" => user.id}
        |> Clubhouse.UserWorker.new()
        |> Oban.insert()
      end

      Accounts.delete_session_token(session_token)
    end

    delete_resp_cookie(conn, @session_cookie, session_cookie_opts())
  end

  @doc """
  Authenticates the user by looking into the session token, populating
  the `current_user` assign.
  """
  def fetch_current_user(conn, _opts) do
    if token = conn.cookies[@session_cookie] do
      user = Accounts.get_user_by_session_token(token)
      assign(conn, :current_user, user)
    else
      conn
    end
  end

  defp set_cookie(conn, key, value) do
    put_resp_cookie(conn, key, value, session_cookie_opts())
  end

  defp session_cookie_opts() do
    base_opts = [max_age: @session_age_secs, http_only: true]

    if :prod ==
         Application.fetch_env!(:clubhouse, :env) do
      [domain: Endpoint.host(), secure: true] ++ base_opts
    else
      base_opts
    end
  end
end
