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
      doc = %{"foo" => "bar", "number" => 5, "float" => 3.1415, "array" => ["bla", "blubb"]}
      {:ok, res} = Couchex.Client.put("test", doc)
      assert res["ok"] == true
    end

    test "get a document" do
      id = "bla"
      {:ok, doc} = Couchex.Client.get("test", id)
      assert id == doc["_id"]
    end

    test "update a document" do
      {:ok, doc} = Couchex.Client.get("test", "bla")
      doc1 = %{doc | "pid" => :erlang.pid_to_list(self())}
      {:ok, res} = Couchex.Client.put("test", doc1)
      assert res["ok"] == true
    end

    test "delete a document" do
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
      {:ok, view} = Couchex.Client.get("test", %{view: "foo/bar", long: true})
      assert view["offset"] == 0
    end

    test "get reduce" do
      key = "bar"
      # a reduce retruns a list!
      {:ok, [view]} = Couchex.Client.get("test", %{view: "foo/reduce"}, %{"group" => true, "key" => "bar"})
      assert view["key"] == "bar"
    end
end
