defmodule Backend.Repo.Migrations.UniqIndexUser do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:username])
  end
end
