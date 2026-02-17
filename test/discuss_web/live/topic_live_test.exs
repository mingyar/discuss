defmodule DiscussWeb.TopicLiveTest do
  use DiscussWeb.ConnCase
  import Phoenix.LiveViewTest
  import Discuss.AccountsFixtures
  import Discuss.DiscussionsFixtures
  alias Discuss.Discussions

  describe "Show - Real-time updates" do
    test "receives real-time comment updates", %{conn: conn} do
      user = user_fixture()
      topic = topic_fixture()
      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      # Another user creates a comment
      {:ok, _comment} = Discussions.create_comment(user, topic, %{content: "New comment"})

      # LiveView should receive the update automatically
      assert render(show_live) =~ "New comment"
    end

    test "receives real-time comment deletion", %{conn: conn} do
      topic = topic_fixture()
      comment = comment_fixture(topic)
      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      # Verify that the comment is there
      assert render(show_live) =~ comment.content

      # Delete the comment
      {:ok, _} = Discussions.delete_comment(comment)

      # The comment should disappear automatically
      refute render(show_live) =~ comment.content
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
      assert render(show_live_1) =~ "From user 1"
      assert render(show_live_2) =~ "From user 1"
    end
  end
end
