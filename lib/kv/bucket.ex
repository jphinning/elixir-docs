defmodule KV.Bucket do
  use Agent, restart: :temporary

  @doc """
    Starts a new Bucket
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
    Get a value given a key from the bucket
  """
  def get(pid, key) do
    Agent.get(pid, &Map.get(&1, key))
  end

  @doc """
    Insert a new value in the bucket
  """
  def put(pid, key, new_value) do
    Agent.update(pid, &Map.put(&1, key, new_value))
  end

  @doc """
      Deletes a value from the bucket
  """
  def delete(pid, key) do
    Agent.get_and_update(pid, &Map.pop(&1, key))
  end
end
