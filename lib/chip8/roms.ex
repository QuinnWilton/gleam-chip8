defmodule Chip8.ROMs do
  roms_paths = "priv/roms/*" |> Path.wildcard() |> Enum.sort()

  roms =
    for rom_path <- roms_paths do
      @external_resource Path.relative_to_cwd(rom_path)
      {Path.basename(rom_path), File.read!(rom_path)}
    end

  @roms Enum.sort_by(roms, fn {name, _contents} -> name end)

  def list_roms do
    @roms
  end

  def get_rom(name) when is_binary(name) do
    roms = list_roms()
    {^name, rom} = List.keyfind(roms, name, 0)

    rom
  end
end
