defmodule AttachedDashboard.Web.Components.Core.Button do
  @moduledoc false

  use Phoenix.Component

  @doc """
  Renders a button or link with consistent DaisyUI styling.

  Renders as `<.link>` when `href`, `navigate`, or `patch` is present,
  otherwise as `<button>`.

  ## Variants

  - `nil` (default) — `btn-ghost btn-sm`
  - `"primary"` — `btn-primary btn-sm`
  - `"secondary"` — `btn-outline btn-sm`
  - `"danger"` — `btn-error btn-sm`

  ## Examples

      <Button.default phx-click="save">Save</Button.default>
      <Button.default variant="primary" phx-click="confirm">Confirm</Button.default>
      <Button.default variant="danger" phx-click="delete">Delete</Button.default>
      <Button.default navigate={~p"/originals"}>Back</Button.default>
  """
  attr :variant, :string, default: nil, values: [nil, "primary", "secondary", "danger"]
  attr :class, :any, default: nil

  attr :rest, :global, include: ~w(href navigate patch method disabled type name value data-confirm target download)

  slot :inner_block, required: true

  def default(%{rest: rest} = assigns) do
    assigns =
      assign(assigns, :class, assigns[:class] || ["btn btn-sm", variant_class(assigns[:variant])])

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  defp variant_class("primary"), do: "btn-primary"
  defp variant_class("secondary"), do: "btn-outline"
  defp variant_class("danger"), do: "btn-error"
  defp variant_class(_), do: "btn-ghost"
end
