defmodule DiscussWeb.AuthController do
  use DiscussWeb, :controller
  plug Ueberauth

  alias Discuss.Accounts

  def request(conn, _params), do: conn

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_params = %{
      email: auth.info.email,
      provider: to_string(auth.provider),
      uid: to_string(auth.uid),
      token: auth.credentials.token,
      avatar_url: auth.info.image,
      name: auth.info.name
    }

    case Accounts.find_or_create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back, #{user.name || user.email}!")
        |> put_session(:user_id, user.id)
        |> redirect(to: ~p"/topics")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Authentication failed. Please try again.")
        |> redirect(to: ~p"/")
    end
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate with GitHub.")
    |> redirect(to: ~p"/")
  end

  def signout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "Signed out successfully")
    |> redirect(to: ~p"/")
  end
end
