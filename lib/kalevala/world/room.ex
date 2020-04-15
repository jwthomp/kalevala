defmodule Kalevala.World.Room.Context do
  @moduledoc """
  Context for performing work for an event in a room
  """

  @type t() :: %__MODULE__{}

  defstruct [:data, assigns: %{}, characters: [], events: [], lines: []]

  defp push(context, to_pid, event = %Kalevala.Character.Conn.Event{}, _newline) do
    Map.put(context, :lines, context.lines ++ [{to_pid, event}])
  end

  defp push(context, to_pid, data, newline) do
    lines = %Kalevala.Character.Conn.Lines{
      data: data,
      newline: newline
    }

    Map.put(context, :lines, context.lines ++ [{to_pid, lines}])
  end

  @doc """
  Render text back to a pid
  """
  def render(context, to_pid, view, template, assigns) do
    assigns = Map.merge(context.assigns, assigns)
    data = view.render(template, assigns)
    push(context, to_pid, data, false)
  end

  @doc """
  Render a prompt back to a pid
  """
  def prompt(context, to_pid, view, template, assigns) do
    assigns = Map.merge(context.assigns, assigns)
    data = view.render(template, assigns)
    push(context, to_pid, data, true)
  end

  @doc """
  Add to the assignment map on the context
  """
  def assign(context, key, value) do
    assigns = Map.put(context.assigns, key, value)
    Map.put(context, :assigns, assigns)
  end

  @doc """
  Send an event back to a pid
  """
  def event(context, to_pid, from_pid, topic, data) do
    event = %Kalevala.Event{
      from_pid: from_pid,
      topic: topic,
      data: data
    }

    Map.put(context, :events, context.events ++ [{to_pid, event}])
  end
end

defmodule Kalevala.World.Room.Movement do
  @moduledoc """
  Handle room movement
  """

  alias Kalevala.Event
  alias Kalevala.Event.Display
  alias Kalevala.Event.Movement
  alias Kalevala.Event.Movement.Voting
  alias Kalevala.World.Zone

  @doc """
  Handle the movement request

  Called after `Kalevala.World.Room.movement_request/2`.

  - If an abort, forward to the character
  - Otherwise, Forward to the zone
  """
  def handle_request({:abort, event, reason}, state, metadata) do
    %{character: character} = event.data

    event = %Event{
      topic: Voting,
      metadata: metadata,
      data: %Voting{
        aborted: true,
        character: character,
        from: state.data.id,
        exit_name: event.data.exit_name,
        reason: reason
      }
    }

    send(character.pid, Voting.abort(event))
  end

  def handle_request({:proceed, event, room_exit}, state, metadata) do
    %{character: character} = event.data

    event = %Event{
      topic: Voting,
      metadata: metadata,
      data: %Voting{
        character: character,
        from: state.data.id,
        to: room_exit.end_room_id,
        exit_name: room_exit.exit_name
      }
    }

    Zone.global_name(state.data.zone_id)
    |> GenServer.whereis()
    |> send(event)
  end

  @doc """
  Handle the movement event
  """
  def handle_event(state, event = %Event{topic: Movement, data: %{direction: :to}}) do
    state
    |> broadcast(event)
    |> append_character(event)
  end

  def handle_event(state, event = %Event{topic: Movement, data: %{direction: :from}}) do
    state
    |> reject_character(event)
    |> broadcast(event)
  end

  @doc """
  Broadcast the event to characters in the room
  """
  def broadcast(state, event) do
    lines = %Kalevala.Character.Conn.Lines{data: event.data.reason, newline: true}
    display_event = %Display{lines: [lines]}

    Enum.each(state.private.characters, fn character ->
      send(character.pid, display_event)
    end)

    state
  end

  defp append_character(state, event) do
    characters = [event.data.character | state.private.characters]
    private = Map.put(state.private, :characters, characters)

    Map.put(state, :private, private)
  end

  defp reject_character(state, event) do
    characters =
      Enum.reject(state.private.characters, fn character ->
        character.id == event.data.character.id
      end)

    private = Map.put(state.private, :characters, characters)
    Map.put(state, :private, private)
  end
end

defmodule Kalevala.World.Room.Private do
  @moduledoc """
  Store private information for a room, e.g. characters in the room
  """

  defstruct characters: []
end

defmodule Kalevala.World.Room.Feature do
  @moduledoc """
  A room feature is a highlighted part of a room
  """

  defstruct [:id, :keyword, :short_description, :description]
end

defmodule Kalevala.World.Room do
  @moduledoc """
  Rooms are the base unit of space in Kalevala
  """

  use GenServer

  require Logger

  alias Kalevala.Event
  alias Kalevala.Event.Message
  alias Kalevala.World.Room.Context
  alias Kalevala.World.Room.Exit
  alias Kalevala.World.Room.Movement
  alias Kalevala.World.Room.Private

  defstruct [
    :id,
    :zone_id,
    :name,
    :description,
    exits: [],
    features: []
  ]

  @type t() :: %__MODULE__{}

  @doc """
  Called when the room is initializing
  """
  @callback init(room :: t()) :: t()

  @doc """
  Called after the room process is started

  Directly after `init` is completed.
  """
  @callback initialized(room :: t()) :: :ok

  @doc """
  Callback for when a new event is received
  """
  @callback event(Context.t(), event :: Event.t()) :: Context.t()

  @doc """
  Callback for the room to hook into movement between exits

  The character is requesting to move via an exit, a tuple allowing or rejecting
  the movement before being pitched up to the Zone should be returned.

  Can immediately terminate a room before being checked in a more detailed fashion
  with `confirm_movement/2` below.
  """
  @callback movement_request(t(), event :: Event.movement_request(), room_exit :: Exit.t() | nil) ::
              {:abort, event :: Event.t(), reason :: atom()}
              | {:proceed, event :: Event.t(), room_exit :: Exit.t()}

  @doc """
  Callback for confirming or aborting character movement

  Called while the Zone is checking each side of the exit to know if the movement
  is indeed allowed. Returning the original event allows movement to proceed, otherwise
  return an aborted event to prevent movement.

  Hook to allow for the room to reject movement for custom reasons, e.g. an NPC
  is blocking the exit and needs to be convinced first, or there is a trap blocking
  the exit.
  """
  @callback confirm_movement(Context.t(), event :: Event.movement_voting()) ::
              {Context.t(), Event.movement_voting()}

  defmacro __using__(_opts) do
    quote do
      import Kalevala.World.Room.Context

      @behaviour Kalevala.World.Room

      @impl true
      def init(room), do: room

      @impl true
      def movement_request(_room, event, nil), do: {:abort, event, :no_exit}

      def movement_request(_room, event, room_exit), do: {:proceed, event, room_exit}

      @impl true
      def confirm_movement(context, event), do: {context, event}

      defoverridable confirm_movement: 2, init: 1, movement_request: 3
    end
  end

  @doc """
  Confirm movement for a character
  """
  def confirm_movement(event = %Event{topic: Voting, data: %{aborted: true}}, _room_id) do
    event
  end

  def confirm_movement(event, room_id) do
    GenServer.call(global_name(room_id), event)
  end

  @doc false
  def global_name(room = %__MODULE__{}), do: global_name(room.id)

  def global_name(room_id), do: {:global, {__MODULE__, room_id}}

  @doc false
  def start_link(options) do
    genserver_options = options.genserver_options
    options = Map.delete(options, :genserver_options)

    GenServer.start_link(__MODULE__, options, genserver_options)
  end

  @impl true
  def init(options) do
    Logger.info("Room starting - #{options.room.id}")

    config = options.config
    room = config.callback_module.init(options.room)

    state = %{
      data: room,
      supervisor_name: config.supervisor_name,
      callback_module: config.callback_module,
      private: %Private{}
    }

    {:ok, state, {:continue, :initialized}}
  end

  @impl true
  def handle_continue(:initialized, state) do
    state.callback_module.initialized(state.data)
    {:noreply, state}
  end

  @impl true
  def handle_call(event = %Event{topic: Event.Movement.Voting}, _from, state) do
    {context, event} =
      state
      |> new_context()
      |> state.callback_module.confirm_movement(event)

    context
    |> send_lines()
    |> send_events()

    state = Map.put(state, :data, context.data)

    {:reply, event, state}
  end

  @impl true
  # Forward movement requests to the zone to handle
  def handle_info(event = %Event{topic: Event.Movement.Request}, state) do
    room_exit =
      Enum.find(state.data.exits, fn exit ->
        exit.exit_name == event.data.exit_name
      end)

    state.data
    |> state.callback_module.movement_request(event, room_exit)
    |> Movement.handle_request(state, event.metadata)

    {:noreply, state}
  end

  def handle_info(event = %Event{topic: Event.Movement}, state) do
    case event.data.room_id == state.data.id do
      true ->
        state = Movement.handle_event(state, event)
        {:noreply, state}

      false ->
        global_name(event.data.room_id)
        |> GenServer.whereis()
        |> send(event)

        {:noreply, state}
    end
  end

  def handle_info(event = %Event{}, state) do
    context =
      new_context(state)
      |> state.callback_module.event(event)
      |> handle_context()

    state = Map.put(state, :data, context.data)

    {:noreply, state}
  end

  def handle_info(message = %Message{}, state) do
    context =
      new_context(state)
      |> state.callback_module.event(message)
      |> handle_context()

    state = Map.put(state, :data, context.data)

    {:noreply, state}
  end

  defp new_context(state) do
    %Context{data: state.data, characters: state.private.characters}
  end

  defp handle_context(context) do
    context
    |> send_lines()
    |> send_events()
  end

  defp send_lines(context) do
    context.lines
    |> Enum.group_by(
      fn {to_pid, _line} ->
        to_pid
      end,
      fn {_to_pid, line} ->
        line
      end
    )
    |> Enum.each(fn {to_pid, lines} ->
      send(to_pid, %Event.Display{lines: lines})
    end)

    context
  end

  defp send_events(context) do
    Enum.each(context.events, fn {to_pid, event} ->
      send(to_pid, event)
    end)

    context
  end
end
