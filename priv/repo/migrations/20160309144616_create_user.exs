defmodule Backend.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :fullname, :string
      add :email, :string
      add :age, :integer

      timestamps
    end

  end
end
