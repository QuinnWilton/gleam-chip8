defmodule Chip8Web.PageLive do
  use Chip8Web, :live_view

  require Chip8.Emulator

  @impl true
  def mount(_params, _session, socket) do
    emulator =
      :chip8@emulator.init()
      |> Chip8.Emulator.from_record()

    socket = assign(socket, emulator: emulator)

    {:ok, socket}
  end

  def handle_event("reset", _value, socket) do
    :timer.cancel(socket.assigns.timer_ref)

    emulator =
      socket.assigns.emulator
      |> Chip8.Emulator.to_record()
      |> :chip8@emulator.update(:reset)
      |> Chip8.Emulator.from_record()

    socket = assign(socket, :emulator, emulator)

    {:noreply, socket}
  end

  def handle_event("load_rom", _value, socket) do
    rom = File.read!(Application.app_dir(:chip8, "priv/roms/MAZE.ch8"))

    emulator =
      socket.assigns.emulator
      |> Chip8.Emulator.to_record()
      |> :chip8@emulator.update({:load_rom, rom})
      |> Chip8.Emulator.from_record()

    socket = assign(socket, :emulator, emulator)

    {:noreply, socket}
  end

  def handle_event("step", _value, socket) do
    emulator =
      socket.assigns.emulator
      |> Chip8.Emulator.to_record()
      |> :chip8@emulator.update(:tick)
      |> Chip8.Emulator.from_record()

    socket = assign(socket, :emulator, emulator)

    {:noreply, socket}
  end

  def handle_event("run", _value, socket) do
    {:ok, timer_ref} = :timer.send_interval(16, self(), :tick)

    {:noreply, assign(socket, :timer_ref, timer_ref)}
  end

  def handle_event("pause", _value, socket) do
    :timer.cancel(socket.assigns.timer_ref)

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    emulator =
      socket.assigns.emulator
      |> Chip8.Emulator.to_record()
      |> :chip8@emulator.update(:tick)
      |> Chip8.Emulator.from_record()

    socket = assign(socket, :emulator, emulator)

    {:noreply, socket}
  end
end
