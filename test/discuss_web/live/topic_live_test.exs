defmodule DiscussWeb.TopicLiveTest do
  use DiscussWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import Discuss.AccountsFixtures
  import Discuss.DiscussionsFixtures
  alias Discuss.Discussions
  alias Discuss.Repo

  describe "Index" do
    test "renders topics list", %{conn: conn} do
      topic = topic_fixture()

      {:ok, index_live, _html} = live(conn, ~p"/topics")

      assert has_element?(index_live, "#topics", topic.title)
    end

    test "shows empty state when no topics exist", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/topics")

      assert has_element?(index_live, "#topics-empty")
    end

    test "topic owner can delete their own topic", %{conn: conn} do
      user = user_fixture()
      topic_fixture(user)

      conn = init_test_session(conn, user_id: user.id)

      {:ok, index_live, _html} = live(conn, ~p"/topics")

      assert has_element?(index_live, "button[aria-label='Delete topic']")

      index_live
      |> element("button[aria-label='Delete topic']")
      |> render_click()

      refute has_element?(index_live, ~s/[aria-label="Delete topic"]/)
    end

    test "non-owner cannot delete another user's topic", %{conn: conn} do
      owner = user_fixture()
      _topic = topic_fixture(owner)

      other_user = user_fixture()

      conn = init_test_session(conn, user_id: other_user.id)

      {:ok, index_live, _html} = live(conn, ~p"/topics")

      refute has_element?(index_live, "button[aria-label='Delete topic']")
    end

    test "real-time insert when a new topic is created", %{conn: conn} do
      user = user_fixture()
      # seed an existing topic
      topic_fixture(user)
      {:ok, index_live, _html} = live(conn, ~p"/topics")

      # Simulate another user creating a topic via PubSub broadcast
      {:ok, topic} = Discussions.create_topic(user, %{title: "Real-time topic"})
      topic = Repo.preload(topic, [:user, :comments])

      send(index_live.pid, {:topic_created, topic})

      assert has_element?(index_live, "#topics", "Real-time topic")
    end

    test "real-time delete when a topic is deleted", %{conn: conn} do
      user = user_fixture()
      topic = topic_fixture(user)
      {:ok, index_live, _html} = live(conn, ~p"/topics")

      # Verify the topic is visible first
      assert has_element?(index_live, "#topics", topic.title)

      # Simulate another user deleting the topic via PubSub broadcast
      {:ok, deleted} = Discussions.delete_topic(topic)
      deleted = Repo.preload(deleted, [:user, :comments])

      send(index_live.pid, {:topic_deleted, deleted})

      refute has_element?(index_live, "#topics", topic.title)
    end

    test "real-time update when a topic title changes", %{conn: conn} do
      user = user_fixture()
      topic = topic_fixture(user)
      {:ok, index_live, _html} = live(conn, ~p"/topics")

      # Simulate topic being updated by another user via PubSub broadcast
      {:ok, updated} =
        Discussions.update_topic_by_user(topic.user, topic, %{title: "Updated from broadcast"})

      updated = Repo.preload(updated, [:user, :comments])

      send(index_live.pid, {:topic_updated, updated})

      assert has_element?(index_live, "#topics", "Updated from broadcast")
    end

    test "real-time update when topic is not in stream yet", %{conn: conn} do
      # When a topic is created while LiveView is already mounted,
      # it arrives via {:topic_created, topic} broadcast
      user = user_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/topics")

      topic =
        %Discuss.Discussions.Topic{
          title: "Brand new topic",
          user_id: user.id
        }
        |> Repo.insert!()

      topic = Repo.preload(topic, [:user, :comments])

      send(index_live.pid, {:topic_created, topic})

      assert has_element?(index_live, "#topics", "Brand new topic")
    end

    test "shows inline composer for authenticated user", %{conn: conn} do
      user = user_fixture()
      topic_fixture(user)

      conn = init_test_session(conn, user_id: user.id)

      {:ok, index_live, _html} = live(conn, ~p"/topics")

      assert has_element?(index_live, "#create-topic-form")
      assert render(index_live) =~ "What do you want to discuss?"
    end

    test "shows sign-in prompt in composer for unauthenticated user", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/topics")

      assert html =~ "Sign in"
      assert html =~ "to start a discussion"
    end

    test "creates a topic via inline composer", %{conn: conn} do
      user = user_fixture()

      conn = init_test_session(conn, user_id: user.id)

      {:ok, index_live, _html} = live(conn, ~p"/topics")

      index_live
      |> form("#create-topic-form", topic: %{title: "Posted via composer"})
      |> render_submit()

      assert has_element?(index_live, "#topics", "Posted via composer")
    end

    test "unauthenticated user cannot create topic via direct event", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/topics")

      # Attempt to create a topic by sending the event directly
      index_live |> render_hook("create_topic", %{"topic" => %{"title" => "Hacked topic"}})

      # The topic should NOT appear in the list
      refute has_element?(index_live, "#topics", "Hacked topic")

      # Verify flash message is shown
      assert render(index_live) =~ "You must be signed in"
    end

    test "unauthenticated user cannot create comment via direct event on Index", %{conn: conn} do
      topic = topic_fixture()

      {:ok, index_live, _html} = live(conn, ~p"/topics")

      # Attempt to create a comment by sending the event directly
      index_live
      |> render_hook("create_comment", %{
        "topic-id" => to_string(topic.id),
        "content" => "Hacked comment"
      })

      # The comment should NOT appear
      refute has_element?(index_live, "#comments", "Hacked comment")

      # Verify the flash message
      assert render(index_live) =~ "must be signed in"
    end
  end

  describe "Show" do
    test "owner can edit topic title inline", %{conn: conn} do
      user = user_fixture()
      topic = topic_fixture(user)
      updated_title = "Updated title - #{System.unique_integer([:positive])}"

      conn = init_test_session(conn, user_id: user.id)

      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      # Start editing by clicking the title
      show_live |> element("h1", topic.title) |> render_click()

      # Now submit the updated title via the form
      show_live
      |> form("form[phx-submit=save_edit]", %{topic_id: topic.id, title: updated_title})
      |> render_submit()

      assert has_element?(show_live, "h1", updated_title)
      assert render(show_live) =~ "Topic updated!"

      # Verify the change persisted in the database
      updated = Discussions.get_topic!(topic.id)
      assert updated.title == updated_title
    end

    test "receives real-time comment updates", %{conn: conn} do
      user = user_fixture()
      topic = topic_fixture()
      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      # Another user creates a comment
      {:ok, _comment} = Discussions.create_comment(user, topic, %{content: "New comment"})

      # LiveView should receive the update automatically
      assert has_element?(show_live, "#comments", "New comment")
    end

    test "receives real-time comment deletion", %{conn: conn} do
      topic = topic_fixture()
      comment = comment_fixture(topic)
      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      # Verify that the comment is there
      assert has_element?(show_live, "#comments", comment.content)

      # Delete the comment
      {:ok, _} = Discussions.delete_comment(comment)

      # The comment should disappear automatically
      refute has_element?(show_live, "#comments", comment.content)
    end

    test "multiple users see same comments in real-time", %{conn: conn} do
      topic = topic_fixture()
      user = user_fixture()

      # Two users connected to the same topic
      {:ok, show_live_1, _html} = live(conn, ~p"/topics/#{topic}")
      {:ok, show_live_2, _html} = live(conn, ~p"/topics/#{topic}")

      # User 1 creates comment
      {:ok, _comment} = Discussions.create_comment(user, topic, %{content: "From user 1"})

      # Both should see it
      assert has_element?(show_live_1, "#comments", "From user 1")
      assert has_element?(show_live_2, "#comments", "From user 1")
    end

    test "unauthenticated user cannot create comment via direct event", %{conn: conn} do
      topic = topic_fixture()

      # Mount Show page without auth
      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      # Attempt to create a comment by sending the event directly
      show_live
      |> render_hook("save_comment", %{"comment" => %{"content" => "Hacked comment"}})

      # The comment should NOT appear in the list
      refute has_element?(show_live, "#comments", "Hacked comment")

      # Verify the flash message
      assert render(show_live) =~ "must be signed in"
    end

    test "receives real-time topic title updates", %{conn: conn} do
      user = user_fixture()
      topic = topic_fixture(user)
      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      # Another user updates the topic
      {:ok, _updated} =
        Discussions.update_topic_by_user(user, topic, %{title: "Updated from broadcast"})

      # The Show page should see the new title
      assert has_element?(show_live, "h1", "Updated from broadcast")
    end
  end
end
