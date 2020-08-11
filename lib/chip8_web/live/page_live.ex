defmodule Chip8Web.PageLive do
  use Chip8Web, :live_view

  require Chip8.Emulator

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, emulator: :chip8@emulator.init())}
  end

  def handle_event("reset", _value, socket) do
    :timer.cancel(socket.assigns.timer_ref)

    msg = :reset
    emulator = :chip8@emulator.update(socket.assigns.emulator, msg)

    {:noreply, assign(socket, :emulator, emulator)}
  end

  def handle_event("load_rom", _value, socket) do
    rom = File.read!(Application.app_dir(:chip8, "priv/roms/MAZE.ch8"))
    msg = {:load_rom, rom}
    emulator = :chip8@emulator.update(socket.assigns.emulator, msg)

    {:noreply, assign(socket, :emulator, emulator)}
  end

  def handle_event("step", _value, socket) do
    msg = :tick
    emulator = :chip8@emulator.update(socket.assigns.emulator, msg)

    {:noreply, assign(socket, :emulator, emulator)}
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
    msg = :tick
    emulator = :chip8@emulator.update(socket.assigns.emulator, msg)

    {:noreply, assign(socket, :emulator, emulator)}
  end
end
