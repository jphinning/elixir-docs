defmodule KV.Registry do
  use GenServer
  ## These are client functions

  def start_link(opts) do
    server_process_name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server_process_name, opts)
  end

  def lookup(server_process_name, bucket_name) do
    case :ets.lookup(server_process_name, bucket_name) do
      [{^bucket_name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  def create(server, new_name) do
    GenServer.call(server, {:create, new_name})
  end

  ## These are server functions

  @impl true
  def init(server_process_name) do
    bucket_table_name = :ets.new(server_process_name, [:named_table, read_concurrency: true])
    refs = %{}

    {:ok, {bucket_table_name, refs}}
  end

  @impl true
  def handle_call({:create, new_name}, _from, state) do
    {bucket_table_name, refs} = state

    case lookup(bucket_table_name, new_name) do
      {:ok, pid} ->
        {:reply, pid, {bucket_table_name, refs}}

      :error ->
        {:ok, bucket_pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        ref = Process.monitor(bucket_pid)
        refs = refs |> Map.put_new(ref, new_name)

        :ets.insert(bucket_table_name, {new_name, bucket_pid})

        {:reply, bucket_pid, {bucket_table_name, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {bucket_table_name, refs} = state

    {name, refs} = refs |> Map.pop(ref)

    :ets.delete(bucket_table_name, name)

    {:noreply, {bucket_table_name, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in KV.Registry: #{inspect(msg)}")
    {:noreply, state}
  end
end
