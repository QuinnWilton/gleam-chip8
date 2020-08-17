defmodule Chip8.RegisterFile do
  use Chip8.Strucord,
    name: :register_file,
    from: "gen/src/chip8@registers_RegisterFile.hrl"

  alias __MODULE__

  def get_data_register(%RegisterFile{} = register_file, register) when is_atom(register) do
    Map.fetch!(register_file.data_registers, register)
  end
end
