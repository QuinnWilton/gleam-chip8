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
        running: false,
        instructions: [],
        stack_addresses: [],
        row0: [],
        row1: [],
        row2: [],
        row3: [],
        row4: [],
        row5: [],
        row6: [],
        row7: [],
        row8: [],
        row9: [],
        row10: [],
        row11: [],
        row12: [],
        row13: [],
        row14: [],
        row15: [],
        row16: [],
        row17: [],
        row18: [],
        row19: [],
        row20: [],
        row21: [],
        row22: [],
        row23: [],
        row24: [],
        row25: [],
        row26: [],
        row27: [],
        row28: [],
        row29: [],
        row30: [],
        row31: []
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
    rom = ROMs.get_rom(rom_name)
    emulator = Emulator.load_rom(socket.assigns.emulator, rom.data)

    socket =
      socket
      |> assign(:emulator, emulator)
      |> assign(:rom, rom)

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

    emulator =
      Enum.reduce(1..timers, socket.assigns.emulator, fn _, acc ->
        Emulator.handle_timers(acc)
      end)

    emulator =
      Enum.reduce(1..cycles, emulator, fn _, acc ->
        Emulator.step(acc)
      end)

    screen = :chip8@screen.to_list(emulator.screen)

    [
      row0,
      row1,
      row2,
      row3,
      row4,
      row5,
      row6,
      row7,
      row8,
      row9,
      row10,
      row11,
      row12,
      row13,
      row14,
      row15,
      row16,
      row17,
      row18,
      row19,
      row20,
      row21,
      row22,
      row23,
      row24,
      row25,
      row26,
      row27,
      row28,
      row29,
      row30,
      row31
    ] = Enum.chunk_every(screen, 64)

    socket =
      socket
      |> assign(:emulator, emulator)
      |> assign(:last_cycle, now)
      |> assign(:instructions, disassemble_instructions(emulator))
      |> assign(:stack_addresses, list_stack_addresses(emulator))
      |> assign(:row0, row0)
      |> assign(:row1, row1)
      |> assign(:row2, row2)
      |> assign(:row3, row3)
      |> assign(:row4, row4)
      |> assign(:row5, row5)
      |> assign(:row6, row6)
      |> assign(:row7, row7)
      |> assign(:row8, row8)
      |> assign(:row9, row9)
      |> assign(:row10, row10)
      |> assign(:row11, row11)
      |> assign(:row12, row12)
      |> assign(:row13, row13)
      |> assign(:row14, row14)
      |> assign(:row15, row15)
      |> assign(:row16, row16)
      |> assign(:row17, row17)
      |> assign(:row18, row18)
      |> assign(:row19, row19)
      |> assign(:row20, row20)
      |> assign(:row21, row21)
      |> assign(:row22, row22)
      |> assign(:row23, row23)
      |> assign(:row24, row24)
      |> assign(:row25, row25)
      |> assign(:row26, row26)
      |> assign(:row27, row27)
      |> assign(:row28, row28)
      |> assign(:row29, row29)
      |> assign(:row30, row30)
      |> assign(:row31, row31)

    {:noreply, socket}
  end

  defp schedule_next_cycle(socket) do
    if socket.assigns.running do
      Process.send_after(self(), :next_cycle, @milliseconds_per_frame)
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
