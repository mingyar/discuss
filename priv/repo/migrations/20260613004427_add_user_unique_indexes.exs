defmodule Discuss.Repo.Migrations.AddUserUniqueIndexes do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:email])
    create unique_index(:users, [:provider, :uid])
  end
end
