defmodule Discuss.DiscussionsTest do
  use Discuss.DataCase, async: true

  import Discuss.AccountsFixtures
  import Discuss.DiscussionsFixtures

  alias Discuss.Discussions

  describe "comments with PubSub" do
    test "create_comment/3 returns unauthorized for nil user" do
      topic = topic_fixture()

      assert Discussions.create_comment(nil, topic, %{content: "Hacked"}) ==
               {:error, :unauthorized}
    end

    test "create_comment/3 broadcasts comment_created event" do
      user = user_fixture()
      topic = topic_fixture()

      # Subscribe to the topic
      Discussions.subscribe_to_topic(topic.id)

      {:ok, comment} = Discussions.create_comment(user, topic, valid_comment_attributes())

      # Verify that broadcast was received
      assert_receive {:comment_created, received_comment}
      assert received_comment.id == comment.id
    end

    test "delete_comment/1 broadcasts comment_deleted event" do
      topic = topic_fixture()
      comment = comment_fixture(topic)

      # Subscribe to the topic
      Discussions.subscribe_to_topic(topic.id)

      {:ok, deleted_comment} = Discussions.delete_comment(comment)

      # Verify that broadcast was received
      assert_receive {:comment_deleted, received_comment}
      assert received_comment.id == deleted_comment.id
    end

    test "subscribe_to_topic/1 subscribes current process" do
      topic = topic_fixture()

      # Subscribe
      :ok = Discussions.subscribe_to_topic(topic.id)

      # Verify subscription by checking if we receive broadcasts
      user = user_fixture()
      {:ok, _comment} = Discussions.create_comment(user, topic, valid_comment_attributes())

      assert_receive {:comment_created, _comment}
    end
  end

  describe "topics with PubSub" do
    test "create_topic/2 broadcasts topic_created event" do
      user = user_fixture()

      Discussions.subscribe_to_topics()

      title = "New PubSub Topic"
      {:ok, topic} = Discussions.create_topic(user, %{title: title})

      # Match on title to avoid picking up messages from parallel tests (async: true)
      assert_receive {:topic_created, %{title: ^title} = received_topic}
      assert received_topic.id == topic.id
    end

    test "update_topic/1 broadcasts topic_updated event" do
      topic = topic_fixture()

      Discussions.subscribe_to_topics()

      title = "Updated Title"
      {:ok, updated_topic} =
        Discussions.update_topic_by_user(topic.user, topic, %{title: title})

      assert_receive {:topic_updated, %{title: ^title} = received_topic}
      assert received_topic.id == updated_topic.id
    end

    test "delete_topic/1 broadcasts topic_deleted event" do
      topic = topic_fixture()

      Discussions.subscribe_to_topics()

      topic_id = topic.id
      {:ok, _deleted_topic} = Discussions.delete_topic(topic)

      assert_receive {:topic_deleted, %{id: ^topic_id}}
    end

    test "subscribe_to_topics/0 subscribes current process" do
      user = user_fixture()

      Discussions.subscribe_to_topics()

      {:ok, _topic} = Discussions.create_topic(user, %{title: "Trigger"})

      assert_receive {:topic_created, %{title: "Trigger"}}
    end
  end
end
