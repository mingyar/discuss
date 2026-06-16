defmodule Discuss.Discussions.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topics" do
    field :title, :string
    field :content, :string

    belongs_to :user, Discuss.Accounts.User
    has_many :comments, Discuss.Discussions.Comment, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:title, :content])
    |> validate_required([:title])
    |> validate_length(:title, min: 3, max: 255)
    |> validate_length(:content, max: 500)
  end
end
