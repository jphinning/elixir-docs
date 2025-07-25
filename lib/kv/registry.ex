defmodule KV.Registry do
  use GenServer
  ## These are client functions

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  def create(server, new_name) do
    GenServer.cast(server, {:create, new_name})
  end

  ## These are server functions

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, buckets_map) do
    {:reply, Map.fetch(buckets_map, name), buckets_map}
  end

  @impl true
  def handle_cast({:create, new_name}, buckets_map) do
    updated_buckets_map =
      buckets_map
      |> Map.put_new_lazy(new_name, fn ->
        {:ok, pid} = KV.Bucket.start_link([])
        pid
      end)

    {:noreply, updated_buckets_map}
  end
end
