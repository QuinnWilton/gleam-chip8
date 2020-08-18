import gleam/int
import gleam/string
import chip8/helpers
import chip8/keyboard
import chip8/registers

pub type Instruction {
  ExecuteSystemCall(address: Int)
  ClearScreen
  ReturnFromSubroutine
  JumpAbsolute(address: Int)
  JumpRelative(offset: Int)
  CallSubroutine(address: Int)
  SkipNextIfEqualConstant(vx: registers.DataRegister, value: Int)
  SkipNextIfEqualRegisters(
    vx: registers.DataRegister,
    vy: registers.DataRegister,
  )
  SkipNextIfNotEqualConstant(vx: registers.DataRegister, value: Int)
  SkipNextIfNotEqualRegisters(
    vx: registers.DataRegister,
    vy: registers.DataRegister,
  )
  SetRegisterToConstant(vx: registers.DataRegister, value: Int)
  SetRegisterToRegister(vx: registers.DataRegister, vy: registers.DataRegister)
  SetAddressRegisterToConstant(address: Int)
  SetRegisterToDelayTimer(vx: registers.DataRegister)
  WaitForKeyPress(vx: registers.DataRegister)
  SetDelayTimerToRegisterValue(vx: registers.DataRegister)
  SetSoundTimerToRegisterValue(vx: registers.DataRegister)
  SetAddressRegisterToSpriteLocation(vx: registers.DataRegister)
  StoreBcdOfRegister(vx: registers.DataRegister)
  StoreRegistersAtAddressRegister(vx: registers.DataRegister)
  ReadRegistersFromAddressRegister(vx: registers.DataRegister)
  AddToRegister(vx: registers.DataRegister, value: Int)
  SetRegisterAdd(vx: registers.DataRegister, vy: registers.DataRegister)
  AddToAddressRegister(vx: registers.DataRegister)
  SetRegisterOr(vx: registers.DataRegister, vy: registers.DataRegister)
  SetRegisterAnd(vx: registers.DataRegister, vy: registers.DataRegister)
  SetRegisterXor(vx: registers.DataRegister, vy: registers.DataRegister)
  SetRegisterShiftRight(vx: registers.DataRegister, vy: registers.DataRegister)
  SetRegisterShiftLeft(vx: registers.DataRegister, vy: registers.DataRegister)
  SetRegisterSub(vx: registers.DataRegister, vy: registers.DataRegister)
  SetRegisterSubFlipped(vx: registers.DataRegister, vy: registers.DataRegister)
  SetRegisterRandom(vx: registers.DataRegister, mask: Int)
  DisplaySprite(
    vx: registers.DataRegister,
    vy: registers.DataRegister,
    length: Int,
  )
  SkipNextIfKeyPressed(vx: registers.DataRegister)
  SkipNextIfKeyNotPressed(vx: registers.DataRegister)
  Unknown(raw: BitString)
}

pub fn decode_instruction(instruction: BitString) -> Instruction {
  case instruction {
    <<0:4, 0:4, 14:4, 0:4>> -> ClearScreen
    <<0:4, 0:4, 14:4, 14:4>> -> ReturnFromSubroutine
    <<0:4, nnn:12>> -> ExecuteSystemCall(nnn)
    <<1:4, nnn:12>> -> JumpAbsolute(nnn)
    <<2:4, nnn:12>> -> CallSubroutine(nnn)
    <<
      3:4,
      x:4,
      kk:8,
    >> -> SkipNextIfEqualConstant(registers.to_data_register(x), kk)
    <<
      4:4,
      x:4,
      kk:8,
    >> -> SkipNextIfNotEqualConstant(registers.to_data_register(x), kk)
    <<
      5:4,
      x:4,
      y:4,
      0:4,
    >> -> SkipNextIfEqualRegisters(
      registers.to_data_register(x),
      registers.to_data_register(y),
    )
    <<
      6:4,
      x:4,
      kk:8,
    >> -> SetRegisterToConstant(registers.to_data_register(x), kk)
    <<7:4, x:4, kk:8>> -> AddToRegister(registers.to_data_register(x), kk)
    <<
      8:4,
      x:4,
      y:4,
      0:4,
    >> -> SetRegisterToRegister(
      registers.to_data_register(x),
      registers.to_data_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      1:4,
    >> -> SetRegisterOr(
      registers.to_data_register(x),
      registers.to_data_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      2:4,
    >> -> SetRegisterAnd(
      registers.to_data_register(x),
      registers.to_data_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      3:4,
    >> -> SetRegisterXor(
      registers.to_data_register(x),
      registers.to_data_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      4:4,
    >> -> SetRegisterAdd(
      registers.to_data_register(x),
      registers.to_data_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      5:4,
    >> -> SetRegisterSub(
      registers.to_data_register(x),
      registers.to_data_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      6:4,
    >> -> SetRegisterShiftRight(
      registers.to_data_register(x),
      registers.to_data_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      7:4,
    >> -> SetRegisterSubFlipped(
      registers.to_data_register(x),
      registers.to_data_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      14:4,
    >> -> SetRegisterShiftLeft(
      registers.to_data_register(x),
      registers.to_data_register(y),
    )
    <<
      9:4,
      x:4,
      y:4,
      0:4,
    >> -> SkipNextIfEqualRegisters(
      registers.to_data_register(x),
      registers.to_data_register(y),
    )
    <<10:4, nnn:12>> -> SetAddressRegisterToConstant(nnn)
    <<11:4, nnn:12>> -> JumpRelative(nnn)
    <<12:4, x:4, nn:8>> -> SetRegisterRandom(registers.to_data_register(x), nn)
    <<
      13:4,
      x:4,
      y:4,
      n:4,
    >> -> DisplaySprite(
      registers.to_data_register(x),
      registers.to_data_register(y),
      n,
    )
    <<
      14:4,
      x:4,
      9:4,
      14:4,
    >> -> SkipNextIfKeyPressed(registers.to_data_register(x))
    <<
      14:4,
      x:4,
      10:4,
      1:4,
    >> -> SkipNextIfKeyNotPressed(registers.to_data_register(x))
    <<
      15:4,
      x:4,
      0:4,
      7:4,
    >> -> SetRegisterToDelayTimer(registers.to_data_register(x))
    <<15:4, x:4, 0:4, 10:4>> -> WaitForKeyPress(registers.to_data_register(x))
    <<
      15:4,
      x:4,
      1:4,
      5:4,
    >> -> SetDelayTimerToRegisterValue(registers.to_data_register(x))
    <<
      15:4,
      x:4,
      1:4,
      8:4,
    >> -> SetSoundTimerToRegisterValue(registers.to_data_register(x))
    <<
      15:4,
      x:4,
      1:4,
      14:4,
    >> -> AddToAddressRegister(registers.to_data_register(x))
    <<
      15:4,
      x:4,
      2:4,
      9:4,
    >> -> SetAddressRegisterToSpriteLocation(registers.to_data_register(x))
    <<15:4, x:4, 3:4, 3:4>> -> StoreBcdOfRegister(registers.to_data_register(x))
    <<
      15:4,
      x:4,
      5:4,
      5:4,
    >> -> StoreRegistersAtAddressRegister(registers.to_data_register(x))
    <<
      15:4,
      x:4,
      6:4,
      5:4,
    >> -> ReadRegistersFromAddressRegister(registers.to_data_register(x))
    unknown -> Unknown(unknown)
  }
}

pub fn disassemble(instruction: Instruction) -> String {
  case instruction {
    ExecuteSystemCall(
      address,
    ) -> string.join(["SYS", helpers.int_to_hex_string(address)], with: " ")
    ClearScreen -> "CLS"
    ReturnFromSubroutine -> "RET"
    JumpAbsolute(
      address,
    ) -> string.join(["JP", helpers.int_to_hex_string(address)], with: " ")
    CallSubroutine(
      address,
    ) -> string.join(["CALL", helpers.int_to_hex_string(address)], with: " ")
    SkipNextIfEqualConstant(
      vx,
      value,
    ) -> string.join(
      ["SE", registers.data_register_to_string(vx), int.to_string(value)],
      with: " ",
    )
    SkipNextIfNotEqualConstant(
      vx,
      value,
    ) -> string.join(
      ["SNE", registers.data_register_to_string(vx), int.to_string(value)],
      with: " ",
    )
    SkipNextIfEqualRegisters(
      vx,
      vy,
    ) -> string.join(
      [
        "SE",
        registers.data_register_to_string(vx),
        registers.data_register_to_string(vy),
      ],
      with: " ",
    )
    SetRegisterToConstant(
      vx,
      value,
    ) -> string.join(
      ["LD", registers.data_register_to_string(vx), int.to_string(value)],
      with: " ",
    )
    AddToRegister(
      vx,
      value,
    ) -> string.join(
      ["ADD", registers.data_register_to_string(vx), int.to_string(value)],
      with: " ",
    )
    SetRegisterToRegister(
      vx,
      vy,
    ) -> string.join(
      [
        "LD",
        registers.data_register_to_string(vx),
        registers.data_register_to_string(vy),
      ],
      with: " ",
    )
    SetRegisterOr(
      vx,
      vy,
    ) -> string.join(
      [
        "OR",
        registers.data_register_to_string(vx),
        registers.data_register_to_string(vy),
      ],
      with: " ",
    )
    SetRegisterAnd(
      vx,
      vy,
    ) -> string.join(
      [
        "AND",
        registers.data_register_to_string(vx),
        registers.data_register_to_string(vy),
      ],
      with: " ",
    )
    SetRegisterXor(
      vx,
      vy,
    ) -> string.join(
      [
        "XOR",
        registers.data_register_to_string(vx),
        registers.data_register_to_string(vy),
      ],
      with: " ",
    )
    SetRegisterAdd(
      vx,
      vy,
    ) -> string.join(
      [
        "ADD",
        registers.data_register_to_string(vx),
        registers.data_register_to_string(vy),
      ],
      with: " ",
    )
    SetRegisterSub(
      vx,
      vy,
    ) -> string.join(
      [
        "SUB",
        registers.data_register_to_string(vx),
        registers.data_register_to_string(vy),
      ],
      with: " ",
    )
    SetRegisterShiftRight(
      vx,
      vy,
    ) -> string.join(
      [
        "SHR",
        registers.data_register_to_string(vx),
        registers.data_register_to_string(vy),
      ],
      with: " ",
    )
    SetRegisterSubFlipped(
      vx,
      vy,
    ) -> string.join(
      [
        "SUBN",
        registers.data_register_to_string(vx),
        registers.data_register_to_string(vy),
      ],
      with: " ",
    )
    SetRegisterShiftLeft(
      vx,
      vy,
    ) -> string.join(
      [
        "SHL",
        registers.data_register_to_string(vx),
        registers.data_register_to_string(vy),
      ],
      with: " ",
    )
    SkipNextIfNotEqualRegisters(
      vx,
      vy,
    ) -> string.join(
      [
        "SNE",
        registers.data_register_to_string(vx),
        registers.data_register_to_string(vy),
      ],
      with: " ",
    )
    SetAddressRegisterToConstant(
      address,
    ) -> string.join(["LD", "I", helpers.int_to_hex_string(address)], with: " ")
    JumpRelative(
      offset,
    ) -> string.join(["JP", "V0", helpers.int_to_hex_string(offset)], with: " ")
    SetRegisterRandom(
      vx,
      mask,
    ) -> string.join(
      ["RND", registers.data_register_to_string(vx), int.to_string(mask)],
      with: " ",
    )
    DisplaySprite(
      vx,
      vy,
      length,
    ) -> string.join(
      [
        "DRW",
        registers.data_register_to_string(vx),
        registers.data_register_to_string(vy),
        int.to_string(length),
      ],
      with: " ",
    )
    SkipNextIfKeyPressed(
      vx,
    ) -> string.join(["SKP", registers.data_register_to_string(vx)], with: " ")
    SkipNextIfKeyNotPressed(
      vx,
    ) -> string.join(["SKNP", registers.data_register_to_string(vx)], with: " ")
    SetRegisterToDelayTimer(
      vx,
    ) -> string.join(
      ["LD", registers.data_register_to_string(vx), "DT"],
      with: " ",
    )
    WaitForKeyPress(
      vx,
    ) -> string.join(
      ["LD", registers.data_register_to_string(vx), "K"],
      with: " ",
    )
    SetDelayTimerToRegisterValue(
      vx,
    ) -> string.join(
      ["LD", "DT", registers.data_register_to_string(vx)],
      with: " ",
    )
    SetSoundTimerToRegisterValue(
      vx,
    ) -> string.join(
      ["LD", "ST", registers.data_register_to_string(vx)],
      with: " ",
    )
    AddToAddressRegister(
      vx,
    ) -> string.join(
      ["ADD", "I", registers.data_register_to_string(vx)],
      with: " ",
    )
    SetAddressRegisterToSpriteLocation(
      vx,
    ) -> string.join(
      ["LD", "F", registers.data_register_to_string(vx)],
      with: " ",
    )
    StoreBcdOfRegister(
      vx,
    ) -> string.join(
      ["LD", "B", registers.data_register_to_string(vx)],
      with: " ",
    )
    StoreRegistersAtAddressRegister(
      vx,
    ) -> string.join(
      ["LD", "[I]", registers.data_register_to_string(vx)],
      with: " ",
    )
    ReadRegistersFromAddressRegister(
      vx,
    ) -> string.join(
      ["LD", registers.data_register_to_string(vx), "[I]"],
      with: " ",
    )
    Unknown(_) -> "???"
  }
}
