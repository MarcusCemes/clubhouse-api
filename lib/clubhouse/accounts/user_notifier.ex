defmodule Clubhouse.Accounts.UserNotifier do
  @moduledoc """
  Handles notifications, such as delivering email to users
  when they register a new account.
  """

  import Swoosh.Email

  alias Clubhouse.Mailer

  @service_name "Clubhouse"

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({@service_name, from_address()})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def deliver_welcome(user, name) do
    deliver(user.email, "Welcome to Clubhouse", "Welcome, #{name}, to Clubhouse!")
  end

  defp from_address() do
    Application.fetch_env!(:clubhouse, :services)
    |> Keyword.get(:mailer_sender)
  end
end
