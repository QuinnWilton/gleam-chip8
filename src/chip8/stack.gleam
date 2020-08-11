pub type Stack(a) =
  List(a)

pub fn new() -> Stack(a) {
  []
}

pub fn push(stack: Stack(a), value: a) -> Stack(a) {
  [value, ..stack]
}

pub fn pop(stack: Stack(a)) -> tuple(Stack(a), a) {
  assert [top, ..rest] = stack

  tuple(rest, top)
}
