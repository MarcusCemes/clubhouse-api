defmodule Clubhouse.Accounts.UserNotifier do
  @moduledoc """
  Handles notifications, such as delivering email to users
  when they register a new account.
  """

  import Swoosh.Email

  import Phoenix.View, only: [render_to_string: 3]

  alias Clubhouse.Accounts.User
  alias Clubhouse.Mailer
  alias Clubhouse.Utility
  alias ClubhouseWeb.EmailView

  @formats ~w(html text)
  @service_name "Clubhouse"

  def deliver_welcome(user) do
    user
    |> bootstrap()
    |> subject("Welcome to Clubhouse")
    |> assign(:title, "Welcome to Clubhouse")
    |> assign(
      :preheader,
      "👋 Welcome to Clubhouse, here are some tips on how to get started!"
    )
    |> deliver(:welcome)
  end

  def deliver_suspension_notice(user, reason) do
    user
    |> bootstrap()
    |> subject("Your account has been suspended")
    |> assign(:title, "Account suspended")
    |> assign(
      :preheader,
      "Your account has been suspended with immediate effect. You may make an appeal by contacting us by email."
    )
    |> assign(:reason, reason)
    |> deliver(:suspended)
  end

  def deliver_reinstatement_notice(user) do
    user
    |> bootstrap()
    |> subject("You account has been reinstated")
    |> assign(:title, "Your account has been reinstated")
    |> assign(
      :preheader,
      "Your account has been reactivated, we can't wait to see you back at Clubhouse!"
    )
    |> deliver(:reinstated)
  end

  ## Private functions

  defp bootstrap(user) do
    name = User.name(user)

    new()
    |> from({@service_name, Utility.service_env(:mailer_sender)})
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
    [html, text] =
      @formats
      |> Enum.map(&render_format(template, &1, email.assigns))
      |> tap(&check_templates!/1)

    email
    |> maybe_add_template(html, &html_body/2)
    |> maybe_add_template(text, &text_body/2)
  end

  defp check_templates!(templates) do
    if Enum.count(templates, &is_binary/1) == 0 do
      raise "missing email template"
    end
  end

  defp maybe_add_template(email, nil, _), do: email
  defp maybe_add_template(email, rendered, fun), do: fun.(email, rendered)

  defp render_format(template, extension, assigns) do
    try do
      template = "#{Atom.to_string(template)}.#{extension}"
      assigns = Map.put(assigns, :layout, {EmailView, "_layout.#{extension}" |> IO.inspect()})
      render_to_string(EmailView, template, assigns)
    rescue
      Phoenix.Template.UndefinedError -> nil
    end
  end
end
