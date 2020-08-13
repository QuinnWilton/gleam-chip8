defmodule Chip8Web.PageLive do
  use Chip8Web, :live_view

  require Chip8.Emulator

  @impl true
  def mount(_params, _session, socket) do
    emulator = Chip8.Emulator.init()
    socket = assign(socket, emulator: emulator)

    {:ok, socket}
  end

  @impl true
  def handle_event("reset", _value, socket) do
    :timer.cancel(socket.assigns.timer_ref)

    emulator = Chip8.Emulator.reset(socket.assigns.emulator)
    socket = assign(socket, :emulator, emulator)

    {:noreply, socket}
  end

  @impl true
  def handle_event("load_rom", _value, socket) do
    rom = File.read!(Application.app_dir(:chip8, "priv/roms/MAZE.ch8"))
    emulator = Chip8.Emulator.load_rom(socket.assigns.emulator, rom)
    socket = assign(socket, :emulator, emulator)

    {:noreply, socket}
  end

  @impl true
  def handle_event("step", _value, socket) do
    emulator = Chip8.Emulator.step(socket.assigns.emulator)
    socket = assign(socket, :emulator, emulator)

    {:noreply, socket}
  end

  @impl true
  def handle_event("run", _value, socket) do
    {:ok, timer_ref} = :timer.send_interval(16, self(), :tick)

    {:noreply, assign(socket, :timer_ref, timer_ref)}
  end

  @impl true
  def handle_event("pause", _value, socket) do
    :timer.cancel(socket.assigns.timer_ref)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    emulator = Chip8.Emulator.step(socket.assigns.emulator)
    socket = assign(socket, :emulator, emulator)

    {:noreply, socket}
  end
end
