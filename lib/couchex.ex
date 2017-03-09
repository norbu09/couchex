defmodule Couchex do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    pool_name = :couchex
    options = [{:timeout, 150000}, {:max_connections, 100}]
    :ok = :hackney_pool.start_pool(pool_name, options)

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Couchex.Worker, [arg1, arg2, arg3])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Couchex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
