defmodule DiscussWeb.PlugsTest do
  use DiscussWeb.ConnCase, async: true

  import Discuss.AccountsFixtures
  import Plug.Conn

  alias DiscussWeb.Plugs.{SetUser, RequireAuth}
  alias DiscussWeb.UserAuth

  # Creates a minimal socket with flash assign for testing on_mount hooks
  defp build_socket do
    %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, flash: %{}}}
  end

  describe "SetUser" do
    test "sets current_user when user_id is in session", %{conn: conn} do
      user = user_fixture()
      conn = conn |> init_test_session(%{user_id: user.id}) |> SetUser.call(%{})

      assert conn.assigns.current_user.id == user.id
    end

    test "sets current_user to nil when user_id is not in session", %{conn: conn} do
      conn = conn |> init_test_session(%{}) |> SetUser.call(%{})

      assert conn.assigns.current_user == nil
    end

    test "sets current_user to nil when user_id references non-existent user", %{conn: conn} do
      conn = conn |> init_test_session(%{user_id: 999_999}) |> SetUser.call(%{})

      assert conn.assigns.current_user == nil
    end
  end

  describe "RequireAuth" do
    test "passes through when current_user is set", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> Phoenix.Controller.fetch_flash([])
        |> SetUser.call(%{})
        |> RequireAuth.call(%{})

      assert conn.status != 302
      assert conn.halted == false
    end

    test "redirects when current_user is not set", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Phoenix.Controller.fetch_flash([])
        |> SetUser.call(%{})
        |> RequireAuth.call(%{})

      assert conn.status == 302
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "sets error flash when redirecting", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Phoenix.Controller.fetch_flash([])
        |> SetUser.call(%{})
        |> RequireAuth.call(%{})

      assert get_session(conn, "phoenix_flash")["error"] =~ "logged in"
    end
  end

  describe "UserAuth on_mount" do
    test ":default sets current_user from session", %{conn: _conn} do
      user = user_fixture()
      socket = build_socket()

      {:cont, socket} = UserAuth.on_mount(:default, %{}, %{"user_id" => user.id}, socket)

      assert socket.assigns.current_user.id == user.id
    end

    test ":default sets current_user to nil when no session", %{conn: _conn} do
      socket = build_socket()

      {:cont, socket} = UserAuth.on_mount(:default, %{}, %{}, socket)

      assert socket.assigns.current_user == nil
    end

    test ":require_authenticated_user passes with valid user", %{conn: _conn} do
      user = user_fixture()
      socket = build_socket()

      {:cont, socket} =
        UserAuth.on_mount(:require_authenticated_user, %{}, %{"user_id" => user.id}, socket)

      assert socket.assigns.current_user.id == user.id
    end

    test ":require_authenticated_user halts without user", %{conn: _conn} do
      socket = build_socket()

      {:halt, socket} = UserAuth.on_mount(:require_authenticated_user, %{}, %{}, socket)

      refute socket.assigns.current_user
    end

    test ":require_authenticated_user sets flash and redirect without user", %{conn: _conn} do
      socket = build_socket()

      {:halt, socket} = UserAuth.on_mount(:require_authenticated_user, %{}, %{}, socket)

      assert socket.assigns.flash["error"] =~ "logged in"
      assert socket.redirected == {:redirect, %{to: "/", status: 302}}
    end
  end
end
