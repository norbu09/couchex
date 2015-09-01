defmodule Couchex.Client do
  
  require Logger
  @couch_url "http://localhost:5984/"

  def get(db, id) do
    path = db <> "/" <> id
    Logger.debug("Got request for: #{path}")
    talk(:get, path, nil, nil)
  end
  def get(db, id, opts) do
    path = db <> "/" <> id
    Logger.debug("Got request for: #{path} with opts")
    talk(:get, path, nil, opts)
  end


  def put(db, %{ "_id" => id} = doc) do
    path = db <> "/" <> id
    Logger.debug("Updating doc at: #{path}")
    
    talk(:put, path, doc, nil)
  end
  def put(db, doc) do
    Logger.debug("Posting new doc to: #{db}")
    talk(:post, db, doc, nil)
  end

  def del(db, %{ "_id" => id, "_rev" => rev} = doc) do
    path = db <> "/" <> id
    Logger.debug("Deleting doc: #{path}")
    talk(:delete, path, nil, %{"rev" => rev})
  end

  def talk(method, path_plain, doc, opts) do
    :hackney.start

    path = case opts do
      nil  -> path_plain
      opts -> path_plain <> "?" <> URI.encode_query(opts)
    end

    case get_content(method, path, doc) do
      {:ok, code, _headers, body_ref} ->
        {:ok, res} = :hackney.body body_ref
        parse_response(res, code)
      error -> error
    end
  end

  defp get_content(method, path, doc) do
    url = @couch_url <> path
    headers = [{"Content-Type", "application/json"}]
    Logger.debug("[#{method}] #{url}")

    case Poison.encode(doc) do
      # empty doc
      {:ok, "null"} ->
        :hackney.request(method, url, headers)
      {:ok, json} ->
        :hackney.request(method, url, headers, json)
      error -> error
    end
  end
  defp parse_response(res, code) do
    case Poison.decode(res) do
      {:ok, json} ->
        cond do
          code in 200..299 ->
            {:ok, json}
          code in 400..599 ->
            {:error, {{:http_status, code}, json}}
          true ->
            {:error, res}
        end
      {:error, json_err} ->
          {:error, json_err}
    end
  end
end
