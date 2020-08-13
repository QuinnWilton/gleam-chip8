import chip8/registers

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

pub fn decode_instruction(instruction: BitString) -> Instruction {
  case instruction {
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
