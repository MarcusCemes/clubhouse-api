defmodule ClubhouseWeb.InfoController do
  use ClubhouseWeb, :controller

  plug :put_layout, "prose.html"

  def about(conn, _params) do
    page_title = "About"
    render(conn, "about.html", page_title: page_title)
  end

  def frequently_asked_questions(conn, _params) do
    page_title = "Frequently Asked Questions"
    render(conn, "frequently-asked-questions.html", page_title: page_title)
  end

  def code_of_conduct(conn, _params) do
    page_title = "Code of Conduct"
    render(conn, "code-of-conduct.html", page_title: page_title)
  end

  def privacy_policy(conn, _params) do
    page_title = "Privacy Policy"
    render(conn, "privacy-policy.html", page_title: page_title)
  end

  def terms_of_service(conn, _params) do
    page_title = "Terms of Service"
    render(conn, "terms-of-service.html", page_title: page_title)
  end
end
