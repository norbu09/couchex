defmodule Couchex.Client do
  
  require Logger

  def head(db, thing) do
    path = "#{db}/#{thing}"
    Logger.debug("Got HEAD request for: #{path}")
    talk(:head, path, nil, nil)
  end

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
    case talk(:get, path, nil, opts) do
      {:error, reason} -> {:error, reason}
      {:ok, res} ->
        # I am sure there is a more elegant version of this out there
        view_opts = Map.delete(view, :view)
        case Map.to_list(view_opts) do
          [{:long, true}] -> {:ok, res}
          [{:key_based, true}] -> 
            case opts["include_docs"] do
              nil ->
                {:ok, Enum.reduce(res["rows"], %{}, fn(x, acc) -> Map.put(acc, x["key"], x["value"]) end)}
              true ->
                {:ok, Enum.reduce(res["rows"], %{}, fn(x, acc) -> Map.put(acc, x["key"], x["doc"]) end)}
            end
          _ ->    {:ok, res["rows"]}
        end
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
      opts -> 
      # FIXME should also respect `startkey` and `endkey`
        opts1 = case Map.has_key?(opts, "key") do
          true -> %{opts | "key" => "\"#{opts["key"]}\""}
          false -> opts
        end
        path_plain <> "?" <> URI.encode_query(opts1)
    end

    case get_content(method, path, doc) do
      {:ok, code, _headers, body_ref} ->
        case method do
          :head -> {:ok, code}
          _ ->
            {:ok, res} = :hackney.body body_ref
            parse_response(res, code)
        end
      error -> error
    end
  end

  def all_dbs do
    Logger.debug("Got request for list of all DBs")
    talk(:get, "_all_dbs", nil, nil)
  end

  def create_db(db) when is_binary(db) do
    Logger.debug("Got request to create db: #{db}")
    path = "#{db}"
    talk(:put, path, nil, nil)
  end

  def delete_db(db) when is_binary(db) do
    Logger.debug("Got request to delete db: #{db}")
    path = "#{db}"
    talk(:delete, path, nil, nil)
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
    auth = case env_get(:user) do
      nil -> ""
      user -> "#{user}:#{env_get(:pass)}@"
    end
    host = env_get(:host)
    port = env_get(:port)
    "http://#{auth}#{host}:#{port}/"
  end


  defp env_get(:host) do
    env_get(:couchex, :host)
  end
  defp env_get(:port) do
    env_get(:couchex, :port)
  end
  defp env_get(:user) do
    env_get(:couchex, :user)
  end
  defp env_get(:pass) do
    env_get(:couchex, :pass)
  end
  defp env_get(config_key, :host) do
      System.get_env("COUCHDB_HOST") || Application.get_env(config_key, :host) || "localhost"
  end
  defp env_get(config_key, :port) do
      System.get_env("COUCHDB_PORT") || Application.get_env(config_key, :port) || 5984
  end
  defp env_get(config_key, :user) do
      System.get_env("COUCHDB_USER") || Application.get_env(config_key, :user) || nil
  end
  defp env_get(config_key, :pass) do
      System.get_env("COUCHDB_PASS") || Application.get_env(config_key, :pass) || nil
  end


end
