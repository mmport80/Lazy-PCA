

defmodule Backend.Repo.Migrations.AddPlotsTable2 do
  use Ecto.Migration

  def change do
    create table(:plots2) do
      add :source, :string
      add :ticker, :string
      add :frequency, :integer
      add :startDate, :date
      add :endDate, :date
      add :y, :boolean
      add :deleted, :boolean
      add :user_id, :integer#, references(:users)


      timestamps
    end

  end
end
