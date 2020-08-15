import chip8/registers

pub type Instruction {
  ExecuteSystemCall(address: Int)
  ClearScreen
  ReturnFromSubroutine
  JumpAbsolute(address: Int)
  JumpRelative(offset: Int)
  CallSubroutine(address: Int)
  SkipNextIfEqualConstant(vx: registers.Register, value: Int)
  SkipNextIfEqualRegisters(vx: registers.Register, vy: registers.Register)
  SkipNextIfNotEqualConstant(vx: registers.Register, value: Int)
  SkipNextIfNotEqualRegisters(vx: registers.Register, vy: registers.Register)
  SetRegisterToConstant(vx: registers.Register, value: Int)
  SetRegisterToRegister(vx: registers.Register, vy: registers.Register)
  SetAddressRegisterToConstant(address: Int)
  SetRegisterToDelayTimer(vx: registers.Register)
  WaitForKeyPress(vx: registers.Register)
  SetDelayTimerToRegisterValue(vx: registers.Register)
  SetSoundTimerToRegisterValue(vx: registers.Register)
  SetAddressRegisterToSpriteLocation(vx: registers.Register)
  StoreBcdOfRegister(vx: registers.Register)
  StoreRegistersAtAddressRegister(vx: registers.Register)
  ReadRegistersFromAddressRegister(vx: registers.Register)
  AddToRegister(vx: registers.Register, value: Int)
  SetRegisterAdd(vx: registers.Register, vy: registers.Register)
  AddToAddressRegister(vx: registers.Register)
  SetRegisterOr(vx: registers.Register, vy: registers.Register)
  SetRegisterAnd(vx: registers.Register, vy: registers.Register)
  SetRegisterXor(vx: registers.Register, vy: registers.Register)
  SetRegisterShiftRight(vx: registers.Register, vy: registers.Register)
  SetRegisterShiftLeft(vx: registers.Register, vy: registers.Register)
  SetRegisterSub(vx: registers.Register, vy: registers.Register)
  SetRegisterSubFlipped(vx: registers.Register, vy: registers.Register)
  SetRegisterRandom(vx: registers.Register, value: Int)
  DisplaySprite(vx: registers.Register, vy: registers.Register, length: Int)
  SkipNextIfKeyPressed(value: Int)
  SkipNextIfKeyNotPressed(value: Int)
}

pub fn decode_instruction(instruction: BitString) -> Instruction {
  case instruction {
    <<0:4, nnn:12>> -> ExecuteSystemCall(address: nnn)
    <<0:4, 0:4, 14:4, 0:4>> -> ClearScreen
    <<0:4, 0:4, 14:4, 14:4>> -> ReturnFromSubroutine
    <<1:4, nnn:12>> -> JumpAbsolute(address: nnn)
    <<2:4, nnn:12>> -> CallSubroutine(address: nnn)
    <<
      3:4,
      x:4,
      kk:8,
    >> -> SkipNextIfEqualConstant(vx: registers.to_register(x), value: kk)
    <<
      4:4,
      x:4,
      kk:8,
    >> -> SkipNextIfNotEqualConstant(vx: registers.to_register(x), value: kk)
    <<
      5:4,
      x:4,
      y:4,
      0:4,
    >> -> SkipNextIfEqualRegisters(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<
      6:4,
      x:4,
      kk:8,
    >> -> SetRegisterToConstant(vx: registers.to_register(x), value: kk)
    <<7:4, x:4, kk:8>> -> AddToRegister(vx: registers.to_register(x), value: kk)
    <<
      8:4,
      x:4,
      y:4,
      0:4,
    >> -> SetRegisterToRegister(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      1:4,
    >> -> SetRegisterOr(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      2:4,
    >> -> SetRegisterAnd(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      3:4,
    >> -> SetRegisterXor(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      4:4,
    >> -> SetRegisterAdd(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      5:4,
    >> -> SetRegisterSub(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      6:4,
    >> -> SetRegisterShiftRight(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      7:4,
    >> -> SetRegisterSubFlipped(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<
      8:4,
      x:4,
      y:4,
      14:4,
    >> -> SetRegisterShiftLeft(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<
      9:4,
      x:4,
      y:4,
      0:4,
    >> -> SkipNextIfEqualRegisters(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
    )
    <<10:4, nnn:12>> -> SetAddressRegisterToConstant(address: nnn)
    <<11:4, nnn:12>> -> JumpRelative(offset: nnn)
    <<
      12:4,
      x:4,
      nn:8,
    >> -> SetRegisterRandom(vx: registers.to_register(x), value: nn)
    <<
      13:4,
      x:4,
      y:4,
      n:4,
    >> -> DisplaySprite(
      vx: registers.to_register(x),
      vy: registers.to_register(y),
      length: n,
    )
    <<14:4, x:4, 9:4, 14:4>> -> SkipNextIfKeyPressed(value: x)
    <<14:4, x:4, 10:4, 1:4>> -> SkipNextIfKeyNotPressed(value: x)
    <<
      15:4,
      x:4,
      0:4,
      7:4,
    >> -> SetRegisterToDelayTimer(vx: registers.to_register(x))
    <<15:4, x:4, 0:4, 10:4>> -> WaitForKeyPress(vx: registers.to_register(x))
    <<
      15:4,
      x:4,
      1:4,
      5:4,
    >> -> SetDelayTimerToRegisterValue(vx: registers.to_register(x))
    <<
      15:4,
      x:4,
      1:4,
      8:4,
    >> -> SetSoundTimerToRegisterValue(vx: registers.to_register(x))
    <<
      15:4,
      x:4,
      1:4,
      14:4,
    >> -> AddToAddressRegister(vx: registers.to_register(x))
    <<
      15:4,
      x:4,
      2:4,
      9:4,
    >> -> SetAddressRegisterToSpriteLocation(vx: registers.to_register(x))
    <<15:4, x:4, 3:4, 3:4>> -> StoreBcdOfRegister(vx: registers.to_register(x))
    <<
      15:4,
      x:4,
      5:4,
      5:4,
    >> -> StoreRegistersAtAddressRegister(vx: registers.to_register(x))
    <<
      15:4,
      x:4,
      6:4,
      5:4,
    >> -> ReadRegistersFromAddressRegister(vx: registers.to_register(x))
  }
}
