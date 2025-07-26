defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup do
    registry_pid = start_supervised!(KV.Registry)
    %{registry: registry_pid}
  end

  test "spawns buckets", %{registry: registry_pid} do
    assert KV.Registry.lookup(registry_pid, "Config map") == :error

    KV.Registry.create(registry_pid, "Shopping cart")
    assert {:ok, bucket_pid} = KV.Registry.lookup(registry_pid, "Shopping cart")

    assert :ok = KV.Registry.create(registry_pid, "Shopping cart")

    KV.Bucket.put(bucket_pid, "milk", 3)
    assert bucket_pid |> KV.Bucket.get("milk") == 3
  end

  test "remove buckets on exit", %{registry: registry_pid} do
    KV.Registry.create(registry_pid, "Shipping list")

    {:ok, bucket_pid} = KV.Registry.lookup(registry_pid, "Shipping list")

    Agent.stop(bucket_pid)
    assert KV.Registry.lookup(registry_pid, "Shipping list") == :error
  end

  test "removes bucket on crash", %{registry: registry_pid} do
    KV.Registry.create(registry_pid, "shopping")
    {:ok, bucket_pid} = KV.Registry.lookup(registry_pid, "shopping")

    # Stop the bucket with non-normal reason
    Agent.stop(bucket_pid, :shutdown)
    assert KV.Registry.lookup(registry_pid, "shopping") == :error
  end
end
