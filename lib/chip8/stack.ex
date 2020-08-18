defmodule Chip8.Stack do
  use Chip8.Strucord,
    name: :stack,
    from: "gen/src/chip8@stack_Stack.hrl"

  alias __MODULE__

  def list_stack_addresses(%Stack{} = stack) do
    record = to_record(stack)

    :chip8@stack.to_list(record)
  end
end
