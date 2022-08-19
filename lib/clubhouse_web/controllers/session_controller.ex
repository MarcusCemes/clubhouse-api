defmodule ClubhouseWeb.SessionController do
  use ClubhouseWeb, :controller

  import ClubhouseWeb.UserAuth, only: [fetch_current_user: 2, ensure_authenticated: 2]

  alias Clubhouse.Accounts.User
  alias ClubhouseWeb.UserAuth

  plug :fetch_current_user, [] when action in [:current_user, :choose_username]
  plug :ensure_authenticated, [] when action in [:choose_username]

  def start(conn, params) do
    case UserAuth.initiate_authentication(params["then"]) do
      {:ok, url} -> render(conn, "sign-in.json", redirect: url)
      {:error, _} -> render_unavailable(conn)
    end
  end

  def complete(conn, %{"key" => key, "auth_check" => auth_check}) do
    case UserAuth.complete_authentication(conn, key, auth_check) do
      {:ok, conn} -> render(conn, "signed-in.json", user: conn.assigns[:current_user])
      {:error, :new_user, token} -> render(conn, "confirm-account.json", token: token)
      {:error, :suspended} -> render(conn, "suspended.json")
      {:error, :bad_key} -> render(conn, "bad-key.json")
      {:error, :bridge} -> render_unavailable(conn)
    end
  end

  def confirm_account(conn, %{"token" => token}) do
    case UserAuth.confirm_account_creation(conn, token) do
      {:ok, conn, user} -> render(conn, "signed-in.json", user: user)
      {:error, :bad_token} -> render(conn, "bad-token.json")
      {:error, :expired} -> render(conn, "token-expired.json")
    end
  end

  def check_username(conn, %{"username" => username}) do
    render(conn, "username-available.json", available: UserAuth.username_available?(username))
  end

  defmodule UsernameError do
    defexception message: "Username is invalid", plug_status: 400
  end

  def choose_username(conn, %{"username" => username}) do
    conn.assigns[:current_user]
    |> UserAuth.choose_username(username)
    |> case do
      :ok -> render(conn, "username-changed.json")
      {:error, :taken} -> render(conn, "username-taken.json")
      {:error, :already_chosen} -> render(conn, "username-chosen.json")
      {:error, :invalid} -> raise UsernameError
    end
  end

  def current_user(conn, _params) do
    case conn.assigns[:current_user] do
      %User{} = user -> render(conn, "signed-in.json", user: user)
      nil -> render(conn, "signed-out.json")
    end
  end

  def sign_out(conn, _params) do
    conn
    |> UserAuth.sign_out()
    |> render("signed-out.json")
  end

  defp render_unavailable(conn) do
    conn
    |> put_status(:service_unavailable)
    |> render("auth-unavailable.json")
  end
end
