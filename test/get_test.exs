defmodule CouchexGetTest do
    use ExUnit.Case

# Design doc used for these tests
# {
#    "_id": "_design/foo",
#    "_rev": "6-998e3294a8bab503793e876df6b69376",
#    "language": "javascript",
#    "views": {
#        "bar": {
#            "map": "function(doc) {\n  if(doc.foo){\n    emit(doc.foo, doc);\n  }\n}"
#        },
#        "reduce": {
#            "map": "function(doc) {\n  if(doc.foo){\n    emit(doc.foo, 1);\n  }\n}",
#            "reduce": "_sum()"
#        }
#    }
# }

    test "add a document" do
      database_checks!
      doc = %{"foo" => "bar", "number" => 5, "float" => 3.1415, "array" => ["bla", "blubb"]}
      {:ok, res} = Couchex.Client.put("test", doc)
      assert res["ok"] == true
    end

    test "get a document" do
      database_checks!
      id = "bla"
      {:ok, doc} = Couchex.Client.get("test", id)
      assert id == doc["_id"]
    end

    test "update a document" do
      database_checks!
      {:ok, doc} = Couchex.Client.get("test", "bla")
      doc1 = %{doc | "pid" => :erlang.pid_to_list(self())}
      {:ok, res} = Couchex.Client.put("test", doc1)
      assert res["ok"] == true
    end

    test "delete a document" do
      database_checks!
      doc = %{"foo" => "bar"}
      {:ok, res1} = Couchex.Client.put("test", doc)
      # {:ok,
      # %{"id" => "28c7eceb4088ca72956845284d0010e8", "ok" => true,
      #      "rev" => "1-afad29a7c5b82c61e9aa70ab4fd2e265"}}
      {:ok, res2} = Couchex.Client.del("test", %{id: res1["id"], rev: res1["rev"]})
      assert res2["ok"] == true
      assert res1["id"] == res2["id"]
    end

    test "get view" do
      database_checks!
      {:ok, view} = Couchex.Client.get("test", %{view: "foo/bar", long: true})
      assert view["offset"] == 0
    end

    test "get view as a key based hash" do
      database_checks!
      doc = %{"foo" => "foobar"}
      {:ok, res} = Couchex.Client.put("test", doc)
      {:ok, view} = Couchex.Client.get("test", %{view: "foo/bar", key_based: true})
      assert view["bar"]["foo"] == "bar"
      assert view["foobar"]["foo"] == "foobar"
    end

    test "get reduce" do
      database_checks!
      key = "bar"
      # a reduce retruns a list!
      {:ok, [view]} = Couchex.Client.get("test", %{view: "foo/reduce"}, %{"group" => true, "key" => "bar"})
      assert view["key"] == "bar"
    end

    test "list all databases" do
      database_checks!
      {:ok, list} = Couchex.Client.all_dbs
      assert is_list(list), "#{inspect list} is not a list"
      assert Enum.member?(list, "_users"), "#{inspect list} should contain \"_users\""
    end

    test "create a database" do
      database_checks!
      {:ok, res} = Couchex.Client.create_db("test_db_for_db_creation")
      assert res["ok"] == true
      {:ok, _res} = Couchex.Client.delete_db("test_db_for_db_creation")
    end

    test "delete a database" do
      database_checks!
      {:ok, _res} = Couchex.Client.create_db("test_db_for_db_deletion")
      {:ok, res} = Couchex.Client.delete_db("test_db_for_db_deletion")
      assert res["ok"] == true
    end

    defp database_checks! do
      {:ok, db_list} = Couchex.Client.all_dbs

      if ! Enum.member?(db_list, "test") do
        raise "CouchDB database missing"
      end

      if  Enum.member?(db_list, "test_db_for_db_creation") ||
          Enum.member?(db_list, "test_db_for_db_deletion") do
        raise "CouchDB database not cleaned up after last test"
      end
    end
end
