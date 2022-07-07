defmodule Clubhouse.DevHelper do
  @moduledoc """
  A GenServer that is started as part of the application
  supervision tree during development and testing.

  The started process owns the :dev_helper ETS table that
  modules can write global state to, such as the bridge
  mock that generates random keys instead of communicating
  with the real Tequila service.
  """

  use GenServer

  @table :dev_helper

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    if Application.get_env(:clubhouse, :env) in [:dev, :test] do
      :ets.new(@table, [:set, :public, :named_table])
    end

    {:ok, nil}
  end
end
