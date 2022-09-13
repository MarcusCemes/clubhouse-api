defmodule Clubhouse.Bridge.Mock do
  @moduledoc """
  An in-memory implementation of the bridge that authenticates
  a fake user without any network calls. Stores generated keys
  in ETS and returns signs-in a fake user.
  """

  import Clubhouse.Utility, only: [append_query_string: 2]

  @table :dev_helper

  def create_request(return_url) do
    token = Nanoid.generate()
    :ets.insert(@table, {token})
    {:ok, append_query_string(return_url, "key=#{token}&auth_check=1")}
  end

  def fetch_attributes(key, _auth_check) do
    case :ets.take(@table, key) do
      [{^key}] ->
        :ets.insert(@table, {key})

        {:ok, generate_attributes()}

      [] ->
        {:error, :bad_key}
    end
  end

  def generate_attributes(attrs \\ %{}) do
    Map.merge(
      %{
        "email" => "test.user@epfl.ch",
        "authstrength" => "1",
        "name" => "User",
        "user" => "user",
        "uniqueid" => "000000",
        "username" => "user",
        "group" => "MT-Etudiants,etudiants-epfl",
        "statut" => "Etudiant",
        "unit" => "MT-BA6,Section de Microtechnique - Bachelor semestre 6",
        "firstname" => "Test",
        "where" => "MT-BA6/MT-S/ETU/EPFL/CH"
      },
      attrs
    )
  end
end
