defmodule Discuss.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :provider, :string
      add :uid, :string
      add :token, :string
      add :avatar_url, :string
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
