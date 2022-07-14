defmodule ClubhouseWeb.UserSessionController do
  use ClubhouseWeb, :controller

  import ClubhouseWeb.UserAuth

  alias ClubhouseWeb.UserAuth

  plug :authenticate_user when action in [:sign_in]

  def sign_in(conn, params) do
    to = params["then"] || Routes.page_path(conn, :index)
    redirect(conn, to: to)
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
    then = Map.get(params, "then", Routes.page_path(conn, :index))
    UserAuth.log_out_user(conn, then)
  end
end
