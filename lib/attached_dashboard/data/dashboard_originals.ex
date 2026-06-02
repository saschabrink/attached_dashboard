defmodule AttachedDashboard.Data.DashboardOriginals do
  @moduledoc false

  import Ecto.Query

  alias Attached.Originals.Scopes
  alias Attached.Variants.Variant

  @per_page 25

  @doc """
  Converts a string-keyed filter-params map (as stored in the LiveView
  URL/socket state) into a keyword list of `paginate/1` options.

  Unknown keys are ignored. `page` is parsed to an integer (falls back
  to `1` on bad input). Missing keys take sane defaults.
  """
  def parse_params(params) when is_map(params) do
    [
      search: params["search"] || "",
      content_type: params["content_type"] || "",
      storage_backend: params["storage_backend"] || "",
      owner_table: params["owner_table"] || "",
      owner_field: params["owner_field"] || "",
      sort_by: params["sort_by"] || "inserted_at",
      sort_dir: params["sort_dir"] || "desc",
      page: parse_page(params["page"])
    ]
  end

  defp parse_page(nil), do: 1
  defp parse_page(v) when is_integer(v) and v > 0, do: v

  defp parse_page(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp parse_page(_), do: 1

  def paginate(opts \\ []) do
    result =
      Attached.Originals.paginate(
        query: filter_from_params(opts),
        order_by: order_from_params(opts),
        page: Keyword.get(opts, :page, 1),
        per_page: @per_page
      )

    %{result | entries: with_variant_counts(result.entries)}
  end

  defp with_variant_counts([]), do: []

  defp with_variant_counts(originals) do
    ids = Enum.map(originals, & &1.id)

    counts =
      from(v in Variant,
        where: v.original_id in ^ids,
        group_by: v.original_id,
        select: {v.original_id, count(v.id)}
      )
      |> Attached.Repo.current().all()
      |> Map.new()

    Enum.map(originals, fn b -> {b, Map.get(counts, b.id, 0)} end)
  end

  defp filter_from_params(opts) do
    fn query ->
      query
      |> apply_owner_filter(opts[:owner_table], opts[:owner_field])
      |> apply_basic_filters(opts)
    end
  end

  defp apply_owner_filter(q, t, f) when is_binary(t) and t != "" and is_binary(f) and f != "" do
    Scopes.by_owner(q, t, f)
  end

  defp apply_owner_filter(q, t, _) when is_binary(t) and t != "" do
    where(q, [b], b.owner_table == ^t)
  end

  defp apply_owner_filter(q, _, f) when is_binary(f) and f != "" do
    where(q, [b], b.owner_field == ^f)
  end

  defp apply_owner_filter(q, _, _), do: q

  defp apply_basic_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:search, s}, q when is_binary(s) and s != "" ->
        pattern = "%#{s}%"
        where(q, [b], like(b.filename, ^pattern) or like(b.key, ^pattern))

      {:content_type, ct}, q when is_binary(ct) and ct != "" ->
        where(q, [b], like(b.content_type, ^"#{ct}/%"))

      {:storage_backend, sb}, q when is_binary(sb) and sb != "" ->
        where(q, [b], b.storage_backend == ^sb)

      _, q ->
        q
    end)
  end

  defp order_from_params(opts) do
    sort_dir = if Keyword.get(opts, :sort_dir, "desc") == "asc", do: :asc, else: :desc

    field =
      case Keyword.get(opts, :sort_by, "inserted_at") do
        "byte_size" -> :byte_size
        "filename" -> :filename
        _ -> :inserted_at
      end

    [{sort_dir, field}]
  end
end
