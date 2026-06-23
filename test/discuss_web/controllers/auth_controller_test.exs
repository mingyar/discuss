defmodule DiscussWeb.AuthControllerTest do
  use DiscussWeb.ConnCase, async: true

  import Discuss.AuthHelpers
  import Discuss.AccountsFixtures
  # Phoenix stores flash in the session under "phoenix_flash" during redirects
  defp flash(conn, key),
    do:
      get_session(conn, "phoenix_flash")[to_string(key)] ||
        get_session(conn, "phoenix_flash")[key]

  describe "GET /auth/:provider/callback" do
    test "creates new user and signs them in", %{conn: conn} do
      conn =
        conn
        |> with_mock_auth(%{uid: "new_uid", info: %{email: "new@example.com", name: "New User"}})
        |> get(~p"/auth/github/callback")

      # Verify redirect to topics
      assert redirected_to(conn) == ~p"/topics"

      # Verify welcome flash
      assert flash(conn, :info) =~ "Welcome"

      # Verify user was created in DB
      user = Discuss.Repo.get_by(Discuss.Accounts.User, uid: "new_uid")
      assert user
      assert user.email == "new@example.com"
      assert user.name == "New User"
      assert user.provider == "github"

      # Verify session contains user_id
      assert get_session(conn, :user_id) == user.id
    end

    test "finds existing user and signs them in", %{conn: conn} do
      existing_user = user_fixture(%{provider: "github", uid: "existing_uid"})

      conn =
        conn
        |> with_mock_auth(%{uid: "existing_uid", info: %{email: existing_user.email}})
        |> get(~p"/auth/github/callback")

      assert redirected_to(conn) == ~p"/topics"
      assert flash(conn, :info) =~ "Welcome back"

      # No duplicate user created
      assert Discuss.Repo.get_by(Discuss.Accounts.User, uid: "existing_uid").id ==
               existing_user.id

      assert get_session(conn, :user_id) == existing_user.id
    end

    test "handles OAuth failure", %{conn: conn} do
      conn =
        conn
        |> with_mock_auth_failure()
        |> get(~p"/auth/github/callback")

      assert redirected_to(conn) == ~p"/"
      assert flash(conn, :error) =~ "Failed to authenticate"
    end

    test "handles missing email from provider", %{conn: conn} do
      conn =
        conn
        |> with_mock_auth(%{info: %{email: nil, name: "No Email User"}})
        |> get(~p"/auth/github/callback")

      # Email is required, so user creation fails and redirects to root
      assert redirected_to(conn) == ~p"/"
      assert flash(conn, :error) =~ "Authentication failed"
    end
  end

  describe "POST /auth/signout" do
    test "signs out and clears session", %{conn: conn} do
      user = user_fixture()
      csrf_token = Plug.CSRFProtection.get_csrf_token()

      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user.id})
        |> put_req_header("x-csrf-token", csrf_token)
        |> post(~p"/auth/signout")

      assert redirected_to(conn) == ~p"/"
      assert flash(conn, :info) =~ "Signed out"

      # Session is marked for drop in response
      assert conn.private.plug_session_info == :drop
    end
  end
end
