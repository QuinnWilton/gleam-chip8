defmodule Chip8.Emulator do
  use Chip8.Strucord,
    name: :emulator,
    from: "gen/src/chip8@emulator_Emulator.hrl"

  alias __MODULE__

  def init() do
    :chip8@emulator.init()
    |> from_record()
  end

  def load_rom(%Emulator{} = emulator, rom) when is_binary(rom) do
    emulator
    |> to_record()
    |> :chip8@emulator.update({:load_rom, rom})
    |> from_record()
  end

  def step(%Emulator{} = emulator) do
    emulator
    |> to_record()
    |> :chip8@emulator.update(:tick)
    |> from_record()
  end
end
