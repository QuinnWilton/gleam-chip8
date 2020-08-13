import gleam/bitwise
import chip8/externals
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

pub type Instruction {
  InstSYS(address: Int)
  InstCLS
  InstRET
  InstJPAbsolute(address: Int)
  InstJPOffset(offset: Int)
  InstCALL(address: Int)
  InstSEImm(vx: registers.Register, value: Int)
  InstSEReg(vx: registers.Register, vy: registers.Register)
  InstSNEImm(vx: registers.Register, value: Int)
  InstSNEReg(vx: registers.Register, vy: registers.Register)
  InstLDRegImm(vx: registers.Register, value: Int)
  InstLDRegReg(vx: registers.Register, vy: registers.Register)
  InstLDRegI(address: Int)
  InstLDRegDT(vx: registers.Register)
  InstLDRegK(vx: registers.Register)
  InstLDDTReg(vx: registers.Register)
  InstLDSTReg(vx: registers.Register)
  InstLDFReg(vx: registers.Register)
  InstLDBReg(vx: registers.Register)
  InstLDArrReg(vx: registers.Register)
  InstLDRegArr(vx: registers.Register)
  InstADDRegImm(vx: registers.Register, value: Int)
  InstADDRegReg(vx: registers.Register, vy: registers.Register)
  InstADDIReg(vx: registers.Register)
  InstOR(vx: registers.Register, vy: registers.Register)
  InstAND(vx: registers.Register, vy: registers.Register)
  InstXOR(vx: registers.Register, vy: registers.Register)
  InstSHRReg(vx: registers.Register)
  InstSHLReg(vx: registers.Register)
  InstSUBRegReg(vx: registers.Register, vy: registers.Register)
  InstSUBNRegReg(vx: registers.Register, vy: registers.Register)
  InstRND(vx: registers.Register, value: Int)
  InstDRW(vx: registers.Register, vy: registers.Register, length: Int)
  InstSKP(value: Int)
  InstSKNP(value: Int)
}

pub fn init() -> Emulator {
  Emulator(
    state: Running,
    registers: registers.new(),
    keyboard: keyboard.new(),
    pc: 512,
    stack: stack.new(),
    memory: memory.new(4096)
    |> memory.put(0, font),
    screen: screen.new(64, 32),
  )
}

pub fn decode_instruction(emulator: Emulator, address: Int) -> Instruction {
  assert Ok(data) = memory.read(emulator.memory, address, 2)

  case data {
    <<0:4, nnn:12>> -> InstSYS(address: nnn)
    <<0:4, 0:4, 14:4, 0:4>> -> InstCLS
    <<0:4, 0:4, 14:4, 14:4>> -> InstRET
    <<1:4, nnn:12>> -> InstJPAbsolute(address: nnn)
    <<2:4, nnn:12>> -> InstCALL(address: nnn)
    <<3:4, x:4, kk:8>> -> InstSEImm(vx: registers.to_register(x), value: kk)
    <<4:4, x:4, kk:8>> -> InstSNEImm(vx: registers.to_register(x), value: kk)
    <<
      5:4,
      x:4,
      y:4,
      0:4,
    >> -> InstSEReg(vx: registers.to_register(x), vy: registers.to_register(y))
    <<6:4, x:4, kk:8>> -> InstLDRegImm(vx: registers.to_register(x), value: kk)
    <<7:4, x:4, kk:8>> -> InstADDRegImm(vx: registers.to_register(x), value: kk)
    <<
      8:4,
      x:4,
      y:4,
      0:4,
    >> -> InstLDRegReg(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      1:4,
    >> -> InstOR(vx: registers.to_register(x), vy: registers.to_register(y))
    <<
      8:4,
      x:4,
      y:4,
      2:4,
    >> -> InstAND(vx: registers.to_register(x), vy: registers.to_register(y))
    <<
      8:4,
      x:4,
      y:4,
      3:4,
    >> -> InstXOR(vx: registers.to_register(x), vy: registers.to_register(y))
    <<
      8:4,
      x:4,
      y:4,
      4:4,
    >> -> InstADDRegReg(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      5:4,
    >> -> InstSUBRegReg(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<8:4, x:4, _:4, 6:4>> -> InstSHRReg(vx: registers.to_register(x))
    <<
      8:4,
      x:4,
      y:4,
      7:4,
    >> -> InstSUBNRegReg(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<8:4, x:4, _:4, 14:4>> -> InstSHLReg(vx: registers.to_register(x))
    <<
      9:4,
      x:4,
      y:4,
      0:4,
    >> -> InstSEReg(vx: registers.to_register(x), vy: registers.to_register(y))
    <<10:4, nnn:12>> -> InstLDRegI(address: nnn)
    <<11:4, nnn:12>> -> InstJPOffset(offset: nnn)
    <<12:4, x:4, nn:8>> -> InstRND(vx: registers.to_register(x), value: nn)
    <<
      13:4,
      x:4,
      y:4,
      n:4,
    >> -> InstDRW(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
      length: n,
    )
    <<14:4, x:4, 9:4, 14:4>> -> InstSKP(value: x)
    <<14:4, x:4, 10:4, 1:4>> -> InstSKNP(value: x)
    <<15:4, x:4, 0:4, 7:4>> -> InstLDRegDT(vx: registers.to_register(x))
    <<15:4, x:4, 0:4, 10:4>> -> InstLDRegK(vx: registers.to_register(x))
    <<15:4, x:4, 1:4, 5:4>> -> InstLDDTReg(vx: registers.to_register(x))
    <<15:4, x:4, 1:4, 8:4>> -> InstLDSTReg(vx: registers.to_register(x))
    <<15:4, x:4, 1:4, 14:4>> -> InstADDIReg(vx: registers.to_register(x))
    <<15:4, x:4, 2:4, 9:4>> -> InstLDFReg(vx: registers.to_register(x))
    <<15:4, x:4, 3:4, 3:4>> -> InstLDBReg(vx: registers.to_register(x))
    <<15:4, x:4, 5:4, 5:4>> -> InstLDArrReg(vx: registers.to_register(x))
    <<15:4, x:4, 6:4, 5:4>> -> InstLDRegArr(vx: registers.to_register(x))
  }
}

pub fn execute_instruction(
  emulator: Emulator,
  instruction: Instruction,
) -> Emulator {
  case instruction {
    InstSYS(_address) -> emulator
    InstCLS -> Emulator(..emulator, screen: screen.clear(emulator.screen))
    InstRET -> {
      let tuple(stack, address) = stack.pop(emulator.stack)
      Emulator(..emulator, stack: stack, pc: address)
    }
    InstJPAbsolute(address) -> Emulator(..emulator, pc: address)
    InstCALL(
      address,
    ) -> Emulator(
      ..emulator,
      pc: address,
      stack: stack.push(emulator.stack, emulator.pc),
    )
    InstSEImm(
      vx: vx,
      value: value,
    ) -> case registers.read(emulator.registers, vx) == value {
      True -> Emulator(..emulator, pc: emulator.pc + 2)
      False -> emulator
    }
    InstSNEImm(
      vx: vx,
      value: value,
    ) -> case registers.read(emulator.registers, vx) == value {
      True -> emulator
      False -> Emulator(..emulator, pc: emulator.pc + 2)
    }
    InstSEReg(
      vx: vx,
      vy: vy,
    ) -> case registers.read(
      emulator.registers,
      vx,
    ) == registers.read(emulator.registers, vy) {
      True -> Emulator(..emulator, pc: emulator.pc + 2)
      False -> emulator
    }
    InstLDRegImm(
      vx: vx,
      value: value,
    ) -> Emulator(
      ..emulator,
      registers: registers.write(emulator.registers, vx, value),
    )
    InstADDRegImm(
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
    InstLDRegReg(
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
    InstOR(vx: vx, vy: vy) -> {
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
    InstAND(vx: vx, vy: vy) -> {
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
    InstXOR(vx: vx, vy: vy) -> {
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
    InstADDRegReg(vx: vx, vy: vy) -> {
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
    InstSUBRegReg(vx: vx, vy: vy) -> {
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
    InstSHRReg(vx: vx) -> {
      let vx_value = registers.read(emulator.registers, vx)
      let lsb = bitwise.and(vx_value, 1)
      let result = case lsb {
        0 -> vx_value / 2
        1 -> vx_value
          |> fn(x) { x - 1 }
          |> fn(x) { x / 2 }
      }
      let updated_registers = emulator.registers
        |> registers.write(vx, result)
        |> registers.write(registers.VF, lsb)
      Emulator(..emulator, registers: updated_registers)
    }
    InstSUBNRegReg(vx: vx, vy: vy) -> {
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
    InstSHLReg(vx: vx) -> {
      let vx_value = registers.read(emulator.registers, vx)
      let msb = bitwise.and(vx_value, 128)
      let tuple(result, vf) = case msb {
        0 -> tuple(vx_value * 2, 0)
        128 -> tuple(
          vx_value
          |> fn(x) { x - 1 }
          |> fn(x) { x * 2 },
          1,
        )
      }
      let updated_registers = emulator.registers
        |> registers.write(vx, result)
        |> registers.write(registers.VF, vf)
      Emulator(..emulator, registers: updated_registers)
    }
    InstSNEReg(vx: vx, vy: vy) -> {
      let vx_value = registers.read(emulator.registers, vx)
      let vy_value = registers.read(emulator.registers, vy)
      case vx_value == vy_value {
        True -> emulator
        False -> Emulator(..emulator, pc: emulator.pc + 2)
      }
    }
    InstLDRegI(
      address,
    ) -> Emulator(
      ..emulator,
      registers: registers.write(emulator.registers, registers.I, address),
    )
    InstJPOffset(
      offset,
    ) -> Emulator(
      ..emulator,
      pc: offset + registers.read(emulator.registers, registers.V0),
    )
    InstRND(vx: vx, value: value) -> {
      let rand = externals.rand_uniform(256) - 1
      let result = bitwise.and(rand, value)
      Emulator(
        ..emulator,
        registers: registers.write(emulator.registers, vx, result),
      )
    }
    InstDRW(vx: vx, vy: vy, length: length) -> {
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
    InstSKP(value: value) -> {
      let key = keyboard.to_key_code(value)
      case keyboard.get_key_state(emulator.keyboard, key) {
        keyboard.KeyUp -> emulator
        keyboard.KeyDown -> Emulator(..emulator, pc: emulator.pc + 2)
      }
    }
    InstSKNP(value: value) -> {
      let key = keyboard.to_key_code(value)
      case keyboard.get_key_state(emulator.keyboard, key) {
        keyboard.KeyUp -> Emulator(..emulator, pc: emulator.pc + 2)
        keyboard.KeyDown -> emulator
      }
    }
    InstLDRegDT(
      vx: vx,
    ) -> Emulator(
      ..emulator,
      registers: registers.write(
        emulator.registers,
        vx,
        registers.read(emulator.registers, registers.DT),
      ),
    )
    InstLDRegK(vx: vx) -> Emulator(..emulator, state: AwaitingInput(vx: vx))
    InstLDDTReg(
      vx: vx,
    ) -> Emulator(
      ..emulator,
      registers: registers.write(
        emulator.registers,
        registers.DT,
        registers.read(emulator.registers, vx),
      ),
    )
    InstLDSTReg(
      vx: vx,
    ) -> Emulator(
      ..emulator,
      registers: registers.write(
        emulator.registers,
        registers.ST,
        registers.read(emulator.registers, vx),
      ),
    )
    InstADDIReg(
      vx: vx,
    ) -> Emulator(
      ..emulator,
      registers: registers.update(
        emulator.registers,
        registers.I,
        fn(old) { old + registers.read(emulator.registers, vx) },
      ),
    )
    InstLDFReg(vx: vx) -> {
      let character = registers.read(emulator.registers, vx)
      let offset = character * 5
      Emulator(
        ..emulator,
        registers: registers.write(emulator.registers, registers.I, offset),
      )
    }
    InstLDBReg(vx: vx) -> {
      let x = registers.read(emulator.registers, vx)
      let x0 = x / 100
      let x1 = x % 100 / 10
      let x2 = x % 10
      let offset = registers.read(emulator.registers, registers.I)
      let m = emulator.memory
        |> memory.put(offset, <<x0>>)
        |> memory.put(offset + 1, <<x1>>)
        |> memory.put(offset + 2, <<x2>>)
      Emulator(..emulator, memory: m)
    }
    InstLDArrReg(vx: vx) -> {
      let offset = registers.read(emulator.registers, registers.I)
      let m = emulator.memory
        |> memory.put(
          offset,
          <<registers.read(emulator.registers, registers.V0)>>,
        )
        |> memory.put(
          offset + 1,
          <<registers.read(emulator.registers, registers.V1)>>,
        )
        |> memory.put(
          offset + 2,
          <<registers.read(emulator.registers, registers.V2)>>,
        )
        |> memory.put(
          offset + 3,
          <<registers.read(emulator.registers, registers.V3)>>,
        )
        |> memory.put(
          offset + 4,
          <<registers.read(emulator.registers, registers.V4)>>,
        )
        |> memory.put(
          offset + 5,
          <<registers.read(emulator.registers, registers.V5)>>,
        )
        |> memory.put(
          offset + 6,
          <<registers.read(emulator.registers, registers.V6)>>,
        )
        |> memory.put(
          offset + 7,
          <<registers.read(emulator.registers, registers.V7)>>,
        )
        |> memory.put(
          offset + 8,
          <<registers.read(emulator.registers, registers.V8)>>,
        )
        |> memory.put(
          offset + 9,
          <<registers.read(emulator.registers, registers.V9)>>,
        )
        |> memory.put(
          offset + 10,
          <<registers.read(emulator.registers, registers.VA)>>,
        )
        |> memory.put(
          offset + 11,
          <<registers.read(emulator.registers, registers.VB)>>,
        )
        |> memory.put(
          offset + 12,
          <<registers.read(emulator.registers, registers.VC)>>,
        )
        |> memory.put(
          offset + 13,
          <<registers.read(emulator.registers, registers.VD)>>,
        )
        |> memory.put(
          offset + 14,
          <<registers.read(emulator.registers, registers.VE)>>,
        )
        |> memory.put(
          offset + 15,
          <<registers.read(emulator.registers, registers.VF)>>,
        )
      Emulator(..emulator, memory: m)
    }
    InstLDRegArr(vx: vx) -> {
      assert Ok(
        <<m0>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 0,
        1,
      )
      assert Ok(
        <<m1>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 1,
        1,
      )
      assert Ok(
        <<m2>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 2,
        1,
      )
      assert Ok(
        <<m3>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 3,
        1,
      )
      assert Ok(
        <<m4>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 4,
        1,
      )
      assert Ok(
        <<m5>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 5,
        1,
      )
      assert Ok(
        <<m6>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 6,
        1,
      )
      assert Ok(
        <<m7>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 7,
        1,
      )
      assert Ok(
        <<m8>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 8,
        1,
      )
      assert Ok(
        <<m9>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 9,
        1,
      )
      assert Ok(
        <<ma>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 10,
        1,
      )
      assert Ok(
        <<mb>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 11,
        1,
      )
      assert Ok(
        <<mc>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 12,
        1,
      )
      assert Ok(
        <<md>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 13,
        1,
      )
      assert Ok(
        <<me>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 14,
        1,
      )
      assert Ok(
        <<mf>>,
      ) = memory.read(
        emulator.memory,
        registers.read(emulator.registers, registers.I) + 15,
        1,
      )
      let r = emulator.registers
        |> registers.write(registers.V0, m0)
        |> registers.write(registers.V1, m1)
        |> registers.write(registers.V2, m2)
        |> registers.write(registers.V3, m3)
        |> registers.write(registers.V4, m4)
        |> registers.write(registers.V5, m5)
        |> registers.write(registers.V6, m6)
        |> registers.write(registers.V7, m7)
        |> registers.write(registers.V8, m8)
        |> registers.write(registers.V9, m9)
        |> registers.write(registers.VA, ma)
        |> registers.write(registers.VB, mb)
        |> registers.write(registers.VC, mc)
        |> registers.write(registers.VD, md)
        |> registers.write(registers.VE, me)
        |> registers.write(registers.VF, mf)
      Emulator(..emulator, registers: r)
    }
  }
}

pub fn step(emulator: Emulator) -> Emulator {
  case emulator {
    Emulator(state: AwaitingInput(_), ..) -> emulator
    Emulator(state: Running, ..) -> {
      let instruction = decode_instruction(emulator, emulator.pc)
      emulator
      |> fn(e) { Emulator(..e, pc: e.pc + 2) }
      |> execute_instruction(instruction)
    }
  }
}

pub fn handle_key_down(emulator: Emulator, key: keyboard.KeyCode) -> Emulator {
  let emulator = Emulator(
    ..emulator,
    keyboard: keyboard.handle_key_down(emulator.keyboard, key),
  )
  case emulator.state {
    Running -> emulator
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

pub fn reset(emulator: Emulator) -> Emulator {
  init()
}

pub fn load_rom(emulator: Emulator, rom: ROM) -> Emulator {
  Emulator(..emulator, memory: memory.put(emulator.memory, emulator.pc, rom))
}
