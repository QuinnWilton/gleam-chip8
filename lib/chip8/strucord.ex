defmodule Chip8.Strucord do
  require Record

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    from = Keyword.fetch!(opts, :from)

    fields = Record.extract(name, from: from)
    struct_fields = Keyword.keys(fields)

    module = __CALLER__.module

    quote do
      defstruct unquote(struct_fields)

      def from_record(record) do
        fields =
          unquote(struct_fields)
          |> Enum.with_index(1)
          |> Enum.map(fn {field, index} ->
            {field, elem(record, index)}
          end)

        struct!(unquote(module), fields)
      end

      def to_record(%unquote(module){} = struct) do
        Enum.reduce(unquote(struct_fields), {unquote(name)}, fn field, record ->
          Tuple.append(record, Map.fetch!(struct, field))
        end)
      end
    end
  end
end
