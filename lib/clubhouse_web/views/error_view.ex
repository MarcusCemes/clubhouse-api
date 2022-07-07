defmodule ClubhouseWeb.ErrorView do
  use ClubhouseWeb, :view

  def template_not_found(template, assigns) do
    status_text = Phoenix.Controller.status_message_from_template(template)
    render("error.html", Map.put(assigns, :status_text, status_text))
  end
end
