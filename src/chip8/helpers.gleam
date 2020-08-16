import gleam/int
import gleam/string

pub external fn bitstring_copy(subject: BitString, n: Int) -> BitString =
  "binary" "copy"

pub external fn bitstring_to_list(subject: BitString) -> List(Int) =
  "binary" "bin_to_list"

pub external fn rand_uniform(n: Int) -> Int =
  "rand" "uniform"

pub fn int_to_hex_string(n: Int) -> String {
  string.append("0x", int.to_base_string(n, 16))
}
