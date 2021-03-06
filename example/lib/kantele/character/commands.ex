defmodule Kantele.Character.Commands do
  @moduledoc false

  use Kalevala.Character.Command.Router

  scope(Kantele.Character) do
    module(CombatCommand) do
      command("combat start", :start)
      command("combat stop", :stop)
      command("combat tick", :tick)
    end

    module(DelayedCommand) do
      command("delay :command", :run)
    end

    module(EmoteCommand) do
      command("emote :text", :broadcast)
      command("emotes", :list)
    end

    module(ItemCommand) do
      command("drop :item_name", :drop)
      command("get :item_name", :get)
    end

    module(LookCommand) do
      command("look", :run)
    end

    module(InventoryCommand) do
      command("i", :run)
      command("inv", :run)
      command("inventory", :run)
    end

    module(MoveCommand) do
      command("north", :north)
      command("south", :south)
      command("east", :east)
      command("west", :west)
      command("up", :up)
      command("down", :down)
    end

    module(QuitCommand) do
      command("quit", :run)
      command(<<4>>, :run, display: false)
    end

    module(SayCommand) do
      command("say :text", :run)
    end

    module(ChannelCommand) do
      command("general :text", :general)
    end

    module(InfoCommand) do
      command("info", :run)
    end

    module(ReloadCommand) do
      command("reload", :run)
    end

    module(WhoCommand) do
      command("who", :run)
    end

    dynamic(EmoteCommand, [])
  end
end
