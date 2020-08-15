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
  SkipNextIfKeyPressed(value: Int)
  SkipNextIfKeyNotPressed(value: Int)
}

pub fn decode_instruction(instruction: BitString) -> Instruction {
  case instruction {
    <<0:4, nnn:12>> -> ExecuteSystemCall(nnn)
    <<0:4, 0:4, 14:4, 0:4>> -> ClearScreen
    <<0:4, 0:4, 14:4, 14:4>> -> ReturnFromSubroutine
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
    <<14:4, x:4, 9:4, 14:4>> -> SkipNextIfKeyPressed(x)
    <<14:4, x:4, 10:4, 1:4>> -> SkipNextIfKeyNotPressed(x)
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
  }
}
