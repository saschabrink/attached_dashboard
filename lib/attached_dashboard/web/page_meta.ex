defmodule AttachedDashboard.Web.PageMeta do
  @moduledoc """
  Page metadata struct for the dashboard.

  Centralises page title, navigation path, and breadcrumb context into a single
  struct. Each LiveView implements `page_meta/2` (one clause per live_action) and
  calls `assign_page_meta/1` after all referenced assigns are set.

  Breadcrumbs are built by walking the `:parent` chain — no separate config needed.
  """

  alias Phoenix.LiveView.Socket

  @enforce_keys [:title, :path]
  defstruct [
    :title,
    :breadcrumb_title,
    :parent,
    :path
  ]

  @doc """
  Builds a breadcrumb trail from a PageMeta struct.

  Walks the parent chain from the current page to the root, returning a list of
  `{title, path}` tuples in root-first order. The last item (current page) has
  `nil` as path to signal it should not be rendered as a link.
  """
  def breadcrumbs(%__MODULE__{} = page_meta) do
    page_meta
    |> Stream.iterate(fn
      %__MODULE__{parent: nil} -> nil
      %__MODULE__{parent: parent} -> parent
    end)
    |> Stream.take_while(& &1)
    |> Enum.map(&{&1.breadcrumb_title || &1.title, &1.path})
    |> Enum.reverse()
    |> List.update_at(-1, fn {title, _} -> {title, nil} end)
  end

  @doc """
  Assigns `:page_meta` and `:page_title` to the socket by calling `page_meta/2`
  on the view module.

  All assigns referenced in `page_meta/2` must be set before calling this.
  """
  def assign_page_meta(%Socket{} = socket) do
    page_meta = socket.view.page_meta(socket, socket.assigns.live_action)

    socket
    |> Phoenix.Component.assign(:page_meta, page_meta)
    |> Phoenix.Component.assign(:page_title, page_meta.title)
  end

  @doc "Returns the page metadata for a given live action."
  @callback page_meta(socket :: Socket.t(), action :: atom()) :: %__MODULE__{}
end
