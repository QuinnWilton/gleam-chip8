import gleam/bit_string
import chip8/externals

pub type Memory =
  BitString

pub fn new(size: Int) -> Memory {
  externals.bitstring_copy(<<0>>, size)
}

pub fn put(memory: Memory, position: Int, data: BitString) -> Memory {
  assert Ok(left) = bit_string.part(memory, 0, position)
  assert Ok(
    right,
  ) = bit_string.part(
    memory,
    position + bit_string.byte_size(data),
    bit_string.byte_size(memory) - position - bit_string.byte_size(data),
  )

  left
  |> bit_string.append(data)
  |> bit_string.append(right)
}

pub fn read(
  memory: Memory,
  position: Int,
  length: Int,
) -> Result(BitString, Nil) {
  bit_string.part(memory, position, length)
}
