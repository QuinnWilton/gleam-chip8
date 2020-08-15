import gleam/bit_string
import chip8/externals

pub opaque type Memory {
  Memory(data: BitString)
}

pub fn new(size: Int) -> Memory {
  Memory(data: externals.bitstring_copy(<<0>>, size))
}

pub fn put(memory: Memory, position: Int, data: BitString) -> Memory {
  assert Ok(left) = bit_string.part(memory.data, 0, position)
  assert Ok(
    right,
  ) = bit_string.part(
    memory.data,
    position + bit_string.byte_size(data),
    bit_string.byte_size(memory.data) - position - bit_string.byte_size(data),
  )

  let data = left
    |> bit_string.append(data)
    |> bit_string.append(right)

  Memory(data: data)
}

pub fn read(
  memory: Memory,
  position: Int,
  length: Int,
) -> Result(BitString, Nil) {
  let position = position % bit_string.byte_size(memory.data)
  bit_string.part(memory.data, position, length)
}
