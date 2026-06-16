defmodule Discuss.Repo.Migrations.AddContentToTopics do
  use Ecto.Migration

  def change do
    alter table(:topics) do
      add :content, :text
    end
  end
end
