defmodule Clubhouse.Scheduler do
  @moduledoc """
  Supervised process that periodically executes tasks.
  """

  use Quantum, otp_app: :clubhouse
end
