defmodule WordleWeb.PageController do
  use WordleWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
