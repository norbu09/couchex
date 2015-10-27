Couchex
=======

A native Elixir CouchDb client
------------------------------

Love CouchDB, love Elixir, however no current client for my beloved DB
yet. This is work in process and currently only implements the most
basic commands, it will (hopefully) be a full featured CouchDB client at
some stage.

It is built on `hackney` and `Poison` and hopefully is fast. Future
versions will implement worker pools for additional performance.

This is based on the Perl client [Store-CouchDB](https://github.com/norbu09/Store-CouchDB/).

## Installation

First, add Couchex to your `mix.exs` dependencies:

```elixir
def deps do
  [{:couchex, github: "norbu09/couchex"}]
  end
```

Then, update your dependencies:

```sh-session
  $ mix deps.get
```

## Usage

```elixir
    iex> {:ok, doc} = Couchex.Client.get(database, doc_id)
    iex> {:ok, res} = Couchex.Client.put(database, doc)
```

