defmodule DiscussWeb.TopicLive.Show do
  use DiscussWeb, :live_view

  alias Discuss.Discussions
  alias Discuss.Discussions.Comment

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Discussions.get_topic(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Topic not found")
         |> push_navigate(to: ~p"/topics")}

      topic ->
        if connected?(socket) do
          Discussions.subscribe_to_topic(id)
        end

        comments_count = length(topic.comments)

        {:ok,
         socket
         |> assign(:topic, topic)
         |> assign(:page_title, topic.title)
         |> assign(:comments_count, comments_count)
         |> stream(:comments, topic.comments)
         |> assign_comment_form()}
    end
  end

  @impl true
  def handle_event("save_comment", %{"comment" => comment_params}, socket) do
    case Discussions.create_comment(
           socket.assigns.current_user,
           socket.assigns.topic,
           comment_params
         ) do
      {:ok, _comment} ->
        {:noreply,
         socket
         |> assign_comment_form()
         |> put_flash(:info, "Comment created successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, comment_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_comment", %{"id" => id}, socket) do
    case Discussions.get_comment(id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Comment not found")}

      comment ->
        case Discussions.delete_comment_by_user(socket.assigns.current_user, comment) do
          {:ok, _} ->
            {:noreply, put_flash(socket, :info, "Comment deleted")}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "You can only delete your own comments")}
        end
    end
  end

  @impl true
  def handle_info({:comment_created, comment}, socket) do
    {:noreply,
     socket
     |> update(:comments_count, &(&1 + 1))
     |> stream_insert(:comments, comment)}
  end

  @impl true
  def handle_info({:comment_deleted, comment}, socket) do
    {:noreply,
     socket
     |> update(:comments_count, &(&1 - 1))
     |> stream_delete(:comments, comment)}
  end

  defp assign_comment_form(socket) do
    assign(socket, :comment_form, to_form(Discussions.change_comment(%Comment{})))
  end
end
