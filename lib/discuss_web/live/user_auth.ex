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
end
