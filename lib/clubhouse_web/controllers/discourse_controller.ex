defmodule ClubhouseWeb.DiscourseController do
  use ClubhouseWeb, :controller

  import Plug.Crypto, only: [secure_compare: 2]
  import Clubhouse.Utility, only: [service_env: 1]
  import ClubhouseWeb.UserAuth

  alias Clubhouse.Accounts.User
  alias Clubhouse.Utility

  defmodule SignatureError do
    defexception message: "Signature invalid", plug_status: 401
  end

  plug :fetch_current_user
  plug :ensure_authenticated
  plug :ensure_has_username

  def connect(conn, %{"sso" => sso, "sig" => sig}) do
    data = verify_and_decode_payload(sso, sig)
    sso_query = generate_sso_response(conn.assigns[:current_user], data["nonce"])
    redirect = Utility.append_query_string(data["return_sso_url"], sso_query)
    render(conn, "connect.json", redirect: redirect)
  end

  defp verify_and_decode_payload(data, signature) do
    data
    |> URI.decode()
    |> validate_signature(signature)
    |> Base.decode64!()
    |> URI.decode_query()
  end

  defp generate_sso_response(user, nonce) do
    sso_attrs(user, nonce)
    |> URI.encode_query()
    |> Base.encode64()
    |> then(fn data -> %{sso: URI.encode(data), sig: sign(data)} end)
    |> URI.encode_query()
  end

  defp sso_attrs(user, nonce) do
    %{
      nonce: nonce,
      name: User.name(user),
      email: user.email,
      username: user.username,
      external_id: user.uid
    }
  end

  defp validate_signature(data, signature) do
    data
    |> sign()
    |> secure_compare(signature)
    |> if(do: data, else: raise(SignatureError))
  end

  defp sign(data) do
    signature = :crypto.mac(:hmac, :sha256, service_env(:discourse_secret), data)
    Base.encode16(signature, case: :lower)
  end
end
