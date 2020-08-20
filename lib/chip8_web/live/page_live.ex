defmodule Chip8Web.PageLive do
  use Chip8Web, :live_view

  alias Chip8.{
    Emulator,
    RegisterFile,
    Stack,
  }

  @milliseconds_per_frame 16
  @milliseconds_per_timer 16
  @milliseconds_per_cycle 1

  @impl true
  def mount(_params, _session, socket) do
    emulator = Emulator.init()

    socket =
      assign(socket,
        emulator: emulator,
        roms: Chip8.ROMs.list_roms(),
        last_cycle: nil,
        running: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("reset", _value, socket) do
    emulator = Emulator.reset(socket.assigns.emulator)

    socket =
      socket
      |> assign(:emulator, emulator)
      |> assign(:running, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("load_rom", %{"name" => rom_name}, socket) do
    rom = Chip8.ROMs.get_rom(rom_name)
    emulator = Emulator.load_rom(socket.assigns.emulator, rom)
    socket = assign(socket, :emulator, emulator)

    {:noreply, socket}
  end

  @impl true
  def handle_event("step", _value, socket) do
    emulator = Emulator.step(socket.assigns.emulator)
    socket = assign(socket, :emulator, emulator)

    {:noreply, socket}
  end

  @impl true
  def handle_event("run", _value, socket) do
    socket =
      socket
      |> assign(:running, true)
      |> assign(:last_cycle, System.system_time(:millisecond))

    schedule_next_cycle(socket)

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
        emulator = Emulator.handle_key_up(socket.assigns.emulator, key)

        {:noreply, assign(socket, :emulator, emulator)}

      :error ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("key_down", %{"key" => key}, socket) do
    case decode_key(key) do
      {:ok, key} ->
        emulator = Emulator.handle_key_down(socket.assigns.emulator, key)

        {:noreply, assign(socket, :emulator, emulator)}

      :error ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:next_cycle, socket) do
    schedule_next_cycle(socket)
    now = System.system_time(:millisecond)

    timers = trunc((now - socket.assigns.last_cycle) / @milliseconds_per_timer)
    cycles = trunc((now - socket.assigns.last_cycle) / @milliseconds_per_cycle)

    emulator = Enum.reduce(1..timers, socket.assigns.emulator, fn _, acc ->
      Emulator.handle_timers(acc)
    end)

    emulator = Enum.reduce(1..cycles, emulator, fn _, acc ->
      Emulator.step(acc)
    end)

    socket =
      socket
      |> assign(:emulator, emulator)
      |> assign(:last_cycle, now)

    {:noreply, socket}
  end

  defp schedule_next_cycle(socket) do
    if socket.assigns.running do
      Process.send_after(self(), :next_cycle, @milliseconds_per_frame)
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

  defp disassemble_instructions(%Emulator{} = emulator) do
    Emulator.disassemble_instructions(emulator, 30)
  end

  defp get_register(%Emulator{} = emulator, register) when is_atom(register) do
    emulator
    |> Emulator.registers()
    |> Map.fetch!(register)
    |> to_hex_string()
  end

  defp get_data_register(%Emulator{} = emulator, register) when is_atom(register) do
    emulator
    |> Emulator.registers()
    |> RegisterFile.get_data_register(register)
    |> to_hex_string()
  end

  defp list_stack_addresses(%Emulator{} = emulator) do
    stack = Emulator.stack(emulator)

    stack
    |> Stack.list_stack_addresses()
    |> Enum.map(fn {address, value} ->
      {to_hex_string(address), to_hex_string(value), address == stack.sp}
    end)
  end

  defp to_hex_string(n) when is_integer(n) do
    "0x" <> Integer.to_string(n, 16)
  end

  defp controls(%Emulator{state: state}, running) do
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
