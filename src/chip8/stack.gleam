import gleam/list
import chip8/memory

pub opaque type Stack {
  Stack(sp: Int, contents: memory.Memory)
}

pub fn new() -> Stack {
  Stack(sp: 0, contents: memory.new(32))
}

pub fn push(stack: Stack, value: Int) -> Stack {
  Stack(
    sp: stack.sp + 2,
    contents: memory.put(stack.contents, stack.sp, <<value:size(16)>>),
  )
}

pub fn pop(stack: Stack) -> tuple(Stack, Int) {
  assert Ok(<<value:size(16)>>) = memory.read(stack.contents, stack.sp - 2, 2)

  tuple(Stack(..stack, sp: stack.sp - 2), value)
}

pub fn to_list(stack: Stack) -> List(tuple(Int, Int)) {
  list.range(0, 16)
  |> list.map(
    fn(n) {
      let address = n * 2
      assert Ok(<<value:size(16)>>) = memory.read(stack.contents, address, 2)

      tuple(address, value)
    },
  )
}
