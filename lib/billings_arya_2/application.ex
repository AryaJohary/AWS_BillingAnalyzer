defmodule BillingsArya2.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BillingsArya2Web.Telemetry,
      # Remove or comment out the Repo if you aren't using a database:
      # BillingsArya2.Repo,
      {DNSCluster, query: Application.get_env(:billings_arya_2, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BillingsArya2.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: BillingsArya2.Finch},
      # Start a worker by calling: BillingsArya2.Worker.start_link(arg)
      # {BillingsArya2.Worker, arg},
      # Start to serve requests, typically the last entry
      BillingsArya2Web.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BillingsArya2.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BillingsArya2Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
