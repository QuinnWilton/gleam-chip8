defmodule Chip8Web.PageLive do
  use Chip8Web, :live_view

  @fps 60

  @impl true
  def mount(_params, _session, socket) do
    emulator = Chip8.Emulator.init()

    socket =
      assign(socket,
        emulator: emulator,
        roms: Chip8.ROMs.list_roms(),
        fps: @fps,
        running: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("reset", _value, socket) do
    emulator = Chip8.Emulator.reset(socket.assigns.emulator)
    socket =
      socket
      |> assign(:emulator, emulator)
      |> assign(:running, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("load_rom", %{"name" => rom_name}, socket) do
    {^rom_name, rom} = List.keyfind(socket.assigns.roms, rom_name, 0)
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
    socket = assign(socket, :running, true)

    schedule_next_frame(socket)

    {:noreply, socket}
  end

  @impl true
  def handle_event("pause", _value, socket) do
    socket = assign(socket, :running, false)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:next_frame, socket) do
    schedule_next_frame(socket)

    emulator = Chip8.Emulator.step(socket.assigns.emulator)
    socket = assign(socket, :emulator, emulator)

    {:noreply, socket}
  end

  defp schedule_next_frame(socket) do
    if socket.assigns.running do
      Process.send_after(self(), :next_frame, trunc(1000 / socket.assigns.fps))
    end
  end

  defp controls(%Chip8.Emulator{state: state}, running) do
    case {state, running} do
      {:awaiting_rom, _} ->
        []

      {state, false} when state in [:running, :awaiting_input] ->
        [
          {"Run", "run", "button ghost primary"},
          {"Step", "step", "button ghost secondary"},
          {"Reset", "reset", "button ghost secondary"}
        ]

      {state, true} when state in [:running, :awaiting_input] ->
        [
          {"Pause", "pause", "button ghost primary"},
          {"Reset", "reset", "button ghost secondary"}
        ]
    end
  end
end
