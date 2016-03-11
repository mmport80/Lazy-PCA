defmodule Backend.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :fullname
      remove :email
      remove :age

      add :name, :string
      add :username, :string
      add :password, :string, virtual: true
      add :password_hash, :string




    end

  end
end
