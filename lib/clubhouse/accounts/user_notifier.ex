defmodule Clubhouse.Accounts.UserNotifier do
  import Swoosh.Email

  alias Clubhouse.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Clubhouse", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def deliver_welcome(user, name) do
    deliver(user.email, "Welcome to Clubhouse", "Welcome, #{name}, to Clubhouse!")
  end
end
