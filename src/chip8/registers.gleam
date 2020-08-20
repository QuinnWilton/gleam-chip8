import gleam/int
import gleam/map

pub type DataRegister {
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
}

pub opaque type RegisterFile {
  RegisterFile(
    address_register: Int,
    delay_timer: Int,
    sound_timer: Int,
    data_registers: map.Map(DataRegister, Int),
  )
}

pub fn new() -> RegisterFile {
  let data_registers =
    map.new()
    |> map.insert(V0, 0)
    |> map.insert(V1, 0)
    |> map.insert(V2, 0)
    |> map.insert(V3, 0)
    |> map.insert(V4, 0)
    |> map.insert(V5, 0)
    |> map.insert(V6, 0)
    |> map.insert(V7, 0)
    |> map.insert(V8, 0)
    |> map.insert(V9, 0)
    |> map.insert(VA, 0)
    |> map.insert(VB, 0)
    |> map.insert(VC, 0)
    |> map.insert(VD, 0)
    |> map.insert(VE, 0)
    |> map.insert(VF, 0)

  RegisterFile(
    address_register: 0,
    delay_timer: 0,
    sound_timer: 0,
    data_registers: data_registers,
  )
}

fn encode_8_bit(value: Int) -> Int {
  let <<x>> = <<value:size(8)>>

  x
}

fn encode_16_bit(value: Int) -> Int {
  let <<x, y>> = <<value:size(16)>>

  x * 256 + y
}

pub fn get_address_register(registers: RegisterFile) -> Int {
  registers.address_register
}

pub fn set_address_register(registers: RegisterFile, value: Int) -> RegisterFile {
  RegisterFile(..registers, address_register: encode_16_bit(value))
}

pub fn get_delay_timer(registers: RegisterFile) -> Int {
  registers.delay_timer
}

pub fn set_delay_timer(registers: RegisterFile, value: Int) -> RegisterFile {
  RegisterFile(..registers, delay_timer: encode_8_bit(value))
}

pub fn get_sound_timer(registers: RegisterFile) -> Int {
  registers.sound_timer
}

pub fn set_sound_timer(registers: RegisterFile, value: Int) -> RegisterFile {
  RegisterFile(..registers, sound_timer: encode_8_bit(value))
}

pub fn get_data_register(registers: RegisterFile, register: DataRegister) -> Int {
  assert Ok(value) = map.get(registers.data_registers, register)

  value
}

pub fn set_data_register(
  registers: RegisterFile,
  register: DataRegister,
  value: Int,
) -> RegisterFile {
  let data_registers =
    map.insert(registers.data_registers, register, encode_8_bit(value))

  RegisterFile(..registers, data_registers: data_registers)
}

pub fn update_address_register(
  registers: RegisterFile,
  f: fn(Int) -> Int,
) -> RegisterFile {
  let old = get_address_register(registers)
  let new = f(old)

  set_address_register(registers, new)
}

pub fn update_data_register(
  registers: RegisterFile,
  register: DataRegister,
  f: fn(Int) -> Int,
) -> RegisterFile {
  let old = get_data_register(registers, register)
  let new = f(old)

  set_data_register(registers, register, new)
}

pub fn decrement_delay_timer(registers: RegisterFile) -> RegisterFile {
  RegisterFile(..registers, delay_timer: int.max(0, registers.delay_timer - 1))
}

pub fn decrement_sound_timer(registers: RegisterFile) -> RegisterFile {
  RegisterFile(..registers, sound_timer: int.max(0, registers.sound_timer - 1))
}

pub fn to_data_register(i: Int) -> DataRegister {
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

pub fn data_register_to_string(register: DataRegister) -> String {
  case register {
    V0 -> "V0"
    V1 -> "V1"
    V2 -> "V2"
    V3 -> "V3"
    V4 -> "V4"
    V5 -> "V5"
    V6 -> "V6"
    V7 -> "V7"
    V8 -> "V8"
    V9 -> "V9"
    VA -> "VA"
    VB -> "VB"
    VC -> "VC"
    VD -> "VD"
    VE -> "VE"
    VF -> "VF"
  }
}

pub fn list_v() -> List(DataRegister) {
  [V0, V1, V2, V3, V4, V5, V6, V7, V8, V9, VA, VB, VC, VD, VE, VF]
}
