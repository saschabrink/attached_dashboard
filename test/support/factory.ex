defmodule AttachedDashboard.Test.Factory do
  @moduledoc false

  alias AttachedDashboard.TestRepo

  def insert(type, attrs \\ [])

  def insert(:original, attrs) do
    attrs = Enum.into(attrs, %{})
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %Attached.Originals.Original{}
    |> Ecto.Changeset.change(%{
      id: Map.get(attrs, :id, Ecto.UUID.generate()),
      key: Map.get(attrs, :key, "key-#{System.unique_integer([:positive])}"),
      filename: Map.get(attrs, :filename, "file-#{System.unique_integer([:positive])}.jpg"),
      content_type: Map.get(attrs, :content_type, "image/jpeg"),
      byte_size: Map.get(attrs, :byte_size, 1024),
      checksum: Map.get(attrs, :checksum, "abc123=="),
      metadata: Map.get(attrs, :metadata, %{}),
      storage_backend: Map.get(attrs, :storage_backend, "Attached.StorageBackends.Disk"),
      owner_table: Map.get(attrs, :owner_table, "test_owners"),
      owner_field: Map.get(attrs, :owner_field, "photo_attached_original_id"),
      inserted_at: Map.get(attrs, :inserted_at, now),
      updated_at: Map.get(attrs, :updated_at, now)
    })
    |> TestRepo.insert!()
  end

  def insert(:variant, attrs) do
    attrs = Enum.into(attrs, %{})
    original_id = Map.get(attrs, :original_id)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %Attached.Variants.Variant{}
    |> Ecto.Changeset.change(%{
      id: Map.get(attrs, :id, Ecto.UUID.generate()),
      original_id: original_id,
      name: Map.get(attrs, :name, "thumb"),
      transform_digest: Map.get(attrs, :digest, Map.get(attrs, :transform_digest, "digest#{System.unique_integer([:positive])}")),
      checksum: Map.get(attrs, :checksum, "abc123=="),
      content_type: Map.get(attrs, :content_type, "image/jpeg"),
      byte_size: Map.get(attrs, :byte_size, 1024),
      metadata: Map.get(attrs, :metadata, %{}),
      inserted_at: Map.get(attrs, :inserted_at, now),
      updated_at: Map.get(attrs, :updated_at, now)
    })
    |> TestRepo.insert!()
  end

  def insert_owner(original_id) do
    id = Ecto.UUID.generate()

    Ecto.Adapters.SQL.query!(
      AttachedDashboard.TestRepo,
      "INSERT INTO test_owners (id, photo_attached_original_id) VALUES (?, ?)",
      [id, original_id]
    )

    id
  end
end
