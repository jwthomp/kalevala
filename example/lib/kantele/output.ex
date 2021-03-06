defmodule Kantele.Output.Macros do
  @moduledoc """
  Helper macros for defining semantic colors
  """

  @doc """
  Define a semantic color

  Available options:
  - foreground
  - background
  - underline
  """
  defmacro color(tag_name, options) do
    options =
      options
      |> Enum.map(fn {key, value} ->
        {to_string(key), to_string(value)}
      end)
      |> Enum.into(%{})

    quote do
      def parse({:open, unquote(tag_name), attributes}, context) do
        attributes = Map.merge(attributes, unquote(Macro.escape(options)))
        Map.put(context, :data, context.data ++ [{:open, "color", attributes}])
      end

      def parse({:close, unquote(tag_name)}, context) do
        Map.put(context, :data, context.data ++ [{:close, "color"}])
      end
    end
  end

  @doc """
  Display metadata attributes on tags
  """
  defmacro metadata(tag_name, color, block) do
    quote do
      def parse({:open, unquote(tag_name), attributes}, context) do
        tag_stack = [{:open, unquote(tag_name), attributes} | context.meta.tag_stack]
        meta = Map.put(context.meta, :tag_stack, tag_stack)

        context
        |> Map.put(:data, context.data ++ [{:open, unquote(tag_name), attributes}])
        |> Map.put(:meta, meta)
      end

      def parse({:close, unquote(tag_name)}, context) do
        [{:open, unquote(tag_name), attributes} | tag_stack] = context.meta.tag_stack
        meta = Map.put(context.meta, :tag_stack, tag_stack)

        tags = [
          {:close, unquote(tag_name)},
          {:open, "color", %{"foreground" => unquote(Macro.escape(color))}},
          unquote(block).(attributes),
          {:close, "color"}
        ]

        context
        |> Map.put(:data, context.data ++ tags)
        |> Map.put(:meta, meta)
      end
    end
  end
end

defmodule Kantele.Output.SemanticColors do
  @moduledoc """
  Transform semantic tags into color tags
  """

  use Kalevala.Output

  import Kantele.Output.Macros, only: [color: 2]

  color("character", foreground: "yellow")
  color("item", foreground: "cyan")
  color("text", foreground: "green")
  color("room-title", foreground: "blue", underline: true)
  color("hp", foreground: "red")
  color("sp", foreground: "blue")
  color("ep", foreground: "169,114,218")

  @impl true
  def parse(datum, context) do
    Map.put(context, :data, context.data ++ [datum])
  end
end

defmodule Kantele.Output.AdminTags do
  @moduledoc """
  Parse admin specific tags

  Display things like item instance ids when present
  """

  use Kalevala.Output

  import Kalevala.Character.View.Macro, only: [sigil_i: 2]
  import Kantele.Output.Macros, only: [metadata: 3]

  @impl true
  def init(opts) do
    %Context{
      data: [],
      opts: opts,
      meta: %{
        tag_stack: []
      }
    }
  end

  metadata("character", "95,95,95", fn attributes ->
    ~i(##{attributes["id"]})
  end)

  metadata("item-instance", "95,95,95", fn attributes ->
    ~i(##{attributes["id"]})
  end)

  metadata("room-title", "95,95,95", fn attributes ->
    ~i( #{attributes["id"]})
  end)

  @impl true
  def parse(datum, context) do
    Map.put(context, :data, context.data ++ [datum])
  end
end
