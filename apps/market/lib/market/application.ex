defmodule Market.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: Market.PubSub}
      # Start a worker by calling: Market.Worker.start_link(arg)
      # {Market.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Market.Supervisor)
  end
end
