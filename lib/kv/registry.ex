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
    buckets_map = %{}
    refs = %{}

    {:ok, {buckets_map, refs}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, state) do
    {buckets_map, _} = state
    {:reply, Map.fetch(buckets_map, name), state}
  end

  @impl true
  def handle_cast({:create, new_name}, state) do
    {buckets_map, refs} = state

    case Map.has_key?(buckets_map, new_name) do
      true ->
        {:noreply, state}

      false ->
        {:ok, bucket_pid} = KV.Bucket.start_link([])
        ref = Process.monitor(bucket_pid)
        refs = refs |> Map.put_new(ref, new_name)
        buckets_map = buckets_map |> Map.put_new(new_name, bucket_pid)

        {:noreply, {buckets_map, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {buckets_map, refs} = state

    {name, refs} = refs |> Map.pop(ref)

    buckets_map = buckets_map |> Map.delete(name)

    {:noreply, {buckets_map, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in KV.Registry: #{inspect(msg)}")
    {:noreply, state}
  end
end
