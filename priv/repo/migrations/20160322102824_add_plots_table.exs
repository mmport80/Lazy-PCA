

defmodule Backend.Repo.Migrations.AddPlotsTable do
  use Ecto.Migration

  def change do
    create table(:plots) do
      add :source, :string
      add :ticker, :string
      add :frequency, :integer
      add :startDate, :date
      add :endDate, :date
      add :y, :boolean
      add :deleted, :boolean
      add :user_id, :integer


      timestamps
    end

  end
end
