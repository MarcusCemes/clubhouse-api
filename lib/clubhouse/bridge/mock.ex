defmodule Clubhouse.Bridge.Mock do
  @moduledoc """
  An in-memory implementation of the bridge that authenticates
  a fake user without any network calls.
  """

  def create_request(_return_url) do
    setup()

    token = Nanoid.generate()
    :ets.insert(:bridge_mock, {token})
    {:ok, token}
  end

  def fetch_attributes(key, _auth_check) do
    setup()

    case :ets.take(:bridge_mock, key) do
      [{^key}] ->
        {:ok,
         %{
           "email" => "fake.person@epfl.ch",
           "authstrength" => "1",
           "name" => "Person",
           "user" => "person",
           "uniqueid" => "000000",
           "username" => "person",
           "group" => "MT-Etudiants,etudiants-epfl",
           "statut" => "Etudiant",
           "unit" => "MT-BA6,Section de Microtechnique - Bachelor semestre 6",
           "firstname" => "Fake"
         }}

      [] ->
        {:error, :bad_key}
    end
  end

  defp setup() do
    if :ets.whereis(:bridge_mock) == :undefined do
      :ets.new(:bridge_mock, [:set, :public, :named_table])
    end
  end
end
