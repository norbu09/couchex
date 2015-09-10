defmodule Couchex.Client do
  
  require Logger

  def get(db, thing) do
    get(db, thing, nil)
  end
  def get(db, id, opts) when is_binary(id) do
    path = "#{db}/#{id}"
    Logger.debug("Got request for: #{path} with opts")
    talk(:get, path, nil, opts)
  end
  def get(db, view, opts) when is_map(view) do
    path = make_path(db, view)
    Logger.debug("Got request for: #{path} with opts")
    {:ok, res} = talk(:get, path, nil, opts)
    case view[:long] do
      true -> {:ok, res}
      _ ->    {:ok, res["rows"]}
    end
  end

  def put(db, %{ id: id} = doc) do
    path = "#{db}/#{id}"
    Logger.debug("Updating doc at: #{path}")
    
    talk(:put, path, doc, nil)
  end
  def put(db, doc) do
    Logger.debug("Posting new doc to: #{db}")
    talk(:post, db, doc, nil)
  end

  def del(db, %{ id: id, rev: rev}) do
    path = "#{db}/#{id}"
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

  defp make_path(db, %{view: view_path}) do
    [design, view] = String.split(String.lstrip(view_path, ?/), "/", parts: 2)
    "#{db}/_design/#{design}/_view/#{view}"
  end
  defp make_path(db, %{list: list, view: view_path}) do
    [design, view] = String.split(String.lstrip(view_path, ?/), "/", parts: 2)
    "#{db}/_design/#{design}/_list/#{list}/#{view}"
  end
  defp make_path(db, %{show: show_path}) do
    [design, show] = String.split(String.lstrip(show_path, ?/), "/", parts: 2)
    "#{db}/_design/#{design}/_show/#{show}"
  end

  defp get_content(method, path, doc) do
    url = make_url <> path
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

  defp make_url do
    env = Application.get_all_env(:couchdb)
    auth = case Keyword.get(env, :user) do
      nil -> ""
      user -> "#{user}:#{Keyword.get(env, :pass)}@"
    end
    host = Keyword.get(env, :host, "localhost")
    port = Keyword.get(env, :port, 5984)
    "http://#{auth}#{host}:#{port}/"
  end
end
