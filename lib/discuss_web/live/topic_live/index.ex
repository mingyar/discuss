defmodule DiscussWeb.TopicLive.Index do
  use DiscussWeb, :live_view

  alias Discuss.Discussions
  alias Discuss.Discussions.Topic

  @impl true
  def mount(_params, _session, socket) do
    guest_user = Discuss.Accounts.get_user_by_email("guest@discuss.app")

    {:ok,
     socket
     |> assign(:current_user, guest_user)
     |> stream(:topics, Discussions.list_topics())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Topic")
    |> assign(:topic, %Topic{})
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

  @impl true
  def handle_info({DiscussWeb.TopicLive.FormComponent, {:saved, topic}}, socket) do
    {:noreply, stream_insert(socket, :topics, topic, at: 0)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    topic = Discussions.get_topic!(id)

    if socket.assigns.current_user.id == topic.user_id do
      {:ok, _} = Discussions.delete_topic(topic)
      {:noreply, stream_delete(socket, :topics, topic)}
    else
      {:noreply, put_flash(socket, :error, "You can only delete your own topics")}
    end
  end
end
