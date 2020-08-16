import gleam/bit_string
import gleam/bool
import gleam/list
import chip8/helpers
import chip8/sprite

pub opaque type Screen {
  Screen(width: Int, height: Int, contents: List(List(Bool)))
}

pub fn new(width: Int, height: Int) -> Screen {
  Screen(
    width: width,
    height: height,
    contents: list.repeat(list.repeat(False, width), height),
  )
}

pub fn to_list(screen: Screen) -> List(List(Bool)) {
  screen.contents
}

pub fn get_pixel(screen: Screen, x: Int, y: Int) -> Bool {
  let x = x % screen.width
  let y = y % screen.height
  assert Ok(row) = list.at(screen.contents, y)
  assert Ok(pixel) = list.at(row, x)

  pixel
}

fn update_pixel(pixels: List(Bool), x: Int) -> List(Bool) {
  assert [current, ..rest] = pixels
  case x {
    0 -> [bool.negate(current), ..rest]
    x -> [current, ..update_pixel(rest, x - 1)]
  }
}

fn update_row(rows: List(List(Bool)), x: Int, y: Int) -> List(List(Bool)) {
  assert [current, ..rest] = rows
  case y {
    0 -> [update_pixel(current, x), ..rest]
    y -> [current, ..update_row(rest, x, y - 1)]
  }
}

pub fn toggle_pixel(screen: Screen, x: Int, y: Int) -> Screen {
  let x = x % screen.width
  let y = y % screen.height
  Screen(..screen, contents: update_row(screen.contents, x, y))
}

pub fn draw_sprite(
  screen: Screen,
  sprite: sprite.Sprite,
  x: Int,
  y: Int,
) -> tuple(Screen, Bool) {
  let tuple(
    screen,
    _,
    collision,
  ) = list.fold(
    sprite,
    tuple(screen, 0, False),
    fn(row, acc) {
      let tuple(screen, dy, collision) = acc
      let tuple(
        screen,
        _,
        collision,
      ) = list.fold(
        row,
        tuple(screen, 0, collision),
        fn(pixel, acc) {
          let tuple(screen, dx, collision) = acc
          let collision = collision || get_pixel(
              screen,
              x + dx,
              y + dy,
            ) && pixel
          let screen = case pixel {
            False -> screen
            True -> toggle_pixel(screen, x + dx, y + dy)
          }
          tuple(screen, dx + 1, collision)
        },
      )
      tuple(screen, dy + 1, collision)
    },
  )

  tuple(screen, collision)
}

pub fn clear(screen: Screen) -> Screen {
  new(screen.width, screen.height)
}
