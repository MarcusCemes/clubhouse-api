defmodule ClubhouseWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Clubhouse.Accounts
  alias Clubhouse.Bridge
  alias ClubhouseWeb.Router.Helpers, as: Routes

  @confirm_attrs_exp_seconds 3600

  @doc """
  Start the sign-in flow, requesting a sign-in key from the bridge
  and redirecting the user to the next step.

  If the bridge is being mocked, this will redirect to the internal
  completion route.
  """
  def initiate_authentication(conn, return_path \\ nil) do
    return_url = Routes.user_session_url(conn, :callback)
    {:ok, key} = Bridge.create_request(return_url)

    conn
    |> put_session(:user_return_to, return_path)
    |> redirect(external: sign_in_url(conn, key))
  end

  defp sign_in_url(conn, key) do
    if mocked_bridge?() do
      Routes.user_session_url(conn, :callback) <> "?key=#{key}&auth_check"
    else
      tequila_url() <> "/requestauth?requestkey=#{key}"
    end
  end

  defp mocked_bridge?() do
    bridge_env = Application.fetch_env!(:clubhouse, :bridge)
    Keyword.get(bridge_env, :mock) == true
  end

  defp tequila_url() do
    services = Application.fetch_env!(:clubhouse, :services)
    Keyword.get(services, :tequila_url)
  end

  @doc """
  Complete the authentication process. Creates or updates the user
  profile, generates a session and redirects to the appropriate
  completion endpoint.
  """
  def complete_authentication(conn, key, auth_check) do
    {:ok, attrs} = Bridge.fetch_attributes(key, auth_check)
    parsed_attrs = Bridge.parse_attrs(attrs)
    user = Accounts.get_user_by_email(parsed_attrs.email)

    case user do
      nil ->
        exp = DateTime.add(DateTime.utc_now(), @confirm_attrs_exp_seconds, :second)
        payload = Clubhouse.Utility.wrap_payload(parsed_attrs, exp)

        conn
        |> put_session(:confirm_attrs, payload)
        |> redirect(to: Routes.user_session_path(conn, :welcome))

      %{suspended: false} ->
        user = Accounts.update_user_profile!(user, parsed_attrs)
        log_in_user(conn, user)

      %{suspended: true} ->
        conn
        |> put_flash(
          :error,
          "Your account has been suspended, send us an email to make an appeal"
        )
        |> redirect(to: "/")
    end
  end

  @doc """
  Finalise the account creation, adding the user to the database
  and starting a session for the user.
  """
  def confirm_account_creation(conn) do
    if attrs = get_session(conn, :confirm_attrs) do
      case Clubhouse.Utility.unwrap_payload(attrs) do
        {:ok, attrs} ->
          {:ok, user} = Accounts.create_user(attrs)
          Accounts.deliver_user_welcome(user)
          log_in_user(conn, user)

        {:error, :expired} ->
          conn
          |> put_flash(:error, "Account attributes expired, try again.")
          |> redirect(to: "/")
      end
    else
      conn
      |> put_flash(:error, "You have no pending account creation")
      |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user) do
    token = Accounts.generate_user_session_token!(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> redirect(to: user_return_to || "/")
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn, return_path \\ nil) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      ClubhouseWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> put_flash(:success, "You have been signed out")
    |> redirect(to: return_path || Routes.page_path(conn, :index))
  end

  @doc """
  Authenticates the user by looking into the session token, populating
  the `current_user` assign.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      {nil, conn}
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: "/")
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> maybe_store_return_to()
      |> redirect(to: Routes.user_session_path(conn, :sign_in))
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn
end
