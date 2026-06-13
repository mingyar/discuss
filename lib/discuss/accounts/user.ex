defmodule Discuss.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :provider, :string
    field :uid, :string
    field :token, :string
    field :avatar_url, :string
    field :name, :string

    has_many :topics, Discuss.Discussions.Topic
    has_many :comments, Discuss.Discussions.Comment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :provider, :uid, :token, :avatar_url, :name])
    |> validate_required([:email, :provider, :uid])
    |> unique_constraint(:email)
    |> unique_constraint([:provider, :uid])
  end
end
