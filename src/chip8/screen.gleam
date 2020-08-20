import gleam/bit_string
import gleam/bool
import gleam/list
import chip8/helpers
import chip8/sprite

pub type Pixel {
  OnPixel
  OffPixel
  DecayingPixel(lifetime: Float)
}

pub opaque type Screen {
  Screen(width: Int, height: Int, contents: List(List(Pixel)))
}

pub fn new(width: Int, height: Int) -> Screen {
  Screen(
    width: width,
    height: height,
    contents: list.repeat(list.repeat(OffPixel, width), height),
  )
}

pub fn to_list(screen: Screen) -> List(tuple(Int, Int, Float)) {
  let tuple(result, _) =
    list.fold(
      screen.contents,
      tuple([], 0),
      fn(row, acc) {
        let tuple(rows, y) = acc
        let tuple(result, _) =
          list.fold(
            row,
            tuple(rows, 0),
            fn(pixel, acc) {
              let tuple(pixels, x) = acc
              let opacity = case pixel {
                OnPixel -> 1.0
                DecayingPixel(n) -> n *. 0.75
                OffPixel -> 0.0
              }

              tuple([tuple(x, y, opacity), ..pixels], x + 1)
            },
          )

        tuple(result, y + 1)
      },
    )

  result
}

pub fn pixel_on(screen: Screen, x: Int, y: Int) -> Bool {
  let x = x % screen.width
  let y = y % screen.height
  assert Ok(row) = list.at(screen.contents, y)
  assert Ok(pixel) = list.at(row, x)

  case pixel {
    OnPixel -> True
    _ -> False
  }
}

fn update_pixel(pixels: List(Pixel), x: Int) -> List(Pixel) {
  assert [current, ..rest] = pixels

  case x {
    0 -> {
      let new = case current {
        OnPixel -> DecayingPixel(1.0)
        DecayingPixel(_) -> OnPixel
        OffPixel -> OnPixel
      }
      [new, ..rest]
    }
    x -> [current, ..update_pixel(rest, x - 1)]
  }
}

fn update_row(rows: List(List(Pixel)), x: Int, y: Int) -> List(List(Pixel)) {
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
  let tuple(screen, _, collision) =
    list.fold(
      sprite,
      tuple(screen, 0, False),
      fn(row, acc) {
        let tuple(screen, dy, collision) = acc
        let tuple(screen, _, collision) =
          list.fold(
            row,
            tuple(screen, 0, collision),
            fn(pixel, acc) {
              let tuple(screen, dx, collision) = acc
              let collision =
                collision || pixel_on(screen, x + dx, y + dy) && pixel
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

pub fn decay(screen: Screen) -> Screen {
  let contents =
    list.map(
      screen.contents,
      fn(row) {
        list.map(
          row,
          fn(pixel) {
            case pixel {
              OnPixel -> OnPixel
              OffPixel -> OffPixel
              DecayingPixel(n) if n <=. 0.0 -> OffPixel
              DecayingPixel(n) -> DecayingPixel(n -. 0.20)
            }
          },
        )
      },
    )

  Screen(..screen, contents: contents)
}

pub fn clear(screen: Screen) -> Screen {
  new(screen.width, screen.height)
}
