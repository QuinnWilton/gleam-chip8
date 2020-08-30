defmodule Chip8Web.PageLive do
  use Chip8Web, :live_view

  alias Chip8.{
    Emulator,
    RegisterFile,
    ROMs,
    Stack
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
        roms: ROMs.list_roms(),
        rom: nil,
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
      |> push_event("disable_soundcard", %{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("load_rom", %{"name" => rom_name}, socket) do
    rom = ROMs.get_rom(rom_name)
    emulator = Emulator.load_rom(socket.assigns.emulator, rom.data)

    socket =
      socket
      |> assign(:emulator, emulator)
      |> assign(:rom, rom)
      |> push_event("initialize_soundcard", %{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("step", _value, socket) do
    {emulator, commands} = Emulator.step(socket.assigns.emulator)

    socket =
      socket
      |> assign(:emulator, emulator)
      |> handle_commands(commands)

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
    if socket.assigns.running do
      case ROMs.translate_keybinds(socket.assigns.rom, key) do
        nil ->
          {:noreply, socket}

        key ->
          emulator = Emulator.handle_key_up(socket.assigns.emulator, key)

          {:noreply, assign(socket, :emulator, emulator)}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("key_down", %{"key" => key}, socket) do
    if socket.assigns.running do
      case ROMs.translate_keybinds(socket.assigns.rom, key) do
        nil ->
          {:noreply, socket}

        key ->
          emulator = Emulator.handle_key_down(socket.assigns.emulator, key)

          {:noreply, assign(socket, :emulator, emulator)}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:next_cycle, socket) do
    schedule_next_cycle(socket)
    now = System.system_time(:millisecond)

    timers = trunc((now - socket.assigns.last_cycle) / @milliseconds_per_timer)
    cycles = trunc((now - socket.assigns.last_cycle) / @milliseconds_per_cycle)

    {emulator, commands} =
      Enum.reduce(1..timers, {socket.assigns.emulator, []}, fn _, {acc_emulator, acc_commands} ->
        {emulator, commands} = Emulator.handle_timers(acc_emulator)

        {emulator, acc_commands ++ commands}
      end)

    {emulator, commands} =
      Enum.reduce(1..cycles, {emulator, commands}, fn _, {acc_emulator, acc_commands} ->
        {emulator, commands} = Emulator.step(acc_emulator)

        {emulator, acc_commands ++ commands}
      end)

    socket =
      socket
      |> assign(:emulator, emulator)
      |> assign(:last_cycle, now)
      |> handle_commands(commands)

    {:noreply, socket}
  end

  defp schedule_next_cycle(socket) do
    if socket.assigns.running do
      Process.send_after(self(), :next_cycle, @milliseconds_per_frame)
    end
  end

  defp handle_commands(socket, commands) do
    Enum.reduce(commands, socket, fn command, socket ->
      case command do
        :sound_on -> push_event(socket, "enable_soundcard", %{})
        :sound_off -> push_event(socket, "disable_soundcard", %{})
      end
    end)
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
