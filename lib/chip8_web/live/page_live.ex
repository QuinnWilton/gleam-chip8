defmodule Chip8Web.PageLive do
  use Chip8Web, :live_view

  @impl true
  def mount(_params, _session, socket) do
    emulator = Chip8.Emulator.init()
    socket = assign(socket, emulator: emulator, timer_ref: nil)

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
    socket = assign(socket, :timer_ref, timer_ref)

    {:noreply, socket}
  end

  @impl true
  def handle_event("pause", _value, socket) do
    :timer.cancel(socket.assigns.timer_ref)
    socket = assign(socket, :timer_ref, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    emulator = Chip8.Emulator.step(socket.assigns.emulator)
    socket = assign(socket, :emulator, emulator)

    {:noreply, socket}
  end

  defp controls(%Chip8.Emulator{state: state}, timer_ref) do
    case {state, timer_ref} do
      {:awaiting_rom, _} ->
        [
          {"Load ROM", "load_rom", "button ghost primary"}
        ]
      {state, nil} when state in [:running, :awaiting_input] ->
        [
          {"Run", "run", "button ghost primary"},
          {"Step", "step", "button ghost secondary"},
          {"Reset", "reset", "button ghost secondary"}
        ]
      {state, ref} when not is_nil(ref) and state in [:running, :awaiting_input] ->
        [
          {"Pause", "pause", "button ghost primary"},
          {"Reset", "reset", "button ghost secondary"}
        ]
    end
  end
end
