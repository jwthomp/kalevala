defmodule Kantele.Character.Events do
  @moduledoc false

  use Kalevala.Event.Router

  alias Kalevala.Event.ItemDrop
  alias Kalevala.Event.ItemPickUp
  alias Kalevala.Event.Message
  alias Kalevala.Event.Movement
  alias Kantele.Character.ChannelEvent
  alias Kantele.Character.EmoteEvent
  alias Kantele.Character.SayEvent

  scope(Kantele.Character) do
    module(CombatEvent) do
      event("combat/start", :start)
      event("combat/stop", :stop)
      event("combat/tick", :tick)
    end

    module(DelayedEvent) do
      event("commands/delayed", :run)
    end

    module(EmoteEvent) do
      event(Message, :echo, interested?: &EmoteEvent.interested?/1)
    end

    module(ItemEvent) do
      event(ItemDrop.Abort, :drop_abort)
      event(ItemDrop.Commit, :drop_commit)

      event(ItemPickUp.Abort, :pickup_abort)
      event(ItemPickUp.Commit, :pickup_commit)
    end

    module(MoveEvent) do
      event(Movement.Commit, :commit)
      event(Movement.Abort, :abort)
      event(Movement.Notice, :notice)
    end

    module(SayEvent) do
      event(Message, :echo, interested?: &SayEvent.interested?/1)
    end

    module(ChannelEvent) do
      event(Message, :echo, interested?: &ChannelEvent.interested?/1)
    end
  end
end

defmodule Kantele.Character.NonPlayerEvents do
  @moduledoc false

  use Kalevala.Event.Router

  alias Kalevala.Event.Movement

  scope(Kantele.Character) do
    module(FleeEvent) do
      event("room/flee", :run)
    end

    module(MoveEvent) do
      event(Movement.Commit, :commit)
      event(Movement.Abort, :abort)
      event(Movement.Notice, :notice)
    end

    module(WanderEvent) do
      event("room/wander", :run)
    end
  end
end
