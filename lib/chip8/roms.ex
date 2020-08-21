defmodule Chip8.ROMs do
  @default_keybinds %{
    "1" => :k0,
    "x" => :k1,
    "2" => :k2,
    "3" => :k3,
    "q" => :k4,
    "w" => :k5,
    "e" => :k6,
    "a" => :k7,
    "s" => :k8,
    "d" => :k9,
    "z" => :ka,
    "c" => :kb,
    "4" => :kc,
    "r" => :kd,
    "f" => :ke,
    "v" => :kf
  }

  @roms [
    %{
      name: "BLINKY",
      data: File.read!(Path.join("priv/roms/", "BLINKY")),
      description: "Pacman! Avoid the ghosts, and eat the dots. Move using the arrow keys.",
      keybinds: %{
        "ArrowLeft" => :k7,
        "ArrowRight" => :k8,
        "ArrowUp" => :k3,
        "ArrowDown" => :k6
      }
    },
    %{
      name: "BRIX",
      data: File.read!(Path.join("priv/roms/", "BRIX")),
      description: "Breakout! Use the left and right arrow keys to move the paddle.",
      keybinds: %{
        "ArrowLeft" => :k4,
        "ArrowRight" => :k6
      }
    },
    %{
      name: "CONNECT4",
      data: File.read!(Path.join("priv/roms/", "CONNECT4")),
      description:
        "Take turns placing game pieces to try to get 4 in a row! Use the left and right arrow keys to choose a position, and then spacebar to drop your piece. Note that this game does not automatically detect the winner.",
      keybinds: %{
        "ArrowLeft" => :k4,
        "ArrowRight" => :k6,
        " " => :k5
      }
    },
    %{
      name: "HIDDEN",
      data: File.read!(Path.join("priv/roms/", "HIDDEN")),
      description:
        "I don't know what this game is. It doesn't seem to work properly, but you can use the arrow keys to move the cursor, and space to select a card.",
      keybinds: %{
        "ArrowLeft" => :k4,
        "ArrowRight" => :k6,
        "ArrowUp" => :k2,
        "ArrowDown" => :k8,
        " " => :k5
      }
    },
    %{
      name: "INVADERS",
      data: File.read!(Path.join("priv/roms/", "INVADERS")),
      description:
        "Space Invaders! Try to shoot the approaching aliens before they reach the bottom of the screen. Use the left and right arrow keys to move, and the spacebar to shoot.",
      keybinds: %{
        "ArrowLeft" => :k4,
        "ArrowRight" => :k6,
        " " => :k5
      }
    },
    %{
      name: "KALEID",
      data: File.read!(Path.join("priv/roms/", "KALEID")),
      description:
        "Press two buttons to seed a random pattern generator! Available buttons are: 1, 2, 3, 4, Q, W, E, R, A, S, D, F, Z, X, C, V",
      keybinds: @default_keybinds
    },
    %{
      name: "MAZE",
      data: File.read!(Path.join("priv/roms/", "MAZE")),
      description: "It just generates a maze!",
      keybinds: @default_keybinds
    },
    %{
      name: "MERLIN",
      data: File.read!(Path.join("priv/roms/", "MERLIN")),
      description: "Simon says! Use Q, W, A, S to match the pattern.",
      keybinds: %{
        "q" => :k4,
        "w" => :k5,
        "a" => :k7,
        "s" => :k8
      }
    },
    %{
      name: "PONG",
      data: File.read!(Path.join("priv/roms/", "PONG")),
      description: "It's Pong! Left player uses Q and A, right player uses Up and Down Arrows.",
      keybinds: %{
        "q" => :k1,
        "a" => :k4,
        "ArrowUp" => :kc,
        "ArrowDown" => :kd
      }
    },
    %{
      name: "PONG2",
      data: File.read!(Path.join("priv/roms/", "PONG2")),
      description:
        "It's Pong! Again! Left player uses Q and A, right player uses Up and Down Arrows.",
      keybinds: %{
        "q" => :k1,
        "a" => :k4,
        "ArrowUp" => :kc,
        "ArrowDown" => :kd
      }
    },
    %{
      name: "PUZZLE",
      data: File.read!(Path.join("priv/roms/", "PUZZLE")),
      description: "Solve the puzzle! Use the arrow keys to move the tiles.",
      keybinds: %{
        "ArrowUp" => :k2,
        "ArrowRight" => :k4,
        "ArrowDown" => :k8,
        "ArrowLeft" => :k6
      }
    },
    %{
      name: "TETRIS",
      data: File.read!(Path.join("priv/roms/", "TETRIS")),
      description: "It's Tetris. Arrows keys to move, space to rotate.",
      keybinds: %{
        "ArrowRight" => :k6,
        "ArrowDown" => :k7,
        "ArrowLeft" => :k5,
        " " => :k4
      }
    },
    %{
      name: "TICTAC",
      data: File.read!(Path.join("priv/roms/", "TICTAC")),
      description:
        "Tic. Tac. Toe. Use Q, W, E, A, S, D, Z, X, C to place a piece in the respective position.",
      keybinds: %{
        "q" => :k1,
        "w" => :k2,
        "e" => :k3,
        "a" => :k4,
        "s" => :k5,
        "d" => :k6,
        "z" => :k7,
        "x" => :k8,
        "c" => :k9
      }
    }
  ]

  def list_roms do
    @roms
  end

  def get_rom(name) when is_binary(name) do
    Enum.find(list_roms(), &(&1.name == name))
  end

  def translate_keybinds(rom, key) when is_binary(key) do
    Map.get(rom.keybinds, key)
  end
end
