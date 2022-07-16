defmodule ClubhouseWeb.InfoController do
  use ClubhouseWeb, :controller

  plug :put_layout, "prose.html"

  def about(conn, _params) do
    render(conn, "about.html", page_title: "About")
  end

  def frequently_asked_questions(conn, _params) do
    render(conn, "frequently-asked-questions.html", page_title: "Frequently Asked Questions")
  end

  def code_of_conduct(conn, _params) do
    render(conn, "code-of-conduct.html", page_title: "Code of Conduct")
  end

  def privacy_policy(conn, _params) do
    render(conn, "privacy-policy.html", page_title: "Privacy Policy")
  end

  def terms_of_service(conn, _params) do
    render(conn, "terms-of-service.html", page_title: "Terms of Service")
  end
end
