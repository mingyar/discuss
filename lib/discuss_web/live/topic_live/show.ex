defmodule DiscussWeb.TopicLive.Show do
  use DiscussWeb, :live_view

  alias Discuss.Discussions
  alias Discuss.Discussions.Comment

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    topic = Discussions.get_topic!(id)

    guest_user =
      Discuss.Accounts.get_user_by_email("guest@discuss.app")

    {:ok,
     socket
     |> assign(:current_user, guest_user)
     |> assign(:topic, topic)
     |> assign(:page_title, topic.title)
     |> stream(:comments, topic.comments)
     |> assign_comment_form()}
  end

  @impl true
  def handle_event("save_comment", %{"comment" => comment_params}, socket) do
    case Discussions.create_comment(
           # ← Agora usa o guest user real
           socket.assigns.current_user,
           socket.assigns.topic,
           comment_params
         ) do
      {:ok, comment} ->
        comment = Discuss.Repo.preload(comment, :user)

        {:noreply,
         socket
         |> stream_insert(:comments, comment)
         |> assign_comment_form()
         |> put_flash(:info, "Comment created successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, comment_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_comment", %{"id" => id}, socket) do
    comment = Discussions.get_comment!(id)

    if socket.assigns.current_user && socket.assigns.current_user.id == comment.user_id do
      {:ok, _} = Discussions.delete_comment(comment)
      {:noreply, stream_delete(socket, :comments, comment)}
    else
      {:noreply, put_flash(socket, :error, "You can only delete your own comments")}
    end
  end

  defp assign_comment_form(socket) do
    assign(socket, :comment_form, to_form(Discussions.change_comment(%Comment{})))
  end
end
