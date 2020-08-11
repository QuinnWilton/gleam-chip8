defmodule Chip8.Emulator do
  require Record

  Record.defrecord(
    :emulator,
    Record.extract(
      :emulator,
      from: "gen/src/chip8@emulator_Emulator.hrl"
    )
  )
end
