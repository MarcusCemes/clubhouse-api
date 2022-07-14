defmodule ClubhouseWeb.UserAuth do
  @moduledoc """
  Common authentication logic that can be invoked from different
  controllers. Most functions take the connection struct and
  redirect the user as necessary for the action.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Clubhouse.Accounts
  alias Clubhouse.Bridge
  alias Clubhouse.Discourse
  alias ClubhouseWeb.Router.Helpers, as: Routes

  @confirm_attrs_exp_seconds 360

  ## Plugs

  @doc """
  Plug that will redirect the user to sign-in if the are not
  authenticated, returning them to the current request URL
  when complete.
  """
  def authenticate_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      {:ok, key} =
        conn
        |> Routes.user_session_url(:callback, then: request_url(conn))
        |> Bridge.create_request()

      conn
      |> redirect_to_authenticate(key)
      |> halt()
    end
  end

  defp redirect_to_authenticate(conn, key) do
    if Bridge.mocked_bridge?() do
      redirect(conn,
        to:
          Routes.user_session_path(conn, :callback,
            key: key,
            auth_check: "check",
            then: request_url(conn)
          )
      )
    else
      redirect(conn, external: "#{tequila_url()}/requestauth?requestkey=#{key}")
    end
  end

  @doc """
  Plug that will prompt the user to choose a username if needed.
  """
  def ensure_username(conn, _opts) do
    if conn.assigns[:current_user].username do
      conn
    else
      then = request_url(conn)
      to = Routes.live_path(conn, ClubhouseWeb.UsernameLive, then: then)
      redirect(conn, to: to)
    end
  end

  ## Functions

  @doc """
  Start the sign-in flow, requesting a sign-in key from the bridge
  and redirecting the user to the next step.

  If the bridge is being mocked, this will redirect to the internal
  completion route.
  """
  def initiate_authentication(conn, return_url) do
    {:ok, key} = Bridge.create_request(return_url)
    redirect(conn, external: sign_in_url(key, return_url))
  end

  defp sign_in_url(key, return_url) do
    if Bridge.mocked_bridge?() do
      return_url <> "?key=#{key}&auth_check"
    else
      tequila_url() <> "/requestauth?requestkey=#{key}"
    end
  end

  defp tequila_url() do
    Application.fetch_env!(:clubhouse, :services)
    |> Keyword.get(:tequila_url)
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
    then = conn.query_params["then"]

    case user do
      nil ->
        exp = DateTime.add(DateTime.utc_now(), @confirm_attrs_exp_seconds, :second)
        payload = Clubhouse.Utility.wrap_payload(parsed_attrs, exp)

        conn
        |> put_session(:confirm_attrs, payload)
        |> redirect(to: Routes.user_session_path(conn, :welcome, then: then))

      %{suspended: false} ->
        user = Accounts.update_user_profile!(user, parsed_attrs)

        conn
        |> log_in_user(user)
        |> redirect(external: then)

      %{suspended: true} ->
        conn
        |> put_flash(
          :error,
          "Your account has been suspended, send us an email to make an appeal"
        )
        |> redirect(to: Routes.page_path(conn, :index))
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

          conn
          |> log_in_user(user)
          |> redirect(external: conn.query_params["then"] || Routes.page_path(conn, :index))

        {:error, :expired} ->
          conn
          |> put_flash(:error, "Account attributes expired, try again.")
          |> redirect(to: Routes.page_path(conn, :index))
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

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{token}")
    |> assign(:current_user, user)
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
    |> put_session(:return_path, get_session(conn, :return_path))
    |> put_session(:sso, get_session(conn, :sso))
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn, return_path \\ nil) do
    if user_token = get_session(conn, :user_token) do
      if user = Accounts.get_user_by_session_token(user_token) do
        Discourse.log_out(user)
      end

      Accounts.delete_session_token(user_token)
    end

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
      |> redirect(to: Routes.page_path(conn, :index))
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
