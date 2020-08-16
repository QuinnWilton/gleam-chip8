import gleam/list
import gleam/bitwise
import chip8/helpers

pub type Sprite =
  List(List(Bool))

pub fn to_sprite(data: BitString) -> Sprite {
  let rows = helpers.bitstring_to_list(data)

  list.map(
    rows,
    fn(row) {
      [
        bitwise.and(row, 128) == 128,
        bitwise.and(row, 64) == 64,
        bitwise.and(row, 32) == 32,
        bitwise.and(row, 16) == 16,
        bitwise.and(row, 8) == 8,
        bitwise.and(row, 4) == 4,
        bitwise.and(row, 2) == 2,
        bitwise.and(row, 1) == 1,
      ]
    },
  )
}
