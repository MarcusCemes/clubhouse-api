defmodule Clubhouse.Accounts.UserNotifier do
  @moduledoc """
  Handles notifications, such as delivering email to users
  when they register a new account.
  """

  import Swoosh.Email

  import Phoenix.View, only: [render_to_string: 3]

  alias Clubhouse.Accounts.User
  alias Clubhouse.Mailer
  alias ClubhouseWeb.EmailView

  @service_name "Clubhouse"

  def deliver_welcome(user) do
    user
    |> bootstrap()
    |> subject("Welcome to Clubhouse")
    |> deliver(:welcome)
  end

  def deliver_suspension_notice(user, reason) do
    user
    |> bootstrap()
    |> subject("Your account has been suspended")
    |> assign(:reason, reason)
    |> deliver(:suspended)
  end

  ## Private functions

  defp bootstrap(user) do
    name = User.name(user)

    new()
    |> from({@service_name, service_address()})
    |> to({User.name(user), user.email})
    |> assign(:name, name)
  end

  # Delivers the email using the application mailer.
  defp deliver(email, template) do
    email = render_template(email, template)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp render_template(email, template) do
    html = render_format(template, "html", email.assigns)
    text = render_format(template, "text", email.assigns)

    if !html and !text do
      raise "missing email template"
    end

    email
    |> maybe_add_template(html, &html_body/2)
    |> maybe_add_template(text, &text_body/2)
  end

  defp maybe_add_template(email, nil, _), do: email
  defp maybe_add_template(email, rendered, fun), do: fun.(email, rendered)

  defp render_format(template, extension, assigns) do
    try do
      render_to_string(EmailView, "#{Atom.to_string(template)}.#{extension}", assigns)
    rescue
      Phoenix.Template.UndefinedError -> nil
    end
  end

  defp service_address() do
    Application.fetch_env!(:clubhouse, :services)
    |> Keyword.get(:mailer_sender)
  end
end
