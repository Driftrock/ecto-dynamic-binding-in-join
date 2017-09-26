defmodule App.Event do
  use Ecto.Schema

  schema "events" do
    field :name, :string
    field :location, :string
    belongs_to :customer, App.Customer
  end
end
