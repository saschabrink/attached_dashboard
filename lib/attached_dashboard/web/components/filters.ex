defmodule AttachedDashboard.Web.Components.Filters do
  @moduledoc false

  use Phoenix.Component

  attr :search, :string, default: ""
  attr :content_type, :string, default: ""
  attr :storage_backend, :string, default: ""
  attr :owner_table, :string, default: ""
  attr :owner_field, :string, default: ""
  attr :sort_by, :string, default: "inserted_at"
  attr :sort_dir, :string, default: "desc"
  attr :services, :list, default: []
  attr :owner_tables, :list, default: []
  attr :owner_fields, :list, default: []

  def original_filter_bar(assigns) do
    ~H"""
    <form phx-submit="filter" class="flex flex-wrap items-center gap-2 mb-4">
      <input
        type="text"
        name="search"
        value={@search}
        placeholder="Search filename…"
        class="input input-bordered input-sm w-full sm:w-44"
      />

      <select name="content_type" class="select select-bordered select-sm flex-1 sm:flex-none sm:w-28">
        <option value="">All types</option>
        <option value="image" selected={@content_type == "image"}>Images</option>
        <option value="video" selected={@content_type == "video"}>Video</option>
        <option value="audio" selected={@content_type == "audio"}>Audio</option>
        <option value="application" selected={@content_type == "application"}>Application</option>
      </select>

      <select :if={@services != []} name="storage_backend" class="select select-bordered select-sm flex-1 sm:flex-none sm:w-32">
        <option value="">All backends</option>
        <option :for={s <- @services} value={s} selected={@storage_backend == s}>{s}</option>
      </select>

      <select
        :if={@owner_tables != []}
        name="owner_table"
        phx-change="filter"
        class="select select-bordered select-sm flex-1 sm:flex-none sm:w-32"
      >
        <option value="">All tables</option>
        <option :for={t <- @owner_tables} value={t} selected={@owner_table == t}>{t}</option>
      </select>

      <select
        :if={@owner_fields != []}
        name="owner_field"
        class="select select-bordered select-sm flex-1 sm:flex-none sm:w-32"
      >
        <option value="">All fields</option>
        <option :for={f <- @owner_fields} value={f} selected={@owner_field == f}>{f}</option>
      </select>

      <select name="sort_by" class="select select-bordered select-sm flex-1 sm:flex-none sm:w-24">
        <option value="inserted_at" selected={@sort_by == "inserted_at"}>Date</option>
        <option value="byte_size" selected={@sort_by == "byte_size"}>Size</option>
        <option value="filename" selected={@sort_by == "filename"}>Filename</option>
      </select>

      <select name="sort_dir" class="select select-bordered select-sm flex-1 sm:flex-none sm:w-20">
        <option value="desc" selected={@sort_dir == "desc"}>Desc</option>
        <option value="asc" selected={@sort_dir == "asc"}>Asc</option>
      </select>

      <button type="submit" class="btn btn-sm btn-primary">→</button>
    </form>
    """
  end
end
