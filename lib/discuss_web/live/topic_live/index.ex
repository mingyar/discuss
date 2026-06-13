defmodule DiscussWeb.TopicLive.Index do
  use DiscussWeb, :live_view

  alias Discuss.Discussions
  alias Discuss.Discussions.Topic
  alias Discuss.Repo

  @impl true
  def mount(_params, _session, socket) do
    # Load topics unconditionally — disconnected render (SSR) is what crawlers see,
    # so they need the data. This is the SEO exception to the async rule.
    topics = Discussions.list_topics()

    {:ok,
     socket
     |> assign(:loading, false)
     |> assign(:topics_count, length(topics))
     |> stream(:topics, topics)
     |> assign_create_form()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Topic")
    |> assign(:topic, Discussions.get_topic!(id))
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
  def handle_info({DiscussWeb.TopicLive.FormComponent, {:saved, topic}}, socket) do
    topic = Repo.preload(topic, :user)

    {:noreply,
     socket
     |> update(:topics_count, &(&1 + 1))
     |> stream_insert(:topics, topic, at: 0)}
  end

  @impl true
  def handle_event("create_topic", %{"topic" => topic_params}, socket) do
    case Discussions.create_topic(socket.assigns.current_user, topic_params) do
      {:ok, topic} ->
        topic = Repo.preload(topic, :user)

        {:noreply,
         socket
         |> update(:topics_count, &(&1 + 1))
         |> stream_insert(:topics, topic, at: 0)
         |> assign_create_form()
         |> put_flash(:info, "Topic created!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:create_form, to_form(changeset, action: :validate))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    topic = Discussions.get_topic!(id)

    case Discussions.delete_topic_by_user(socket.assigns.current_user, topic) do
      {:ok, _} ->
        {:noreply,
         socket
         |> update(:topics_count, &(&1 - 1))
         |> stream_delete(:topics, topic)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You can only delete your own topics")}
    end
  end

  defp assign_create_form(socket) do
    assign(socket, :create_form, to_form(Discussions.change_topic(%Topic{})))
  end
end
