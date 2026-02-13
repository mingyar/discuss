defmodule Discuss.AuthController do
  use Discuss.Web, :controller
  plug Ueberauth

  alias Discuss.User

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_params = build_user_params(auth)
    changeset = User.changeset(%User{}, user_params)
    signin(conn, changeset)
  end

  def callback(%{assigns: %{ueberauth_failure: _failure}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate with GitHub. Please try again.")
    |> redirect(to: topic_path(conn, :index))
  end

  def signout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: topic_path(conn, :index))
  end

  # Private functions

  defp build_user_params(auth) do
    # GitHub may not return email in some cases, handle gracefully
    email = auth.info.email || auth.info.nickname || "user-#{auth.uid}@github.local"
    %{token: auth.credentials.token, email: email, provider: "github"}
  end

  defp signin(conn, changeset) do
    case insert_or_update_user(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> put_session(:user_id, user.id)
        |> redirect(to: topic_path(conn, :index))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Error signing in")
        |> redirect(to: topic_path(conn, :index))
    end
  end

  defp insert_or_update_user(changeset) do
    case Repo.get_by(User, email: changeset.changes.email) do
      nil -> Repo.insert(changeset)
      user -> {:ok, user}
    end
  end
end
