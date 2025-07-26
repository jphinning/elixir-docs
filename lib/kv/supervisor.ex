defmodule KV.Supervisor do
  use Supervisor

  ### Cliente
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  ### Servidor
  @impl true
  def init(:ok) do
    children = [
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
      {KV.Registry, name: KV.Registry}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
