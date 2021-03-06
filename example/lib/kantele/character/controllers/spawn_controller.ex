defmodule Kantele.Character.SpawnController do
  use Kalevala.Character.Controller

  alias Kalevala.Character.Brain.Node
  alias Kantele.Character.MoveEvent
  alias Kantele.Character.NonPlayerEvents
  alias Kantele.Character.SpawnView

  @impl true
  def init(conn) do
    character = conn.character

    conn =
      Enum.reduce(character.meta.initial_events, conn, fn initial_event, conn ->
        delay_event(conn, initial_event.delay, initial_event.topic, initial_event.data)
      end)

    conn
    |> move(:to, character.room_id, SpawnView, "spawn", %{})
    |> subscribe("rooms:#{character.room_id}", [], &MoveEvent.subscribe_error/2)
    |> event("room/look", %{})
  end

  @impl true
  def event(conn, event) do
    conn.character.meta.brain
    |> Node.run(conn, event)
    |> NonPlayerEvents.call(event)
  end

  @impl true
  def recv(conn, _text), do: conn

  @impl true
  def display(conn, _text), do: conn
end
