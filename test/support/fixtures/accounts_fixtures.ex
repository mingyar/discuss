defmodule Discuss.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discuss.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def unique_user_uid, do: "#{System.unique_integer()}"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      provider: "github",
      uid: unique_user_uid(),
      name: "Test User"
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Discuss.Accounts.create_user()

    user
  end
end
