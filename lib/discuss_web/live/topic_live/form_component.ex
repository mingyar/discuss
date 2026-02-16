defmodule DiscussWeb.TopicLive.FormComponent do
  use DiscussWeb, :live_component

  alias Discuss.Discussions

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage topic records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="topic-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Topic</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{topic: topic} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Discussions.change_topic(topic))
     end)}
  end

  @impl true
  def handle_event("validate", %{"topic" => topic_params}, socket) do
    changeset = Discussions.change_topic(socket.assigns.topic, topic_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"topic" => topic_params}, socket) do
    save_topic(socket, socket.assigns.action, topic_params)
  end

  defp save_topic(socket, :edit, topic_params) do
    case Discussions.update_topic(socket.assigns.topic, topic_params) do
      {:ok, topic} ->
        notify_parent({:saved, topic})

        {:noreply,
         socket
         |> put_flash(:info, "Topic updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_topic(socket, :new, topic_params) do
    case Discussions.create_topic(socket.assigns.current_user, topic_params) do
      {:ok, topic} ->
        notify_parent({:saved, topic})

        {:noreply,
         socket
         |> put_flash(:info, "Topic created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
