defmodule DiscussWeb.TopicLive.Index do
  use DiscussWeb, :live_view

  alias Discuss.Discussions
  alias Discuss.Discussions.Topic

  @impl true
  def mount(_params, _session, socket) do
    # Load topics unconditionally — disconnected render (SSR) is what crawlers see,
    # so they need the data. This is the SEO exception to the async rule.
    topics = Discussions.list_topics()

    if connected?(socket) do
      Discussions.subscribe_to_topics()

      # Subscribe to each topic's channel for comment updates
      for topic <- topics do
        Discussions.subscribe_to_topic(topic.id)
      end
    end

    {:ok,
     socket
     |> assign(:loading, false)
     |> assign(:editing_topic_id, nil)
     |> stream(:topics, topics)
     |> assign_create_form()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Topics")
    |> assign(:topic, nil)
  end

  defp apply_action(socket, :new, _params) do
    # Inline composer replaces the new-topic modal, redirect to index
    socket
    |> assign(:page_title, "Topics")
    |> assign(:topic, nil)
    |> push_navigate(to: ~p"/topics")
  end

  @impl true
  def handle_info({:topic_created, topic}, socket) do
    {:noreply, stream_insert(socket, :topics, topic, at: 0)}
  end

  @impl true
  def handle_info({:topic_deleted, topic}, socket) do
    {:noreply, stream_delete(socket, :topics, topic)}
  end

  @impl true
  def handle_info({:topic_updated, topic}, socket) do
    {:noreply, stream_insert(socket, :topics, topic)}
  end

  @impl true
  def handle_info({:comment_created, comment}, socket) do
    # Re-fetch the topic with comments preloaded; if the topic was deleted
    # between the comment broadcast and this handler, silently no-op
    case Discussions.get_topic(comment.topic_id) do
      nil -> {:noreply, socket}
      topic -> {:noreply, stream_insert(socket, :topics, topic)}
    end
  end

  @impl true
  def handle_info({:comment_deleted, comment}, socket) do
    # Re-fetch the topic with comments preloaded; if the topic was deleted
    # between the comment broadcast and this handler, silently no-op
    case Discussions.get_topic(comment.topic_id) do
      nil -> {:noreply, socket}
      topic -> {:noreply, stream_insert(socket, :topics, topic)}
    end
  end

  @impl true
  def handle_event("create_topic", %{"topic" => topic_params}, socket) do
    case Discussions.create_topic(socket.assigns.current_user, topic_params) do
      {:ok, _topic} ->
        {:noreply,
         socket
         |> assign_create_form()
         |> put_flash(:info, "Topic created!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:create_form, to_form(changeset, action: :validate))}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You must be signed in to create a topic")}
    end
  end

  @impl true
  def handle_event("start_edit", %{"id" => topic_id}, socket) do
    case Discussions.get_topic(topic_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Topic not found")}

      topic ->
        {:noreply,
         socket
         |> assign(:editing_topic_id, topic_id)
         |> stream_insert(:topics, topic)}
    end
  end

  @impl true
  def handle_event(
        "save_edit",
        %{"topic_id" => topic_id_str, "title" => title, "content" => content},
        socket
      ) do
    topic_id =
      case Integer.parse(topic_id_str) do
        {parsed, _} -> parsed
        :error -> topic_id_str
      end

    case Discussions.get_topic(topic_id) do
      nil ->
        {:noreply,
         socket
         |> assign(:editing_topic_id, nil)
         |> put_flash(:error, "Topic not found")}

      topic ->
        case Discussions.update_topic_by_user(socket.assigns.current_user, topic, %{
               "title" => title,
               "content" => content
             }) do
          {:ok, updated_topic} ->
            topic = Discussions.get_topic!(updated_topic.id)

            {:noreply,
             socket
             |> assign(:editing_topic_id, nil)
             |> stream_insert(:topics, topic)
             |> put_flash(:info, "Topic updated!")}

          {:error, :unauthorized} ->
            topic = Discussions.get_topic!(topic_id)

            {:noreply,
             socket
             |> assign(:editing_topic_id, nil)
             |> stream_insert(:topics, topic)
             |> put_flash(:error, "You can only edit your own topics")}

          {:error, %Ecto.Changeset{} = changeset} ->
            message =
              changeset
              |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
                Regex.replace(~r/%\{(\w+)\}/, msg, fn _, key ->
                  opts[String.to_existing_atom(key)] |> to_string()
                end)
              end)
              |> Enum.map(fn {key, msgs} -> "#{key}: #{Enum.join(msgs, ", ")}" end)
              |> Enum.join("; ")

            {:noreply,
             socket
             |> assign(:editing_topic_id, nil)
             |> put_flash(:error, message)}
        end
    end
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    topic_id = socket.assigns.editing_topic_id

    socket =
      if topic_id do
        case Discussions.get_topic(topic_id) do
          nil -> socket
          topic -> stream_insert(socket, :topics, topic)
        end
      else
        socket
      end

    {:noreply, assign(socket, :editing_topic_id, nil)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Discussions.get_topic(id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Topic not found")}

      topic ->
        case Discussions.delete_topic_by_user(socket.assigns.current_user, topic) do
          {:ok, _} ->
            {:noreply, put_flash(socket, :info, "Topic deleted")}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "You can only delete your own topics")}
        end
    end
  end

  @impl true
  def handle_event("create_comment", %{"topic-id" => topic_id, "content" => content}, socket) do
    case Discussions.get_topic(topic_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Topic not found")}

      topic ->
        case Discussions.create_comment(socket.assigns.current_user, topic, %{
               "content" => content
             }) do
          {:ok, _comment} ->
            # Re-fetch topic with comments preloaded and re-stream
            topic = Discussions.get_topic!(topic_id)

            {:noreply,
             socket
             |> stream_insert(:topics, topic)
             |> put_flash(:info, "Comment added!")}

          {:error, %Ecto.Changeset{}} ->
            {:noreply, put_flash(socket, :error, "Could not add comment")}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "You must be signed in to comment")}
        end
    end
  end

  defp assign_create_form(socket) do
    assign(socket, :create_form, to_form(Discussions.change_topic(%Topic{})))
  end
end
