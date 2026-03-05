package main

import "vendor:sdl2"
import "vendor:raylib"

KeyMap :: struct {
  key: raylib.KeyboardKey,
  hasKey2: bool,
  key2: raylib.KeyboardKey,
  hasKey3: bool,
  key3: raylib.KeyboardKey,
  gamepad: sdl2.GameControllerButton,
  canCollide: bool,
  positionModifier: [2]int,
  callback: proc(^Piece)
}

mappings :: []KeyMap {
  {
    key = .R,
    gamepad = .BACK,
    callback = proc(ref: ^Piece) {
      reset()
    }
  },
  {
    key = .E,
    key2 = .UP,
    key3 = .W,
    gamepad = .A,
    hasKey2 = true,
    hasKey3 = true,
    canCollide = true,
    callback = proc(ref: ^Piece) {
      rotate(ref, true)
    }
  },
  {
    key = .Q,
    gamepad = .B,
    canCollide = true,
    callback = proc(ref: ^Piece) {
      rotate(ref, false)
    }
  },
  {
    key = .DOWN,
    key2 = .S,
    gamepad = .DPAD_DOWN,
    hasKey2 = true,
    canCollide = true,
    callback = proc(ref: ^Piece) {
      ref.pos[1] += 1
    }
  },
  {
    key = .RIGHT,
    key2 = .D,
    gamepad = .DPAD_RIGHT,
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
    gamepad = .DPAD_LEFT,
    canCollide = true,
    callback = proc(ref: ^Piece) {
      ref.pos[0] -= 1
    }
  },
  {
    key = .SPACE,
    gamepad = .DPAD_UP,
    callback = proc(ref: ^Piece) {
      hard_drop(ref)
    }
  },
  {
    key = .ESCAPE,
    gamepad = .START,
    callback = proc(ref: ^Piece) {
      paused = !paused
    }
  }
  /*{
    key = .P,
    callback = proc(ref: ^Piece) {
      board[19] = { 0..<10 = 7 }
      lines = 300
      check_needed = true
    }
  }*/
}
