defmodule Wordle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WordleWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:wordle, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Wordle.PubSub},
      # Start a worker by calling: Wordle.Worker.start_link(arg)
      # {Wordle.Worker, arg},
      # Start to serve requests, typically the last entry
      WordleWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wordle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WordleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
