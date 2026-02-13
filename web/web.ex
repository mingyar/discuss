defmodule Discuss.Web do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use Discuss.Web, :controller
      use Discuss.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      alias Discuss.Repo
      import Ecto
      import Ecto.Query

      import Discuss.Router.Helpers
      import Discuss.Gettext
    end
  end

  def view do
    quote do
      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2]

      # Use all HTML functionality (forms, tags, etc)
      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers

      import Discuss.Router.Helpers
      import Discuss.ErrorHelpers
      import Discuss.Gettext
      
      # For template rendering - the old Phoenix.View.render/3 is now direct function calls
      # But we need to support the old render(@view_module, @view_template, assigns) syntax
      # So we provide a wrapper
      def render(view_module, template_name, assigns) when is_atom(view_module) and is_binary(template_name) do
        apply(view_module, :render, [template_name, assigns])
      end
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias Discuss.Repo
      import Ecto
      import Ecto.Query
      import Discuss.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
