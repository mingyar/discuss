defmodule Discuss.Accounts do
  @moduledoc """
  The Accounts context — manages users and authentication.
  """

  alias Discuss.Repo
  alias Discuss.Accounts.User

  @doc """
  Returns a user by ID, or nil if not found.
  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Returns a user by ID.

  Raises an exception if the user is not found.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Returns a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Finds or creates a user.

  Used in the OAuth flow.
  """
  def find_or_create_user(%{provider: provider, uid: uid} = attrs) do
    case Repo.get_by(User, provider: provider, uid: uid) do
      nil -> create_user(attrs)
      user -> {:ok, user}
    end
  end

  @doc """
  Creates a new user.
  """
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Lists all users.
  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Returns a changeset for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
