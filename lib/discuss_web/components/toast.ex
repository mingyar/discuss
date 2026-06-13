defmodule DiscussWeb.Components.Toast do
  use DiscussWeb, :html

  def toast(assigns) do
    ~H"""
    <div
      id="toast"
      class="fixed top-4 right-4 z-50 max-w-sm w-full bg-base-100 shadow-lg rounded-lg pointer-events-auto"
      phx-mounted={JS.show(transition: "fade-in-scale")}
      phx-remove={JS.hide(transition: "fade-out-scale")}
    >
      <div class="p-4">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            <%= if @type == :info do %>
              <.icon name="hero-check-circle" class="h-6 w-6 text-success" />
            <% else %>
              <.icon name="hero-exclamation-circle" class="h-6 w-6 text-error" />
            <% end %>
          </div>
          <div class="ml-3 w-0 flex-1 pt-0.5">
            <p class="text-sm font-medium text-base-content">
              {@message}
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
