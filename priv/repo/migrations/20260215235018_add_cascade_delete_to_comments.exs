defmodule Discuss.Repo.Migrations.AddCascadeDeleteToComments do
  use Ecto.Migration

  def up do
    drop constraint(:comments, "comments_topic_id_fkey")

    alter table(:comments) do
      modify :topic_id, references(:topics, on_delete: :delete_all)
    end
  end

  def down do
    drop constraint(:comments, "comments_topic_id_fkey")

    alter table(:comments) do
      modify :topic_id, references(:topics, on_delete: :nothing)
    end
  end
end
