defmodule Discuss.Discussions do
  @moduledoc """
  The Discussions context — manages topics and comments.
  """

  import Ecto.Query
  alias Discuss.Repo
  alias Discuss.Discussions.{Topic, Comment}

  # ============================================================================
  # Topics
  # ============================================================================

  @doc """
  Lists all topics with users preloaded, ordered by date.
  """
  def list_topics do
    Topic
    |> preload(:user)
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns a topic by ID with its user and comments preloaded.
  """
  def get_topic!(id) do
    Topic
    |> preload([:user, comments: [:user]])
    |> Repo.get!(id)
  end

  @doc """
  Creates a new topic associated with a user.
  """
  def create_topic(user, attrs) do
    user
    |> Ecto.build_assoc(:topics)
    |> Topic.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing topic.
  """
  def update_topic(%Topic{} = topic, attrs) do
    topic
    |> Topic.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a topic.
  """
  def delete_topic(%Topic{} = topic) do
    from(c in Comment, where: c.topic_id == ^topic.id)
    |> Repo.delete_all()

    Repo.delete(topic)
  end

  @doc """
  Returns a changeset for tracking topic changes.
  """
  def change_topic(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end

  # ============================================================================
  # Comments
  # ============================================================================

  @doc """
  Lists all comments for a specific topic.
  """
  def list_comments_for_topic(topic_id) do
    Comment
    |> where([c], c.topic_id == ^topic_id)
    |> preload(:user)
    |> order_by([c], asc: c.inserted_at)
    |> Repo.all()
  end

  @doc """
  Creates a new comment and broadcasts to connected users.
  """
  def create_comment(user, topic, attrs) do
    topic
    |> Ecto.build_assoc(:comments)
    |> Comment.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
    |> broadcast_comment(:comment_created)
  end

  @doc """
  Deletes a comment and broadcasts the deletion.
  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
    |> broadcast_comment(:comment_deleted)
  end

  @doc """
  Subscribes the current process to receive updates from a topic.
  """
  def subscribe_to_topic(topic_id) do
    Phoenix.PubSub.subscribe(Discuss.PubSub, "topic:#{topic_id}")
  end

  @doc """
  Returns a changeset for tracking comment changes.
  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  def get_comment!(id) do
    Repo.get!(Comment, id)
  end

  defp broadcast_comment({:ok, comment} = result, event) do
    # Preload associations before broadcasting
    comment = Repo.preload(comment, [:user, :topic])

    Phoenix.PubSub.broadcast(
      Discuss.PubSub,
      "topic:#{comment.topic_id}",
      {event, comment}
    )

    result
  end

  defp broadcast_comment(error, _event), do: error
end
