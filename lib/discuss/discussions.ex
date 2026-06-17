defmodule Discuss.Discussions do
  @moduledoc """
  The Discussions context — manages topics and comments.
  """

  import Ecto.Query
  alias Discuss.Accounts.User
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
    |> preload([:user, comments: [:user]])
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns a topic by ID with its user and comments preloaded, or nil if not found.
  """
  def get_topic(id) do
    Topic
    |> preload([:user, comments: [:user]])
    |> Repo.get(id)
  end

  @doc """
  Returns a topic by ID or raises if not found.
  """
  def get_topic!(id) do
    Topic
    |> preload([:user, comments: [:user]])
    |> Repo.get!(id)
  end

  @doc """
  Subscribes the current process to receive topic-level updates (creates, deletes, updates).
  """
  def subscribe_to_topics do
    Phoenix.PubSub.subscribe(Discuss.PubSub, "topics")
  end

  @doc """
  Creates a new topic associated with a user and broadcasts to connected users.
  Returns `{:ok, topic}` on success, `{:error, changeset}` on validation failure,
  or `{:error, :unauthorized}` if no user is provided.
  """
  def create_topic(nil, _attrs), do: {:error, :unauthorized}

  def create_topic(user, attrs) do
    user
    |> Ecto.build_assoc(:topics)
    |> Topic.changeset(attrs)
    |> Repo.insert()
    |> broadcast_topic(:topic_created)
  end

  defp update_topic(%Topic{} = topic, attrs) do
    topic
    |> Topic.changeset(attrs)
    |> Repo.update()
    |> broadcast_topic(:topic_updated)
  end

  @doc """
  Updates a topic, verifying the user is the owner.
  Returns `{:ok, topic}` on success, `{:error, :unauthorized}` if the user does not own the topic,
  or `{:error, changeset}` on validation failure.
  """
  def update_topic_by_user(%User{id: user_id}, %Topic{user_id: user_id} = topic, attrs) do
    update_topic(topic, attrs)
  end

  def update_topic_by_user(_user, _topic, _attrs), do: {:error, :unauthorized}

  @doc """
  Deletes a topic and broadcasts the deletion. Comments are cascade-deleted at the database level.
  """
  def delete_topic(%Topic{} = topic) do
    Repo.delete(topic)
    |> broadcast_topic(:topic_deleted)
  end

  @doc """
  Deletes a topic, verifying the user is the owner.
  Returns `{:ok, topic}` on success, `{:error, :unauthorized}` if the user does not own the topic.
  """
  def delete_topic_by_user(%User{id: user_id}, %Topic{user_id: user_id} = topic) do
    delete_topic(topic)
  end

  def delete_topic_by_user(_user, _topic), do: {:error, :unauthorized}

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
  Returns `{:ok, comment}` on success, `{:error, changeset}` on validation failure,
  or `{:error, :unauthorized}` if no user is provided.
  """
  def create_comment(nil, _topic, _attrs), do: {:error, :unauthorized}

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
  Deletes a comment, verifying the user is the owner.
  Returns `{:ok, comment}` on success, `{:error, :unauthorized}` if the user does not own the comment.
  """
  def delete_comment_by_user(%User{id: user_id}, %Comment{user_id: user_id} = comment) do
    delete_comment(comment)
  end

  def delete_comment_by_user(_user, _comment), do: {:error, :unauthorized}

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

  @doc """
  Returns a comment by ID, or nil if not found.
  """
  def get_comment(id) do
    Repo.get(Comment, id)
  end

  def get_comment!(id) do
    Repo.get!(Comment, id)
  end

  defp broadcast_topic({:ok, topic} = result, event) do
    topic = Repo.preload(topic, [:user, comments: [:user]])

    Phoenix.PubSub.broadcast(Discuss.PubSub, "topics", {event, topic})

    result
  end

  defp broadcast_topic(error, _event), do: error

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
