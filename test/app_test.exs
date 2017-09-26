defmodule AppTest do
  use ExUnit.Case, async: true
  import Ecto.Query
  alias App.Customer
  alias App.Event

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(App.Repo)
  end

  def add_event_filter_from_params(query, params) do
    # construct "ON" condition as conjunction of all params on the last JOIN binding
    join_on = List.foldl(params, true, fn {column, value}, previous ->
      dynamic([c, ..., ev], fragment("? = ?", field(ev, ^column), ^value) and ^previous)
    end)

    # append the inner join to the query, with extra ON condition from dynamic above
    from c in query,
      inner_join: ev in assoc(c, :events),
      on: ^join_on
  end

  test "dynamic use last binding in each join appended in run time query" do
    query = from c in Customer,
            where: c.name == "Test Customer"

    # Add two filters (this would be in app map over 0..N filters from user)
    query = query
      |> add_event_filter_from_params([name: "Event 1", location: "Location 1"])
      |> add_event_filter_from_params([name: "Event 2", location: "Location 2"])

    # Expect the query be successfull, with each JOIN's ON condition
    # reference its JOIN binding
    result = App.Repo.all(query)
  end

  test "dynamic use last binding in each join appended in compile time query" do
    query = from c in Customer,
            where: c.name == "Test Customer"

    # construct "ON" condition as conjunction of all params on the last JOIN binding
    # the `ev` here should be calculated as `e1`
    join_on = dynamic([c, ..., ev], ev.name == "Event 1" and ev.location == "Location 1")

    # append the inner join to the query, with extra ON condition from dynamic above
    query = from c in query,
      inner_join: ev in assoc(c, :events),
      on: ^join_on

    # add one more join. this time `ev` here should be calculated as `e2`
    join_on = dynamic([c, ..., ev], ev.name == "Event 2" and ev.location == "Location 2")

    query = from c in query,
      inner_join: ev in assoc(c, :events),
      on: ^join_on

    # Expect the query be successfull, with each JOIN's ON condition
    # reference its JOIN binding
    result = App.Repo.all(query)
  end
end
