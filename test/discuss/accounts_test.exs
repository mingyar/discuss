defmodule Discuss.AccountsTest do
  use Discuss.DataCase, async: true

  import Discuss.AccountsFixtures

  alias Discuss.Accounts
  alias Discuss.Accounts.User

  describe "get_user/1" do
    test "returns the user with valid id" do
      user = user_fixture()
      assert Accounts.get_user(user.id).id == user.id
    end

    test "returns nil for non-existent id" do
      assert Accounts.get_user(999_999) == nil
    end
  end

  describe "get_user!/1" do
    test "returns the user with valid id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id).id == user.id
    end

    test "raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(999_999)
      end
    end
  end

  describe "get_user_by_email/1" do
    test "returns the user with matching email" do
      user = user_fixture()
      assert Accounts.get_user_by_email(user.email).id == user.id
    end

    test "returns nil for unknown email" do
      assert Accounts.get_user_by_email("unknown@example.com") == nil
    end
  end

  describe "find_or_create_user/1" do
    test "creates a new user when provider+uid does not exist" do
      attrs = %{
        provider: "github",
        uid: "new_uid_123",
        email: "new@example.com",
        name: "New User"
      }

      assert {:ok, %User{} = user} = Accounts.find_or_create_user(attrs)
      assert user.uid == "new_uid_123"
      assert user.provider == "github"
    end

    test "returns existing user when provider+uid already exists" do
      existing = user_fixture(%{provider: "github", uid: "existing_uid"})

      assert {:ok, user} =
               Accounts.find_or_create_user(%{
                 provider: "github",
                 uid: "existing_uid",
                 email: "different@example.com",
                 name: "Different"
               })

      assert user.id == existing.id
      # Email is NOT updated — existing user is returned as-is
      assert user.email == existing.email
    end

    test "raises FunctionClauseError when provider key is missing" do
      assert_raise FunctionClauseError, fn ->
        Accounts.find_or_create_user(%{uid: "no_provider"})
      end
    end

    test "returns error when email is nil (required field)" do
      attrs = %{
        provider: "github",
        uid: "no_email_uid",
        email: nil,
        name: "No Email"
      }

      # email is required by validate_required in User.changeset
      assert {:error, %Ecto.Changeset{}} = Accounts.find_or_create_user(attrs)
    end
  end

  describe "create_user/1" do
    test "creates a user with valid attributes" do
      attrs = valid_user_attributes()

      assert {:ok, %User{} = user} = Accounts.create_user(attrs)
      assert user.email == attrs.email
      assert user.provider == "github"
    end

    test "returns error changeset with missing required fields" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(%{})
    end

    test "returns error changeset with duplicate email" do
      user_fixture(%{email: "dupe@example.com"})

      assert {:error, %Ecto.Changeset{}} =
               Accounts.create_user(%{
                 email: "dupe@example.com",
                 provider: "github",
                 uid: "another_uid"
               })
    end

    test "returns error changeset with duplicate provider+uid" do
      user_fixture(%{provider: "github", uid: "dupe_uid"})

      assert {:error, %Ecto.Changeset{}} =
               Accounts.create_user(%{
                 email: "another@example.com",
                 provider: "github",
                 uid: "dupe_uid"
               })
    end
  end

  describe "update_user/2" do
    test "updates user with valid attributes" do
      user = user_fixture()

      assert {:ok, %User{} = updated} = Accounts.update_user(user, %{name: "Updated Name"})
      assert updated.name == "Updated Name"
    end

    test "returns error changeset with invalid attributes" do
      user = user_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_user(user, %{email: nil})
    end
  end

  describe "delete_user/1" do
    test "deletes the user" do
      user = user_fixture()

      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert Accounts.get_user(user.id) == nil
    end

    test "raises FK constraint error when user owns topics" do
      user = user_fixture()
      {:ok, _topic} = Discuss.Discussions.create_topic(user, %{title: "Topic owned"})

      # Topic has belongs_to :user with FK constraint, so deleting user fails
      assert_raise Ecto.ConstraintError, fn ->
        Accounts.delete_user(user)
      end
    end
  end

  describe "list_users/0" do
    test "returns all users" do
      user_fixture()
      user_fixture()

      users = Accounts.list_users()
      assert length(users) >= 2
    end
  end

  describe "change_user/2" do
    test "returns a changeset with given attributes" do
      user = user_fixture()
      changeset = Accounts.change_user(user, %{name: "Changed"})
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :name) == "Changed"
    end

    test "returns a changeset with empty attrs by default" do
      user = user_fixture()
      changeset = Accounts.change_user(user)
      assert changeset.valid?
    end
  end
end
