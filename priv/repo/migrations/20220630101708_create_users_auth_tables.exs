defmodule Clubhouse.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    create table(:users) do
      add :uid, :string, null: false
      add :email, :citext, null: false

      add :first_name, :string
      add :last_name, :string
      add :username, :string
      add :student_id, :integer

      add :suspended, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:users, [:uid])
    create unique_index(:users, [:email])
    create unique_index(:users, [:username])

    create table(:users_tokens) do
      add :token, :string, null: false
      add :context, :string, null: false

      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
