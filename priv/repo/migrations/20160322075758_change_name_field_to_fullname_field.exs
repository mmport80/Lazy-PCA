defmodule Backend.Repo.Migrations.ChangeNameFieldToFullnameField do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :name
      add :fullname, :string
    end
  end
end
