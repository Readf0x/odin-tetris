package main

import "vendor:raylib"

KeyMap :: struct {
  key: raylib.KeyboardKey,
  hasKey2: bool,
  key2: raylib.KeyboardKey,
  hasKey3: bool,
  key3: raylib.KeyboardKey,
  canCollide: bool,
  positionModifier: [2]int,
  callback: proc(^Piece)
}

mappings :: []KeyMap {
  {
    key = .R,
    callback = proc(ref: ^Piece) {
      reset()
    }
  },
  {
    key = .E,
    key2 = .UP,
    key3 = .W,
    hasKey2 = true,
    hasKey3 = true,
    canCollide = true,
    callback = proc(ref: ^Piece) {
      rotate(ref, true)
    }
  },
  {
    key = .Q,
    canCollide = true,
    callback = proc(ref: ^Piece) {
      rotate(ref, false)
    }
  },
  {
    key = .DOWN,
    key2 = .S,
    hasKey2 = true,
    canCollide = true,
    callback = proc(ref: ^Piece) {
      ref.pos[1] += 1
    }
  },
  {
    key = .RIGHT,
    key2 = .D,
    hasKey2 = true,
    canCollide = true,
    callback = proc(ref: ^Piece) {
      ref.pos[0] += 1
    }
  },
  {
    key = .LEFT,
    key2 = .A,
    hasKey2 = true,
    canCollide = true,
    callback = proc(ref: ^Piece) {
      ref.pos[0] -= 1
    }
  },
  {
    key = .SPACE,
    callback = proc(ref: ^Piece) {
      hard_drop(ref)
    }
  },
  /*{
    key = .P,
    callback = proc(ref: ^Piece) {
      board[19] = { 0..<10 = 7 }
      lines = 300
      check_needed = true
    }
  }*/
}
