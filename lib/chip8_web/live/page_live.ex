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
  def handle_event("key_up", %{"key" => key}, socket) do
    case decode_key(key) do
      {:ok, key} ->
        emulator = Chip8.Emulator.handle_key_up(socket.assigns.emulator, key)

        {:noreply, assign(socket, :emulator, emulator)}

      :error ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("key_down", %{"key" => key}, socket) do
    case decode_key(key) do
      {:ok, key} ->
        emulator = Chip8.Emulator.handle_key_down(socket.assigns.emulator, key)

        {:noreply, assign(socket, :emulator, emulator)}

      :error ->
        {:noreply, socket}
    end
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

  defp decode_key(key) do
    case key do
      "1" -> {:ok, :k0}
      "x" -> {:ok, :k1}
      "2" -> {:ok, :k2}
      "3" -> {:ok, :k3}
      "q" -> {:ok, :k4}
      "w" -> {:ok, :k5}
      "e" -> {:ok, :k6}
      "a" -> {:ok, :k7}
      "s" -> {:ok, :k8}
      "d" -> {:ok, :k9}
      "z" -> {:ok, :ka}
      "c" -> {:ok, :kb}
      "4" -> {:ok, :kc}
      "r" -> {:ok, :kd}
      "f" -> {:ok, :ke}
      "v" -> {:ok, :kf}
      _ -> :error
    end
  end

  defp disassemble_instructions(%Chip8.Emulator{} = emulator) do
    Chip8.Emulator.disassemble_instructions(emulator, 30)
  end

  defp controls(%Chip8.Emulator{state: state}, running) do
    case {state, running} do
      {:awaiting_rom, _} ->
        []

      {_, false} ->
        [
          {"Run", "run", "button ghost primary"},
          {"Step", "step", "button ghost secondary"},
          {"Reset", "reset", "button ghost secondary"}
        ]

      {_, true} ->
        [
          {"Pause", "pause", "button ghost primary"},
          {"Reset", "reset", "button ghost secondary"}
        ]
    end
  end
end
