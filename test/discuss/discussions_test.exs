defmodule Discuss.DiscussionsTest do
  use Discuss.DataCase

  import Discuss.AccountsFixtures
  import Discuss.DiscussionsFixtures

  alias Discuss.Discussions
  alias Discuss.Discussions.Comment

  describe "comments with PubSub" do
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
end
