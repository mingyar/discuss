defmodule DiscussWeb.PlugsTest do
  use DiscussWeb.ConnCase, async: true

  import Discuss.AccountsFixtures

  alias DiscussWeb.Plugs.SetUser
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
  end
end
