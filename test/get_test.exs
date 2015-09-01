defmodule CouchexGetTest do
    use ExUnit.Case

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
      {:ok, res2} = Couchex.Client.del("test", %{"_id" => res1["id"], "_rev" => res1["rev"]})
       
    end

end
