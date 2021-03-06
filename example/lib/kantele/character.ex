defmodule Kantele.Character do
  @moduledoc """
  Character callbacks for Kalevala
  """

  @behaviour Kalevala.Character

  @impl true
  def trim_meta(meta) do
    Map.take(meta, [:vitals])
  end
end

defmodule Kantele.Character.PlayerMeta do
  @moduledoc """
  Specific metadata for a character in Kantele
  """

  defstruct [:vitals]
end

defmodule Kantele.Character.NonPlayerMeta do
  @moduledoc """
  Specific metadata for a world character in Kantele
  """

  defstruct [:brain, :initial_events, :vitals, :zone_id]
end

defmodule Kantele.Character.Vitals do
  @moduledoc """
  Character vital information
  """

  @derive Jason.Encoder
  defstruct [
    :health_points,
    :max_health_points,
    :skill_points,
    :max_skill_points,
    :endurance_points,
    :max_endurance_points
  ]
end

defmodule Kantele.Character.InitialEvent do
  @moduledoc """
  Initial events to kick off when a character starts
  """

  defstruct [:data, :delay, :topic]
end
