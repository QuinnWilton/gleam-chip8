import gleam/bitwise
import gleam/int
import gleam/list
import chip8/externals
import chip8/instruction
import chip8/keyboard
import chip8/memory
import chip8/registers
import chip8/screen
import chip8/sprite
import chip8/stack

const font = <<
  240, 144, 144, 144, 240, 32, 96, 32, 32, 112, 240, 16, 240, 128, 240, 240, 16,
  240, 16, 240, 144, 144, 240, 16, 16, 240, 128, 240, 16, 240, 240, 128, 240,
  144, 240, 240, 16, 32, 64, 64, 240, 144, 240, 144, 240, 240, 144, 240, 16, 240,
  240, 144, 240, 144, 144, 224, 144, 224, 144, 224, 240, 128, 128, 128, 240, 224,
  144, 144, 144, 224, 240, 128, 240, 128, 240, 240, 128, 240, 128, 128,
>>

pub type State {
  Running
  AwaitingROM
  AwaitingInput(vx: registers.Register)
}

pub type ROM =
  BitString

pub type Emulator {
  Emulator(
    state: State,
    registers: registers.RegisterFile,
    keyboard: keyboard.Keyboard,
    pc: Int,
    stack: stack.Stack(Int),
    memory: memory.Memory,
    screen: screen.Screen,
  )
}

pub fn init() -> Emulator {
  Emulator(
    state: AwaitingROM,
    registers: registers.new(),
    keyboard: keyboard.new(),
    pc: 512,
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
  let emulator = Emulator(
    ..emulator,
    keyboard: keyboard.handle_key_down(emulator.keyboard, key),
  )
  case emulator.state {
    Running -> emulator
    AwaitingROM -> emulator
    AwaitingInput(
      vx,
    ) -> Emulator(
      ..emulator,
      state: Running,
      registers: registers.write(
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
    instruction.InstSYS(_address) -> emulator
    instruction.InstCLS -> Emulator(
      ..emulator,
      screen: screen.clear(emulator.screen),
    )
    instruction.InstRET -> {
      let tuple(stack, address) = stack.pop(emulator.stack)
      Emulator(..emulator, stack: stack, pc: address)
    }
    instruction.InstJPAbsolute(address) -> Emulator(..emulator, pc: address)
    instruction.InstCALL(
      address,
    ) -> Emulator(
      ..emulator,
      pc: address,
      stack: stack.push(emulator.stack, emulator.pc),
    )
    instruction.InstSEImm(
      vx: vx,
      value: value,
    ) -> case registers.read(emulator.registers, vx) == value {
      True -> Emulator(..emulator, pc: emulator.pc + 2)
      False -> emulator
    }
    instruction.InstSNEImm(
      vx: vx,
      value: value,
    ) -> case registers.read(emulator.registers, vx) == value {
      True -> emulator
      False -> Emulator(..emulator, pc: emulator.pc + 2)
    }
    instruction.InstSEReg(
      vx: vx,
      vy: vy,
    ) -> case registers.read(
      emulator.registers,
      vx,
    ) == registers.read(emulator.registers, vy) {
      True -> Emulator(..emulator, pc: emulator.pc + 2)
      False -> emulator
    }
    instruction.InstLDRegImm(
      vx: vx,
      value: value,
    ) -> Emulator(
      ..emulator,
      registers: registers.write(emulator.registers, vx, value),
    )
    instruction.InstADDRegImm(
      vx: vx,
      value: value,
    ) -> Emulator(
      ..emulator,
      registers: registers.update(
        emulator.registers,
        vx,
        fn(old) { old + value },
      ),
    )
    instruction.InstLDRegReg(
      vx: vx,
      vy: vy,
    ) -> Emulator(
      ..emulator,
      registers: registers.write(
        emulator.registers,
        vx,
        registers.read(emulator.registers, vy),
      ),
    )
    instruction.InstOR(vx: vx, vy: vy) -> {
      let vy_value = registers.read(emulator.registers, vy)
      Emulator(
        ..emulator,
        registers: registers.update(
          emulator.registers,
          vx,
          fn(vx_value) { bitwise.or(vx_value, vy_value) },
        ),
      )
    }
    instruction.InstAND(vx: vx, vy: vy) -> {
      let vy_value = registers.read(emulator.registers, vy)
      Emulator(
        ..emulator,
        registers: registers.update(
          emulator.registers,
          vx,
          fn(vx_value) { bitwise.and(vx_value, vy_value) },
        ),
      )
    }
    instruction.InstXOR(vx: vx, vy: vy) -> {
      let vy_value = registers.read(emulator.registers, vy)
      Emulator(
        ..emulator,
        registers: registers.update(
          emulator.registers,
          vx,
          fn(vx_value) { bitwise.exclusive_or(vx_value, vy_value) },
        ),
      )
    }
    instruction.InstADDRegReg(vx: vx, vy: vy) -> {
      let vx_value = registers.read(emulator.registers, vx)
      let vy_value = registers.read(emulator.registers, vy)
      let result = vx_value + vy_value
      let carry = case result > 255 {
        True -> 1
        False -> 0
      }
      let updated_registers = emulator.registers
        |> registers.write(vx, result)
        |> registers.write(registers.VF, carry)
      Emulator(..emulator, registers: updated_registers)
    }
    instruction.InstSUBRegReg(vx: vx, vy: vy) -> {
      let vx_value = registers.read(emulator.registers, vx)
      let vy_value = registers.read(emulator.registers, vy)
      let result = vx_value - vy_value
      let not_borrow = case vx_value > vy_value {
        True -> 1
        False -> 0
      }
      let updated_registers = emulator.registers
        |> registers.write(vx, result)
        |> registers.write(registers.VF, not_borrow)
      Emulator(..emulator, registers: updated_registers)
    }
    instruction.InstSHRReg(vx: vx) -> {
      let vx_value = registers.read(emulator.registers, vx)
      let lsb = bitwise.and(vx_value, 1)
      let updated_registers = emulator.registers
        |> registers.write(vx, vx_value / 2)
        |> registers.write(registers.VF, lsb)
      Emulator(..emulator, registers: updated_registers)
    }
    instruction.InstSUBNRegReg(vx: vx, vy: vy) -> {
      let vx_value = registers.read(emulator.registers, vx)
      let vy_value = registers.read(emulator.registers, vy)
      let result = vy_value - vx_value
      let not_borrow = case vy_value > vx_value {
        True -> 1
        False -> 0
      }
      let updated_registers = emulator.registers
        |> registers.write(vx, result)
        |> registers.write(registers.VF, not_borrow)
      Emulator(..emulator, registers: updated_registers)
    }
    instruction.InstSHLReg(vx: vx) -> {
      let vx_value = registers.read(emulator.registers, vx)
      let msb = bitwise.and(vx_value, 128)
      let vf = case msb {
        0 -> 0
        128 -> 1
      }
      let updated_registers = emulator.registers
        |> registers.write(vx, vx_value * 2)
        |> registers.write(registers.VF, vf)
      Emulator(..emulator, registers: updated_registers)
    }
    instruction.InstSNEReg(vx: vx, vy: vy) -> {
      let vx_value = registers.read(emulator.registers, vx)
      let vy_value = registers.read(emulator.registers, vy)
      case vx_value == vy_value {
        True -> emulator
        False -> Emulator(..emulator, pc: emulator.pc + 2)
      }
    }
    instruction.InstLDRegI(
      address,
    ) -> Emulator(
      ..emulator,
      registers: registers.write(emulator.registers, registers.I, address),
    )
    instruction.InstJPOffset(
      offset,
    ) -> Emulator(
      ..emulator,
      pc: offset + registers.read(emulator.registers, registers.V0),
    )
    instruction.InstRND(vx: vx, value: value) -> {
      let rand = externals.rand_uniform(256) - 1
      let result = bitwise.and(rand, value)
      Emulator(
        ..emulator,
        registers: registers.write(emulator.registers, vx, result),
      )
    }
    instruction.InstDRW(vx: vx, vy: vy, length: length) -> {
      let x = registers.read(emulator.registers, vx)
      let y = registers.read(emulator.registers, vy)
      let offset = registers.read(emulator.registers, registers.I)
      assert Ok(sprite_data) = memory.read(emulator.memory, offset, length)
      let sprite = sprite.to_sprite(sprite_data)
      let tuple(
        screen,
        collision,
      ) = screen.draw_sprite(emulator.screen, sprite, x, y)
      let registers = case collision {
        False -> registers.write(emulator.registers, registers.VF, 1)
        True -> registers.write(emulator.registers, registers.VF, 1)
      }
      Emulator(..emulator, screen: screen, registers: registers)
    }
    instruction.InstSKP(value: value) -> {
      let key = keyboard.to_key_code(value)
      case keyboard.get_key_state(emulator.keyboard, key) {
        keyboard.KeyUp -> emulator
        keyboard.KeyDown -> Emulator(..emulator, pc: emulator.pc + 2)
      }
    }
    instruction.InstSKNP(value: value) -> {
      let key = keyboard.to_key_code(value)
      case keyboard.get_key_state(emulator.keyboard, key) {
        keyboard.KeyUp -> Emulator(..emulator, pc: emulator.pc + 2)
        keyboard.KeyDown -> emulator
      }
    }
    instruction.InstLDRegDT(
      vx: vx,
    ) -> Emulator(
      ..emulator,
      registers: registers.write(
        emulator.registers,
        vx,
        registers.read(emulator.registers, registers.DT),
      ),
    )
    instruction.InstLDRegK(
      vx: vx,
    ) -> Emulator(..emulator, state: AwaitingInput(vx: vx))
    instruction.InstLDDTReg(
      vx: vx,
    ) -> Emulator(
      ..emulator,
      registers: registers.write(
        emulator.registers,
        registers.DT,
        registers.read(emulator.registers, vx),
      ),
    )
    instruction.InstLDSTReg(
      vx: vx,
    ) -> Emulator(
      ..emulator,
      registers: registers.write(
        emulator.registers,
        registers.ST,
        registers.read(emulator.registers, vx),
      ),
    )
    instruction.InstADDIReg(
      vx: vx,
    ) -> Emulator(
      ..emulator,
      registers: registers.update(
        emulator.registers,
        registers.I,
        fn(old) { old + registers.read(emulator.registers, vx) },
      ),
    )
    instruction.InstLDFReg(vx: vx) -> {
      let character = registers.read(emulator.registers, vx)
      let offset = character * 5
      Emulator(
        ..emulator,
        registers: registers.write(emulator.registers, registers.I, offset),
      )
    }
    instruction.InstLDBReg(vx: vx) -> {
      let n = registers.read(emulator.registers, vx)
      let x0 = n / 100
      let x1 = n % 100 / 10
      let x2 = n % 10
      let offset = registers.read(emulator.registers, registers.I)
      let m = emulator.memory
        |> memory.put(offset, <<x0>>)
        |> memory.put(offset + 1, <<x1>>)
        |> memory.put(offset + 2, <<x2>>)
      Emulator(..emulator, memory: m)
    }
    instruction.InstLDArrReg(vx: vx) -> {
      let address = registers.read(emulator.registers, registers.I)
      let tuple(
        emulator,
        _,
        _,
      ) = list.fold(
        registers.list_v(),
        tuple(emulator, 0, False),
        fn(register, acc: tuple(Emulator, Int, Bool)) {
          let tuple(emulator, offset, done) = acc
          case done {
            True -> acc
            False -> {
              let value = registers.read(emulator.registers, register)
              let memory = memory.put(
                emulator.memory,
                address + offset,
                <<value>>,
              )
              let emulator = Emulator(..emulator, memory: memory)
              let done = register == vx
              tuple(emulator, offset + 1, done)
            }
          }
        },
      )
      emulator
    }
    instruction.InstLDRegArr(vx: vx) -> {
      let address = registers.read(emulator.registers, registers.I)
      let tuple(
        emulator,
        _,
        _,
      ) = list.fold(
        registers.list_v(),
        tuple(emulator, 0, False),
        fn(register, acc: tuple(Emulator, Int, Bool)) {
          let tuple(emulator, offset, done) = acc
          case done {
            True -> acc
            False -> {
              assert Ok(
                <<value>>,
              ) = memory.read(emulator.memory, address + offset, 1)
              let registers = registers.write(
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
      let Ok(raw_instruction) = memory.read(emulator.memory, emulator.pc, 2)
      let instruction = instruction.decode_instruction(raw_instruction)
      Emulator(..emulator, pc: emulator.pc + 2)
      |> execute_instruction(instruction)
      |> fn(e: Emulator) {
        let registers = e.registers
          |> registers.update(registers.ST, fn(old) { int.max(0, old - 1) })
          |> registers.update(registers.DT, fn(old) { int.max(0, old - 1) })
        Emulator(..e, registers: registers)
      }
    }
  }
}
