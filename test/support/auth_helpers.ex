defmodule Discuss.AuthHelpers do
  @moduledoc """
  Test helpers for building mock Ueberauth auth structs.
  """

  alias Ueberauth.Auth.{Info, Credentials, Extra}

  @doc """
  Builds a mock `Ueberauth.Auth` struct suitable for testing the OAuth callback.
  """
  def mock_ueberauth_auth(attrs \\ %{}) do
    defaults = %{
      provider: "github",
      uid: "12345",
      info: %Info{
        email: "user@example.com",
        name: "Test User",
        image: "https://avatars.githubusercontent.com/u/12345"
      },
      credentials: %Credentials{
        token: "mock-token-12345"
      },
      extra: %Extra{}
    }

    deep_merge(defaults, attrs)
  end

  @doc """
  Assigns a mock Ueberauth auth to the conn for testing callback handlers.
  """
  def with_mock_auth(conn, attrs \\ %{}) do
    Plug.Conn.assign(conn, :ueberauth_auth, mock_ueberauth_auth(attrs))
  end

  @doc """
  Assigns a Ueberauth failure to the conn for testing failure callback.
  """
  def with_mock_auth_failure(conn) do
    Plug.Conn.assign(conn, :ueberauth_failure, %{message: "auth denied"})
  end

  defp deep_merge(left, right) do
    Map.merge(left, right, fn
      _key, %{__struct__: _} = left_val, right_val ->
        deep_merge(Map.from_struct(left_val), right_val)
        |> then(fn merged ->
          struct(left_val, merged)
        end)

      _key, left_val, right_val when is_map(left_val) and is_map(right_val) ->
        Map.merge(left_val, right_val)

      _key, _left_val, right_val ->
        right_val
    end)
  end
end
