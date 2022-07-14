defmodule ClubhouseWeb.DiscourseController do
  use ClubhouseWeb, :controller

  import Plug.Crypto, only: [secure_compare: 2]
  import ClubhouseWeb.UserAuth
  alias Clubhouse.Accounts.User

  defmodule InvalidSignature do
    defexception message: "Signature invalid", plug_status: 401
  end

  plug :authenticate_user
  plug :ensure_username

  def connect(conn, %{"sso" => sso, "sig" => sig}) do
    data = verify_and_decode_payload(sso, sig)
    sso_query = generate_sso_response(conn.assigns[:current_user], data["nonce"])
    redirect(conn, external: append_query(data["return_sso_url"], sso_query))
  end

  defp append_query(url, query) do
    separator = if(String.contains?(url, "?"), do: "&", else: "?")
    url <> separator <> query
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
    |> if(do: data, else: raise(InvalidSignature))
  end

  defp sign(data) do
    :crypto.mac(:hmac, :sha256, signing_secret(), data)
    |> Base.encode16(case: :lower)
  end

  defp signing_secret() do
    Application.fetch_env!(:clubhouse, :services)
    |> Keyword.get(:discourse_secret)
  end
end
