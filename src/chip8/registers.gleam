import gleam/map

pub type RegisterSize {
  Register8
  Register16
}

pub type Register {
  V0
  V1
  V2
  V3
  V4
  V5
  V6
  V7
  V8
  V9
  VA
  VB
  VC
  VD
  VE
  VF
  I
  DT
  ST
}

pub type RegisterFile =
  map.Map(Register, Int)

pub fn new() -> RegisterFile {
  map.new()
}

fn register_size(register: Register) -> RegisterSize {
  case register {
    V0 -> Register8
    V1 -> Register8
    V2 -> Register8
    V3 -> Register8
    V4 -> Register8
    V5 -> Register8
    V6 -> Register8
    V7 -> Register8
    V8 -> Register8
    V9 -> Register8
    VA -> Register8
    VB -> Register8
    VC -> Register8
    VD -> Register8
    VE -> Register8
    VF -> Register8
    I -> Register16
    DT -> Register8
    ST -> Register8
  }
}

fn encode_register_value(register: Register, value: Int) -> Int {
  case register_size(register) {
    Register8 -> {
      let <<x>> = <<value:size(8)>>
      x
    }
    Register16 -> {
      let <<x, y>> = <<value:size(16)>>
      x * 256 + y
    }
  }
}

pub fn read(register_file: RegisterFile, register: Register) -> Int {
  case map.get(register_file, register) {
    Ok(value) -> value
    Error(Nil) -> 0
  }
}

pub fn write(
  register_file: RegisterFile,
  register: Register,
  value: Int,
) -> RegisterFile {
  let value = encode_register_value(register, value)

  map.insert(register_file, register, value)
}

pub fn update(
  register_file: RegisterFile,
  register: Register,
  f: fn(Int) -> Int,
) -> RegisterFile {
  let old = read(register_file, register)
  let new = f(old)

  write(register_file, register, new)
}

pub fn to_register(i: Int) -> Register {
  case i {
    0 -> V0
    1 -> V1
    2 -> V2
    3 -> V3
    4 -> V4
    5 -> V5
    6 -> V6
    7 -> V7
    8 -> V8
    9 -> V9
    10 -> VA
    11 -> VB
    12 -> VC
    13 -> VD
    14 -> VE
    15 -> VF
  }
}
