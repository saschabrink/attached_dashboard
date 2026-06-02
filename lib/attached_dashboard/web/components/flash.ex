defmodule AttachedDashboard.Web.Components.Flash do
  @moduledoc false

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders a single flash message as a DaisyUI alert.

  ## Examples

      <Flash.message kind={:info} flash={@flash} />
      <Flash.message kind={:error} flash={@flash} />
  """
  attr :id, :string, default: "flash"
  attr :flash, :map, default: %{}
  attr :kind, :atom, values: [:info, :error]
  attr :rest, :global

  slot :inner_block

  def message(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      role="alert"
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> JS.hide(to: "##{@id}")}
      class={[
        "alert cursor-pointer",
        @kind == :info && "alert-success",
        @kind == :error && "alert-error"
      ]}
      {@rest}
    >
      <span>{msg}</span>
    </div>
    """
  end

  @doc """
  Renders both flash kinds and a disconnected notice.

  ## Examples

      <Flash.group flash={@flash} />
  """
  attr :flash, :map, required: true

  def group(assigns) do
    ~H"""
    <div class="fixed top-4 right-4 z-50 flex flex-col gap-2 w-80">
      <.message kind={:info} flash={@flash} />
      <.message kind={:error} flash={@flash} />
      <.message
        id="flash-disconnected"
        kind={:error}
        phx-disconnected={JS.show(to: "#flash-disconnected")}
        phx-connected={JS.hide(to: "#flash-disconnected")}
        hidden
      >
        Verbindung unterbrochen – wird wiederhergestellt…
      </.message>
    </div>
    """
  end
end
