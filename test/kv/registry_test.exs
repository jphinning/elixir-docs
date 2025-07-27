defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup context do
    _registry_name = start_supervised!({KV.Registry, name: context.test})
    %{registry: context.test}
  end

  test "spawns buckets", %{registry: registry_name} do
    assert KV.Registry.lookup(registry_name, "Config map") == :error

    KV.Registry.create(registry_name, "Shopping cart")
    assert {:ok, bucket_pid} = KV.Registry.lookup(registry_name, "Shopping cart")

    KV.Registry.create(registry_name, "Shopping cart")

    KV.Bucket.put(bucket_pid, "milk", 3)
    assert bucket_pid |> KV.Bucket.get("milk") == 3
  end

  test "remove buckets on exit", %{registry: registry_name} do
    KV.Registry.create(registry_name, "Shipping list")

    {:ok, bucket_pid} = KV.Registry.lookup(registry_name, "Shipping list")

    Agent.stop(bucket_pid)

    ### Avoid race condition on processing the :DOWN message to exclude the bucket
    _ = KV.Registry.create(registry_name, "bogus")
    assert KV.Registry.lookup(registry_name, "Shipping list") == :error
  end

  test "removes bucket on crash", %{registry: registry_name} do
    KV.Registry.create(registry_name, "shopping")
    {:ok, bucket_pid} = KV.Registry.lookup(registry_name, "shopping")

    # Stop the bucket with non-normal reason
    Agent.stop(bucket_pid, :shutdown)

    ### Avoid race condition on processing the :DOWN message to exclude the bucket
    _ = KV.Registry.create(registry_name, "bogus")
    assert KV.Registry.lookup(registry_name, "shopping") == :error
  end
end
