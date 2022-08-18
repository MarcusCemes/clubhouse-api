defmodule ClubhouseWeb.SessionView do
  use ClubhouseWeb, :view

  alias Clubhouse.Accounts.User

  @user_keys ~w(uid email first_name last_name unit username)a

  def render("sign-in.json", %{redirect: url}) do
    %{code: "SIGN_IN", redirect: url}
  end

  def render("confirm-account.json", %{token: token}) do
    %{code: "CONFIRM_ACCOUNT", token: token}
  end

  def render("signed-in.json", %{user: %User{} = user}) do
    %{code: "SIGNED_IN", user: render(__MODULE__, "user.json", user: user)}
  end

  def render("username-available.json", %{available: available}) do
    %{available: available}
  end

  def render("username-changed.json", _), do: %{code: "USERNAME_CHANGED"}
  def render("signed-out.json", _), do: %{code: "SIGNED_OUT"}

  def render("unauthenticated.json", _), do: %{code: "E_UNAUTHENTICATED"}
  def render("no-username.json", _), do: %{code: "E_NO_USERNAME"}
  def render("auth-unavailable.json", _), do: %{code: "E_AUTH_UNAVAILABLE"}
  def render("bad-key.json", _), do: %{code: "E_BAD_KEY"}
  def render("token-expired.json", _), do: %{code: "E_TOKEN_EXPIRED"}
  def render("bad-token.json", _), do: %{code: "E_BAD_TOKEN"}
  def render("suspended.json", _), do: %{code: "E_SUSPENDED"}
  def render("username-taken.json", _), do: %{code: "E_USERNAME_TAKEN"}
  def render("username-chosen.json", _), do: %{code: "E_USERNAME_CHOSEN"}

  def render("user.json", %{user: user}) do
    Map.take(user, @user_keys)
  end
end
