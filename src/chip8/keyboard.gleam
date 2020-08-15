import gleam/map

pub type KeyCode {
  K0
  K1
  K2
  K3
  K4
  K5
  K6
  K7
  K8
  K9
  KA
  KB
  KC
  KD
  KE
  KF
}

pub type KeyState {
  KeyUp
  KeyDown
}

pub opaque type Keyboard {
  Keyboard(state: map.Map(KeyCode, KeyState))
}

pub fn new() -> Keyboard {
  let state = map.new()
    |> map.insert(K0, KeyUp)
    |> map.insert(K1, KeyUp)
    |> map.insert(K2, KeyUp)
    |> map.insert(K3, KeyUp)
    |> map.insert(K4, KeyUp)
    |> map.insert(K5, KeyUp)
    |> map.insert(K6, KeyUp)
    |> map.insert(K7, KeyUp)
    |> map.insert(K8, KeyUp)
    |> map.insert(K9, KeyUp)
    |> map.insert(KA, KeyUp)
    |> map.insert(KB, KeyUp)
    |> map.insert(KC, KeyUp)
    |> map.insert(KD, KeyUp)
    |> map.insert(KE, KeyUp)
    |> map.insert(KF, KeyUp)

  Keyboard(state: state)
}

pub fn get_key_state(keyboard: Keyboard, key: KeyCode) -> KeyState {
  case map.get(keyboard.state, key) {
    Ok(value) -> value
    Error(Nil) -> KeyUp
  }
}

pub fn handle_key_up(keyboard: Keyboard, key: KeyCode) -> Keyboard {
  Keyboard(state: map.insert(keyboard.state, key, KeyUp))
}

pub fn handle_key_down(keyboard: Keyboard, key: KeyCode) -> Keyboard {
  Keyboard(state: map.insert(keyboard.state, key, KeyDown))
}

pub fn to_key_code(i: Int) -> KeyCode {
  case i {
    0 -> K0
    1 -> K1
    2 -> K2
    3 -> K3
    4 -> K4
    5 -> K5
    6 -> K6
    7 -> K7
    8 -> K8
    9 -> K9
    10 -> KA
    11 -> KB
    12 -> KC
    13 -> KD
    14 -> KE
    15 -> KF
  }
}

pub fn key_code_to_int(key: KeyCode) -> Int {
  case key {
    K0 -> 0
    K1 -> 1
    K2 -> 2
    K3 -> 3
    K4 -> 4
    K5 -> 5
    K6 -> 6
    K7 -> 7
    K8 -> 8
    K9 -> 9
    KA -> 10
    KB -> 11
    KC -> 12
    KD -> 13
    KE -> 14
    KF -> 15
  }
}
