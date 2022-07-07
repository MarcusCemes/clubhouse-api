defmodule ClubhouseWeb.UserSessionController do
  use ClubhouseWeb, :controller

  alias ClubhouseWeb.UserAuth

  def sign_in(conn, params) do
    UserAuth.initiate_authentication(conn, Map.get(params, "return_path"))
  end

  def callback(conn, %{"key" => key, "auth_check" => auth_check}) do
    UserAuth.complete_authentication(conn, key, auth_check)
  end

  def welcome(conn, _params) do
    conn
    |> put_layout(false)
    |> render("welcome.html")
  end

  def confirm(conn, _params) do
    UserAuth.confirm_account_creation(conn)
  end

  def sign_out(conn, params) do
    return_path = Map.get(params, "return_path")
    UserAuth.log_out_user(conn, return_path)
  end
end
