defmodule DiscussWeb.TopicLive.Index do
  use DiscussWeb, :live_view

  alias Discuss.Discussions
  alias Discuss.Discussions.Topic

  @impl true
  def mount(_params, _session, socket) do
    # Load topics unconditionally — disconnected render (SSR) is what crawlers see,
    # so they need the data. This is the SEO exception to the async rule.
    topics = Discussions.list_topics()

    if connected?(socket), do: Discussions.subscribe_to_topics()

    {:ok,
     socket
     |> assign(:loading, false)
     |> stream(:topics, topics)
     |> assign_create_form()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    case Discussions.get_topic(id) do
      nil ->
        socket
        |> put_flash(:error, "Topic not found")
        |> push_navigate(to: ~p"/topics")

      topic ->
        if socket.assigns.current_user &&
             socket.assigns.current_user.id == topic.user_id do
          socket
          |> assign(:page_title, "Edit Topic")
          |> assign(:topic, topic)
        else
          socket
          |> put_flash(:error, "You can only edit your own topics")
          |> push_navigate(to: ~p"/topics")
        end
    end
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
  def handle_info({DiscussWeb.TopicLive.FormComponent, {:saved, topic}}, socket) do
    # The FormComponent fires notify_parent on edit.
    # The topic was already broadcast via update_topic/2 so the stream is already updated,
    # but this ensures the parent side-effects (flash navigation) still occur.
    # The duplicate stream_insert is a no-op since the DOM ID already exists.
    {:noreply, stream_insert(socket, :topics, topic)}
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

  defp assign_create_form(socket) do
    assign(socket, :create_form, to_form(Discussions.change_topic(%Topic{})))
  end
end
