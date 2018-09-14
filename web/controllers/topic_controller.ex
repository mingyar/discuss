defmodule Discuss.TopicController do
    use Discuss.Web, :controller

    alias Discuss.Topic

    def new(conn, _params) do
        changeset = Topic.changeset(%Topic{}, %{})

        render conn, "new.html", changeset: changeset

    end

    @spec create(any(), map()) :: nil
    def create(conn, %{"topic" => topic}) do
        changeset = Topic.changeset(%Topic{}, topic)

        case Repo.insert(changeset) do
            {:ok, post} -> IO.inspect(post)
            {:error, changeset} ->
                render conn, "new.html", changeset: changeset
        end

    end
end
