defmodule ClubhouseWeb.SessionControllerTest do
  use ClubhouseWeb.ConnCase, async: true

  @key_auth_check_regex ~r/key=([a-zA-Z0-9_-]+)&auth_check=([a-zA-Z0-9_-]+)/

  describe "start" do
    test "creates a request", %{conn: conn} do
      conn = post(conn, "/auth/start")
      body = json_response(conn, 200)

      assert body["code"] == "SIGN_IN"
      assert Regex.match?(@key_auth_check_regex, body["redirect"])
    end
  end

  describe "complete" do
    test "requires a valid key", %{conn: conn} do
      conn = post(conn, "/auth/complete", key: "some_key", auth_check: "1")
      body = json_response(conn, 200)
      assert body == %{"code" => "E_BAD_KEY"}
    end

    test "accepts a valid key", %{conn: conn} do
      {key, auth_check} = generate_key_auth_check()

      conn = post(conn, "/auth/complete", key: key, auth_check: auth_check)
      body = json_response(conn, 200)

      assert body["code"] == "CONFIRM_ACCOUNT"
      assert is_binary(body["token"])
    end
  end

  describe "confirm_account" do
    test "requires a valid token", %{conn: conn} do
      conn = post(conn, "/auth/confirm-account", token: "some_token")
      body = json_response(conn, 200)
      assert body == %{"code" => "E_BAD_TOKEN"}
    end

    test "accepts a valid token", %{conn: conn} do
      conn = post(conn, "/auth/confirm-account", token: generate_token(conn))
      body = json_response(conn, 200)

      assert %{
               "code" => "SIGNED_IN",
               "user" => %{
                 "uid" => "" <> _,
                 "email" => "" <> _,
                 "first_name" => "" <> _,
                 "last_name" => "" <> _,
                 "username" => nil,
                 "unit" => "" <> _
               }
             } = body
    end
  end

  describe "check_username" do
    test "checks availability", %{conn: conn} do
      conn = get(conn, "/auth/username-availability/some_username")
      body = json_response(conn, 200)
      assert body == %{"available" => true}
    end
  end

  describe "sign_out" do
    test "signs out", %{conn: conn} do
      conn = post(conn, "/auth/sign-out")
      body = json_response(conn, 200)
      assert body == %{"code" => "SIGNED_OUT"}
    end
  end

  defp generate_token(conn) do
    {key, auth_check} = generate_key_auth_check()

    %{"token" => token} =
      conn
      |> post("/auth/complete", key: key, auth_check: auth_check)
      |> json_response(200)

    token
  end

  defp generate_key_auth_check do
    {:ok, url} = Clubhouse.Bridge.Mock.create_request("https://clubhouse.test")
    [_, key, auth_check] = Regex.run(@key_auth_check_regex, url)
    {key, auth_check}
  end
end
