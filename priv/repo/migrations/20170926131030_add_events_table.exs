defmodule App.Repo.Migrations.AddEventsTable do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :name, :string
      add :location, :string
      add :customer_id, references(:customers, on_delete: :nothing)

      timestamps()
    end
  end
end
