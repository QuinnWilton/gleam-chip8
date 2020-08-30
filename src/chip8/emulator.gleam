import gleam/bitwise
import gleam/int
import gleam/list
import gleam/string
import chip8/helpers
import chip8/instruction
import chip8/keyboard
import chip8/memory
import chip8/registers
import chip8/screen
import chip8/sprite
import chip8/stack

const font = <<
  240, 144, 144, 144, 240, 32, 96, 32, 32, 112, 240, 16, 240, 128, 240, 240, 16,
  240, 16, 240, 144, 144, 240, 16, 16, 240, 128, 240, 16, 240, 240, 128, 240, 144,
  240, 240, 16, 32, 64, 64, 240, 144, 240, 144, 240, 240, 144, 240, 16, 240, 240,
  144, 240, 144, 144, 224, 144, 224, 144, 224, 240, 128, 128, 128, 240, 224, 144,
  144, 144, 224, 240, 128, 240, 128, 240, 240, 128, 240, 128, 128,
>>

pub type State {
  Running
  AwaitingROM
  AwaitingInput(vx: registers.DataRegister)
}

pub type ROM =
  BitString

pub type Emulator {
  Emulator(
    state: State,
    registers: registers.RegisterFile,
    keyboard: keyboard.Keyboard,
    pc: Int,
    stack: stack.Stack,
    memory: memory.Memory,
    screen: screen.Screen,
  )
}

pub fn init() -> Emulator {
  Emulator(
    state: AwaitingROM,
    registers: registers.new(),
    keyboard: keyboard.new(),
    pc: 0x200,
    stack: stack.new(),
    memory: memory.put(memory.new(4096), 0, font),
    screen: screen.new(64, 32),
  )
}

pub fn reset(_emulator: Emulator) -> Emulator {
  init()
}

pub fn load_rom(emulator: Emulator, rom: ROM) -> Emulator {
  assert Emulator(state: AwaitingROM, ..) = emulator
  Emulator(
    ..emulator,
    state: Running,
    memory: memory.put(emulator.memory, emulator.pc, rom),
  )
}

pub fn handle_key_down(emulator: Emulator, key: keyboard.KeyCode) -> Emulator {
  let emulator =
    Emulator(
      ..emulator,
      keyboard: keyboard.handle_key_down(emulator.keyboard, key),
    )
  case emulator.state {
    Running -> emulator
    AwaitingROM -> emulator
    AwaitingInput(vx) ->
      Emulator(
        ..emulator,
        state: Running,
        registers: registers.set_data_register(
          emulator.registers,
          vx,
          keyboard.key_code_to_int(key),
        ),
      )
  }
}

pub fn handle_key_up(emulator: Emulator, key: keyboard.KeyCode) -> Emulator {
  Emulator(..emulator, keyboard: keyboard.handle_key_up(emulator.keyboard, key))
}

pub fn execute_instruction(
  emulator: Emulator,
  instruction: instruction.Instruction,
) -> Emulator {
  case instruction {
    instruction.Unknown(_) -> emulator

    instruction.ExecuteSystemCall(_) -> emulator

    instruction.ClearScreen ->
      Emulator(..emulator, screen: screen.clear(emulator.screen))

    instruction.ReturnFromSubroutine -> {
      let tuple(stack, address) = stack.pop(emulator.stack)
      Emulator(..emulator, stack: stack, pc: address)
    }

    instruction.JumpAbsolute(address) -> Emulator(..emulator, pc: address - 2)

    instruction.CallSubroutine(address) ->
      Emulator(
        ..emulator,
        pc: address - 2,
        stack: stack.push(emulator.stack, emulator.pc),
      )

    instruction.SkipNextIfEqualConstant(vx, value) ->
      case registers.get_data_register(emulator.registers, vx) == value {
        True -> Emulator(..emulator, pc: emulator.pc + 2)
        False -> emulator
      }

    instruction.SkipNextIfNotEqualConstant(vx, value) ->
      case registers.get_data_register(emulator.registers, vx) == value {
        True -> emulator
        False -> Emulator(..emulator, pc: emulator.pc + 2)
      }

    instruction.SkipNextIfEqualRegisters(vx, vy) ->
      case registers.get_data_register(emulator.registers, vx) == registers.get_data_register(
        emulator.registers,
        vy,
      ) {
        True -> Emulator(..emulator, pc: emulator.pc + 2)
        False -> emulator
      }

    instruction.SetRegisterToConstant(vx, value) ->
      Emulator(
        ..emulator,
        registers: registers.set_data_register(emulator.registers, vx, value),
      )

    instruction.AddToRegister(vx, value) ->
      Emulator(
        ..emulator,
        registers: registers.update_data_register(
          emulator.registers,
          vx,
          fn(old) { old + value },
        ),
      )

    instruction.SetRegisterToRegister(vx, vy) ->
      Emulator(
        ..emulator,
        registers: registers.set_data_register(
          emulator.registers,
          vx,
          registers.get_data_register(emulator.registers, vy),
        ),
      )

    instruction.SetRegisterOr(vx, vy) -> {
      let vy_value = registers.get_data_register(emulator.registers, vy)
      Emulator(
        ..emulator,
        registers: registers.update_data_register(
          emulator.registers,
          vx,
          fn(vx_value) { bitwise.or(vx_value, vy_value) },
        ),
      )
    }

    instruction.SetRegisterAnd(vx, vy) -> {
      let vy_value = registers.get_data_register(emulator.registers, vy)
      Emulator(
        ..emulator,
        registers: registers.update_data_register(
          emulator.registers,
          vx,
          fn(vx_value) { bitwise.and(vx_value, vy_value) },
        ),
      )
    }

    instruction.SetRegisterXor(vx, vy) -> {
      let vy_value = registers.get_data_register(emulator.registers, vy)
      Emulator(
        ..emulator,
        registers: registers.update_data_register(
          emulator.registers,
          vx,
          fn(vx_value) { bitwise.exclusive_or(vx_value, vy_value) },
        ),
      )
    }

    instruction.SetRegisterAdd(vx, vy) -> {
      let vx_value = registers.get_data_register(emulator.registers, vx)
      let vy_value = registers.get_data_register(emulator.registers, vy)
      let result = vx_value + vy_value
      let carry = case result > 255 {
        True -> 1
        False -> 0
      }
      let updated_registers =
        emulator.registers
        |> registers.set_data_register(vx, result)
        |> registers.set_data_register(registers.VF, carry)
      Emulator(..emulator, registers: updated_registers)
    }

    instruction.SetRegisterSub(vx, vy) -> {
      let vx_value = registers.get_data_register(emulator.registers, vx)
      let vy_value = registers.get_data_register(emulator.registers, vy)
      let result = vx_value - vy_value
      let not_borrow = case vx_value > vy_value {
        True -> 1
        False -> 0
      }
      let updated_registers =
        emulator.registers
        |> registers.set_data_register(vx, result)
        |> registers.set_data_register(registers.VF, not_borrow)
      Emulator(..emulator, registers: updated_registers)
    }

    instruction.SetRegisterShiftRight(vx, _) -> {
      let value = registers.get_data_register(emulator.registers, vx)
      let lsb = bitwise.and(value, 1)
      let updated_registers =
        emulator.registers
        |> registers.set_data_register(vx, value / 2)
        |> registers.set_data_register(registers.VF, lsb)
      Emulator(..emulator, registers: updated_registers)
    }

    instruction.SetRegisterSubFlipped(vx, vy) -> {
      let vx_value = registers.get_data_register(emulator.registers, vx)
      let vy_value = registers.get_data_register(emulator.registers, vy)
      let result = vy_value - vx_value
      let not_borrow = case vy_value > vx_value {
        True -> 1
        False -> 0
      }
      let updated_registers =
        emulator.registers
        |> registers.set_data_register(vx, result)
        |> registers.set_data_register(registers.VF, not_borrow)
      Emulator(..emulator, registers: updated_registers)
    }

    instruction.SetRegisterShiftLeft(vx, _) -> {
      let value = registers.get_data_register(emulator.registers, vx)
      let msb = bitwise.and(value, 128)
      let vf = case msb {
        0 -> 0
        128 -> 1
      }
      let updated_registers =
        emulator.registers
        |> registers.set_data_register(vx, value * 2)
        |> registers.set_data_register(registers.VF, vf)
      Emulator(..emulator, registers: updated_registers)
    }

    instruction.SkipNextIfNotEqualRegisters(vx, vy) -> {
      let vx_value = registers.get_data_register(emulator.registers, vx)
      let vy_value = registers.get_data_register(emulator.registers, vy)
      case vx_value == vy_value {
        True -> emulator
        False -> Emulator(..emulator, pc: emulator.pc + 2)
      }
    }

    instruction.SetAddressRegisterToConstant(address) ->
      Emulator(
        ..emulator,
        registers: registers.set_address_register(emulator.registers, address),
      )

    instruction.JumpRelative(offset) ->
      Emulator(
        ..emulator,
        pc: offset + registers.get_data_register(
          emulator.registers,
          registers.V0,
        ),
      )

    instruction.SetRegisterRandom(vx, mask) -> {
      let rand = helpers.rand_uniform(256) - 1
      let result = bitwise.and(rand, mask)
      Emulator(
        ..emulator,
        registers: registers.set_data_register(emulator.registers, vx, result),
      )
    }

    instruction.DisplaySprite(vx, vy, length) -> {
      let x = registers.get_data_register(emulator.registers, vx)
      let y = registers.get_data_register(emulator.registers, vy)
      let offset = registers.get_address_register(emulator.registers)
      assert Ok(sprite_data) = memory.read(emulator.memory, offset, length)
      let sprite = sprite.to_sprite(sprite_data)
      let tuple(screen, collision) =
        screen.draw_sprite(emulator.screen, sprite, x, y)
      let registers = case collision {
        False ->
          registers.set_data_register(emulator.registers, registers.VF, 0)
        True -> registers.set_data_register(emulator.registers, registers.VF, 1)
      }
      Emulator(..emulator, screen: screen, registers: registers)
    }

    instruction.SkipNextIfKeyPressed(vx) -> {
      let value = registers.get_data_register(emulator.registers, vx)
      let key = keyboard.to_key_code(value)
      case keyboard.get_key_state(emulator.keyboard, key) {
        keyboard.KeyUp -> emulator
        keyboard.KeyDown -> Emulator(..emulator, pc: emulator.pc + 2)
      }
    }

    instruction.SkipNextIfKeyNotPressed(vx) -> {
      let value = registers.get_data_register(emulator.registers, vx)
      let key = keyboard.to_key_code(value)
      case keyboard.get_key_state(emulator.keyboard, key) {
        keyboard.KeyUp -> Emulator(..emulator, pc: emulator.pc + 2)
        keyboard.KeyDown -> emulator
      }
    }

    instruction.SetRegisterToDelayTimer(vx) ->
      Emulator(
        ..emulator,
        registers: registers.set_data_register(
          emulator.registers,
          vx,
          registers.get_delay_timer(emulator.registers),
        ),
      )

    instruction.WaitForKeyPress(vx) ->
      Emulator(..emulator, state: AwaitingInput(vx: vx))

    instruction.SetDelayTimerToRegisterValue(vx) ->
      Emulator(
        ..emulator,
        registers: registers.set_delay_timer(
          emulator.registers,
          registers.get_data_register(emulator.registers, vx),
        ),
      )

    instruction.SetSoundTimerToRegisterValue(vx) ->
      Emulator(
        ..emulator,
        registers: registers.set_sound_timer(
          emulator.registers,
          registers.get_data_register(emulator.registers, vx),
        ),
      )

    instruction.AddToAddressRegister(vx) ->
      Emulator(
        ..emulator,
        registers: registers.update_address_register(
          emulator.registers,
          fn(old) { old + registers.get_data_register(emulator.registers, vx) },
        ),
      )

    instruction.SetAddressRegisterToSpriteLocation(vx) -> {
      let character = registers.get_data_register(emulator.registers, vx)
      let offset = character * 5
      Emulator(
        ..emulator,
        registers: registers.set_address_register(emulator.registers, offset),
      )
    }

    instruction.StoreBcdOfRegister(vx) -> {
      let n = registers.get_data_register(emulator.registers, vx)
      let x0 = n / 100
      let x1 = n % 100 / 10
      let x2 = n % 10
      let offset = registers.get_address_register(emulator.registers)
      let m =
        emulator.memory
        |> memory.put(offset, <<x0:size(8)>>)
        |> memory.put(offset + 1, <<x1:size(8)>>)
        |> memory.put(offset + 2, <<x2:size(8)>>)
      Emulator(..emulator, memory: m)
    }

    instruction.StoreRegistersAtAddressRegister(vx) -> {
      let address = registers.get_address_register(emulator.registers)
      let tuple(emulator, _, _) =
        list.fold(
          registers.list_v(),
          tuple(emulator, 0, False),
          fn(register, acc: tuple(Emulator, Int, Bool)) {
            let tuple(emulator, offset, done) = acc
            case done {
              True -> acc
              False -> {
                let value =
                  registers.get_data_register(emulator.registers, register)
                let memory =
                  memory.put(emulator.memory, address + offset, <<value>>)
                let emulator = Emulator(..emulator, memory: memory)
                let done = register == vx
                tuple(emulator, offset + 1, done)
              }
            }
          },
        )
      emulator
    }

    instruction.ReadRegistersFromAddressRegister(vx) -> {
      let address = registers.get_address_register(emulator.registers)
      let tuple(emulator, _, _) =
        list.fold(
          registers.list_v(),
          tuple(emulator, 0, False),
          fn(register, acc: tuple(Emulator, Int, Bool)) {
            let tuple(emulator, offset, done) = acc
            case done {
              True -> acc
              False -> {
                assert Ok(<<value>>) =
                  memory.read(emulator.memory, address + offset, 1)
                let registers =
                  registers.set_data_register(
                    emulator.registers,
                    register,
                    value,
                  )
                let emulator = Emulator(..emulator, registers: registers)
                let done = register == vx
                tuple(emulator, offset + 1, done)
              }
            }
          },
        )
      emulator
    }
  }
}

pub fn step(emulator: Emulator) -> Emulator {
  case emulator.state {
    AwaitingROM -> emulator

    AwaitingInput(_) -> emulator

    Running -> {
      assert Ok(raw_instruction) = memory.read(emulator.memory, emulator.pc, 2)
      let instruction = instruction.decode_instruction(raw_instruction)
      let emulator = execute_instruction(emulator, instruction)
      Emulator(..emulator, pc: emulator.pc + 2)
    }
  }
}

pub fn handle_timers(emulator: Emulator) -> Emulator {
  let screen = screen.decay(emulator.screen)
  let registers =
    emulator.registers
    |> registers.decrement_delay_timer()
    |> registers.decrement_sound_timer()

  Emulator(..emulator, registers: registers, screen: screen)
}

pub fn disassemble_instructions(
  emulator: Emulator,
  length: Int,
) -> List(tuple(String, String, Bool)) {
  let half_length = length / 2
  let start = int.max(512, emulator.pc - half_length * 2)

  list.range(0, length - 1)
  |> list.map(fn(n) {
    let address = start + n * 2
    assert Ok(raw) = memory.read(emulator.memory, address, 2)
    let decoded = instruction.decode_instruction(raw)
    let disassembled = instruction.disassemble(decoded)

    tuple(
      helpers.int_to_hex_string(address),
      disassembled,
      address == emulator.pc,
    )
  })
}
