defmodule Discuss.Repo.Migrations.MakeCommentsUserIdNonNullable do
  use Ecto.Migration

  def change do
    # Remove orphaned comments before making user_id non-nullable
    execute "DELETE FROM comments WHERE user_id IS NULL", ""

    # Drop existing FK constraint before modifying the column
    drop constraint(:comments, "comments_user_id_fkey")

    alter table(:comments) do
      modify :user_id, references(:users, on_delete: :delete_all), null: false
    end
  end
end
