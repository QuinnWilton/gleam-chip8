defmodule Chip8.Strucord do
  require Record

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    from = Keyword.fetch!(opts, :from)

    fields = Record.extract(name, from: from)
    struct_fields = Keyword.keys(fields)
    vars = Macro.generate_arguments(length(struct_fields), __MODULE__)
    kvs = Enum.zip(struct_fields, vars)

    quote do
      defstruct unquote(struct_fields)

      def from_record({unquote(name), unquote_splicing(vars)}) do
        %__MODULE__{unquote_splicing(kvs)}
      end

      def to_record(%__MODULE__{unquote_splicing(kvs)}) do
        {unquote(name), unquote_splicing(vars)}
      end

      def with_record(%__MODULE__{} = struct, f) when is_function(f, 1) do
        struct
        |> to_record()
        |> f.()
        |> from_record()
      end
    end
  end
end
