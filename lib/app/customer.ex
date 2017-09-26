defmodule App.Customer do
  use Ecto.Schema

  schema "customers" do
    field :name, :string
    has_many :events, App.Event
  end
end
