defmodule ClubhouseWeb.UsernameLive do
  @moduledoc false

  use ClubhouseWeb, :live_view

  alias Clubhouse.Accounts
  alias Clubhouse.Accounts.User
  alias Clubhouse.Repo

  def mount(params, session, socket) do
    then = params["then"] || Routes.page_path(socket, :index)
    user = Accounts.get_user_by_session_token(session["user_token"])

    if user.username do
      {:ok, redirect(socket, external: then)}
    else
      {:ok,
       assign(socket, %{
         available: nil,
         changeset: User.username_changeset(%User{}),
         error: nil,
         user: user,
         then: then
       })}
    end
  end

  def handle_event("validate", %{"user" => %{"username" => username}}, socket) do
    changeset = validate_username(%User{}, %{username: username})
    available = if changeset.valid?, do: Accounts.username_available?(username)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:available, available)}
  end

  def handle_event("save", assigns, socket) do
    username = assigns["user"]["username"]
    changeset = validate_username(socket.assigns[:user], %{username: username})
    available? = Accounts.username_available?(username)

    if changeset.valid? and available? do
      case Repo.update(changeset) do
        {:ok, _} -> redirect(socket, external: assigns[:then])
        {:error, _} -> {:noreply, assign(socket, :error, "An error occurred")}
      end
    else
      handle_event("validate", assigns, socket)
    end
  end

  defp validate_username(user, attrs) do
    user
    |> User.username_changeset(attrs)
    |> Ecto.Changeset.validate_required([:username], message: "")
  end

  def availability(assigns) do
    case assigns.available do
      true -> ~H(<span class="font-bold text-green-500">😀 That username is free</span>)
      false -> ~H(<span class="font-bold text-red-500">😔 That username is taken</span>)
      nil -> ~H()
    end
  end
end
