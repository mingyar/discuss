defmodule DiscussWeb.Plugs.SetUser do
  import Plug.Conn

  alias Discuss.Accounts

  def init(_params), do: nil

  def call(conn, _params) do
    user_id = get_session(conn, :user_id)

    cond do
      user = user_id && Accounts.get_user(user_id) ->
        assign(conn, :current_user, user)

      true ->
        assign(conn, :current_user, nil)
    end
  end
end
