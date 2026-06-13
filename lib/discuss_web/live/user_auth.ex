defmodule DiscussWeb.UserAuth do
  import Phoenix.Component, only: [assign: 3]

  alias Discuss.Accounts

  def on_mount(:default, _params, session, socket) do
    user =
      case session["user_id"] do
        nil -> nil
        user_id -> Accounts.get_user(user_id)
      end

    {:cont, assign(socket, :current_user, user)}
  end

  def on_mount(:require_authenticated_user, _params, session, socket) do
    case on_mount(:default, nil, session, socket) do
      {:cont, socket} ->
        if socket.assigns.current_user do
          {:cont, socket}
        else
          socket =
            socket
            |> Phoenix.LiveView.put_flash(:error, "You must be logged in to access this page")
            |> Phoenix.LiveView.redirect(to: "/")

          {:halt, socket}
        end

      {:halt, _socket} = halt_tuple ->
        halt_tuple
    end
  end
end
