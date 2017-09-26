# Ecto use of `...` (last binding) in dynamic as part of ON clause

Demonstration of bug in Ecto's `dynamic` when used with "last binding" operator
as ON clause of the constructed JOIN statement

## Use case

We want to dynamically add multiple `INNER JOIN` clauses to the query
based on many filters from the user request. Each JOIN has different ON clause
that is referencing that particular JOINED table.

## Problem

Using `join_cond = dynamic([c, ..., last_join])` in `on: join_cond` results
in that the `last_join` binding is calculated to the previous binding, instead of the current
join table where `on:` is being added.

Example:

```
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
```

## Run

```
mix deps.get
mix ecto.create
mix ecto.migrate
mix test
```

What happens:

```
     ** (Ecto.QueryError) deps/ecto/lib/ecto/association.ex:509: field `location` in `join` does not exist in schema App.Customer in query:

     from c in App.Customer,
       join: e0 in App.Event,
       on: e0.customer_id == c.id and (c.name == ^"Event 1" and c.location == ^"Location 1"),
       join: e1 in App.Event,
       on: e1.customer_id == c.id and (e0.name == ^"Event 2" and e0.location == ^"Location 2"),
       where: c.name == "Test Customer",
       select: c
```

Notice that the first `join: e0` has `on:` clause with `c.name`, and the second
`join: e1` has `on:` clause with the `e0.name`.

What should happen:

The query should look like this:
```
     from c in App.Customer,
       join: e0 in App.Event,
       on: e0.customer_id == c.id and (e0.name == ^"Event 1" and e0.location == ^"Location 1"),
       join: e1 in App.Event,
       on: e1.customer_id == c.id and (e1.name == ^"Event 2" and e1.location == ^"Location 2"),
       where: c.name == "Test Customer",
       select: c
```
