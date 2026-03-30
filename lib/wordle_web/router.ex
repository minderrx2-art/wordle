defmodule WordleWeb.Router do
  use WordleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WordleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WordleWeb do
    pipe_through :browser

    live "/", MainPage, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", WordleWeb do
  #   pipe_through :api
  # end
end
