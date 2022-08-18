defmodule ClubhouseWeb.DiscourseView do
  use ClubhouseWeb, :view

  def render("connect.json", %{redirect: redirect}) do
    %{code: "CONNECT", redirect: redirect}
  end
end
