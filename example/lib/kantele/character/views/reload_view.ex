defmodule Kantele.Character.ReloadView do
  use Kalevala.Character.View

  def render("reloaded", _assigns) do
    "Game world data reloaded!\n"
  end
end
