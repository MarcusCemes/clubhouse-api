defmodule ClubhouseWeb.ErrorViewTest do
  use ClubhouseWeb.ConnCase, async: true

  import Phoenix.View

  test "renders 404.json" do
    assert render(ClubhouseWeb.ErrorView, "404.json", []) ==
             %{errors: %{detail: "Not Found"}}
  end

  test "renders 500.json" do
    assert render(ClubhouseWeb.ErrorView, "500.json", []) ==
             %{errors: %{detail: "Internal Server Error"}}
  end

  test "renders a generic error" do
    assert render(ClubhouseWeb.ErrorView, "error.json", []) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
