defmodule AttachedDashboard.Web.Components.Core.Card do
  @moduledoc false

  use Phoenix.Component

  attr :class, :string, default: nil

  slot :title
  slot :inner_block

  slot :body do
    attr :mode, :atom
  end

  def default(assigns) do
    ~H"""
    <div class={["bg-base-100 rounded-lg shadow overflow-hidden", @class]}>
      <div :if={@title != []} class="px-5 py-4 border-b border-base-300">
        <h2 class="text-sm font-semibold text-base-content/70">{render_slot(@title)}</h2>
      </div>
      <div
        :for={item <- @body}
        :if={Map.get(item, :mode, :prepend) == :prepend}
        class="px-5 py-4"
      >
        {render_slot(item)}
      </div>
      {render_slot(@inner_block)}
      <div :for={item <- @body} :if={Map.get(item, :mode) == :append} class="px-5 py-4">
        {render_slot(item)}
      </div>
    </div>
    """
  end
end
