defmodule MyAppWeb.UserLiveAuth do
  @moduledoc false

  import Phoenix.LiveView

  alias Clubhouse.Accounts

  def on_mount(:default, _params, %{"user_id" => user_id} = _session, socket) do
    socket =
      assign_new(socket, :current_user, fn ->
        Accounts.get_user!(user_id)
      end)

    if socket.assigns.current_user.confirmed_at do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end
end
