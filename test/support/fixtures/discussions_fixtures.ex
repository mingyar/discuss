defmodule Discuss.DiscussionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discuss.Discussions` context.
  """

  import Discuss.AccountsFixtures

  def valid_topic_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      title: "Test Topic #{System.unique_integer()}"
    })
  end

  def topic_fixture(user \\ nil, attrs \\ %{}) do
    user = user || user_fixture()

    {:ok, topic} =
      attrs
      |> valid_topic_attributes()
      |> then(&Discuss.Discussions.create_topic(user, &1))

    Discuss.Repo.preload(topic, :user)
  end

  def valid_comment_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      content: "Test comment content"
    })
  end

  def comment_fixture(topic \\ nil, user \\ nil, attrs \\ %{}) do
    topic = topic || topic_fixture()
    user = user || user_fixture()

    {:ok, comment} =
      attrs
      |> valid_comment_attributes()
      |> then(&Discuss.Discussions.create_comment(user, topic, &1))

    Discuss.Repo.preload(comment, [:user, :topic])
  end
end
