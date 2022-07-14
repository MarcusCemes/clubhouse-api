defmodule ClubhouseWeb.ErrorViewTest do
  use ClubhouseWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(ClubhouseWeb.ErrorView, "404.html", []) =~ "Where are you off to?"
  end

  test "renders a generic error" do
    assert render_to_string(ClubhouseWeb.ErrorView, "error.html",
             status: 500,
             status_text: "Internal Server Error"
           ) =~ "Whoops!"
  end
end
