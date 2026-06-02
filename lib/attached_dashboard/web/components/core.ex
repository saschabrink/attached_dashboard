defmodule AttachedDashboard.Web.Components.Core do
  @moduledoc false

  use Phoenix.Component

  alias AttachedDashboard.Web.Components.Core.Button
  alias Phoenix.LiveView.JS

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :sub, :string, default: nil
  attr :navigate, :string, default: nil

  def stat_card(assigns) do
    ~H"""
    <a
      href={@navigate}
      class={[
        "bg-base-100 rounded-lg shadow p-5 block",
        @navigate && "hover:shadow-md hover:bg-base-200/50 transition-all cursor-pointer"
      ]}
    >
      <p class="text-sm font-medium text-base-content/50 truncate">{@label}</p>
      <p class="mt-1 text-3xl font-semibold text-base-content">{@value}</p>
      <p :if={@sub} class="mt-1 text-sm text-base-content/40">{@sub}</p>
    </a>
    """
  end

  attr :total, :integer, required: true
  attr :page, :integer, required: true
  attr :per_page, :integer, required: true
  attr :on_change, JS, default: nil

  def pagination(assigns) do
    total_pages = max(1, ceil(assigns.total / assigns.per_page))
    from = (assigns.page - 1) * assigns.per_page + 1
    to = min(assigns.page * assigns.per_page, assigns.total)

    assigns =
      assign(assigns,
        total_pages: total_pages,
        from: from,
        to: to,
        prev_disabled: assigns.page <= 1,
        next_disabled: assigns.page >= total_pages
      )

    ~H"""
    <div class="flex items-center justify-between px-4 py-3 border-t border-base-300 text-sm text-base-content/50">
      <span>{@from}–{@to} of {@total}</span>
      <div class="flex gap-2">
        <Button.default disabled={@prev_disabled} phx-click={JS.push("paginate", value: %{page: @page - 1})}>Previous</Button.default>
        <Button.default disabled={@next_disabled} phx-click={JS.push("paginate", value: %{page: @page + 1})}>Next</Button.default>
      </div>
    </div>
    """
  end
end
