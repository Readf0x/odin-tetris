#+feature using-stmt
package main

import "vendor:sdl2"
import "core:math"
import "core:slice"
import "core:fmt"
import "base:intrinsics"
import "core:math/rand"
import "vendor:raylib"

i32_Vector2 :: [2]i32
res : i32_Vector2 : {400, 600}
max_fps :: 30
block_size : i32 : 20
block_pad : i32 : 4

board_size : i32_Vector2 : {
  (block_size * 10) + (block_pad * 9),
  (block_size * 20) + (block_pad * 19),
}
board_offset : i32_Vector2 : {
  (res.x - board_size.x) / 2,
  (res.y - board_size.y) / 2,
}
board_edges : i32_Vector2 : {
  board_size.x + board_offset.x,
  board_size.y + board_offset.y,
}

score_values := [4]int{ 4, 10, 30, 120 }

board : [20][10]u8
active_piece : Piece
next_piece : Piece

score : int
level : int
lines : int
drop_speed : u8 = 30

paused : bool
check_needed : bool
tick_should_reset : bool

main :: proc() {
  using raylib

  InitWindow(res.x, res.y, "Tetris")
  defer CloseWindow()
  SetTargetFPS(max_fps)
  SetExitKey(.KEY_NULL)

  gamepad : ^sdl2.GameController
  event : sdl2.Event = {}
  sdl_init := sdl2.Init({ .GAMECONTROLLER, .JOYSTICK, .EVENTS })
  if sdl_init < 0 {
    for i in 0..<sdl2.NumJoysticks() do if sdl2.IsGameController(i) {
      gamepad = sdl2.GameControllerOpen(i)
    }
  }
  defer if sdl_init < 0 do sdl2.Quit()

  next_piece = pieces[rand.choice_enum(PieceID)]
  new_piece()

  frozen : bool

  stored_lines := make([dynamic][10]u8, 0, 4)
  to_clear := make([dynamic]int, 0, 4)
  tick_frames : u8
  animated_frames : u16

  game_over : bool
  game_over_anim_line : int

  for !WindowShouldClose() {
    for sdl2.PollEvent(&event) {
      #partial switch event.type {
      case .CONTROLLERDEVICEADDED:
        gamepad = sdl2.GameControllerOpen(event.cdevice.which)
      case .CONTROLLERDEVICEREMOVED:
        if sdl2.JoystickID(event.cdevice.which) == sdl2.JoystickInstanceID(sdl2.GameControllerGetJoystick(gamepad)) {
          sdl2.GameControllerClose(gamepad)
        }
      case .CONTROLLERBUTTONDOWN:
        if !frozen do for m in mappings {
          if sdl2.GameControllerButton(event.cbutton.button) == m.gamepad {
            handle_keymap(m)
          }
        }
      }
    }
    if !frozen do for m in mappings {
      if IsKeyPressed(m.key) || IsKeyPressedRepeat(m.key) \
      || (false if !m.hasKey2 else IsKeyPressed(m.key2) || IsKeyPressedRepeat(m.key2)) \
      || (false if !m.hasKey3 else IsKeyPressed(m.key3) || IsKeyPressedRepeat(m.key3)) \
      { handle_keymap(m) }
    }

    if tick_should_reset do tick_frames = 0

    if check_needed {
      for j in 0..<20 {
        if game_over {
          break
        }
        for i in 0..<10 {
          color := board[j][i]
          if j == 0 {
            if color != 0 {
              frozen = true
              game_over = true
              break
            }
          } else {
            if color == 0 do break
            else if i == 9 do append(&to_clear, j)
          }
        }
      }
      check_needed = false
    }

    // line clear anim
    if len(to_clear) > 0 {
      if animated_frames == 0 {
        frozen = true
        for line in to_clear {
          append(&stored_lines, board[line])
        }
      }
      if animated_frames > 30 {
        defer {
          clear(&to_clear)
          clear(&stored_lines)
        }
        tmp_board : [20][10]u8
        skipped : int
        for i := 19; i >= 0; i -= 1 {
          if slice.contains(to_clear[:], i) {
            skipped += 1
            continue
          }
          tmp_board[i+skipped] = board[i]
        }
        lines += len(to_clear)
        score += score_values[len(to_clear)-1] * (level+1)
        level = lines / 10
        drop_speed = cast (u8) math.max(1, 30 - level)
        board = tmp_board
        animated_frames = 0
        frozen = false
      } else {
        animated_frames += 1
        if animated_frames % 5 == 0 {
          if board[to_clear[0]][0] == 8 {
            for _, i in to_clear {
              board[to_clear[i]] = stored_lines[i]
            }
          } else {
            for line in to_clear {
              board[line] = { 0..<10 = 8 }
            }
          }
        } 
      }
    }

    //game over anim
    if game_over {
      if animated_frames % 5 == 0 {
        if game_over_anim_line == 20 {
          reset()
          frozen = false
          game_over = false
        } else {
          board[game_over_anim_line] = { 0..<10 = 8 }
          game_over_anim_line += 1
        }
      }
      animated_frames += 1
    }

    // drop tick
    if !frozen && !paused {
      tick_frames += 1
      if tick_frames >= drop_speed {
        tick_frames = 0
        tmp_piece := active_piece
        tmp_piece.pos.y += 1
        if check_collision(&tmp_piece) {
          place_piece(&active_piece)
        } else {
          active_piece.pos.y += 1
        }
      }
    }

    BeginDrawing()

      ClearBackground(bg0)
      for j in 0..<20 do for i in 0..<10 {
        color := board[j][i]
        raylib.DrawRectangle(
          i32(i)*(block_size+block_pad) + board_offset.x,
          i32(j)*(block_size+block_pad) + board_offset.y,
          block_size,
          block_size,
          colors[color]
        )
      }
      draw_ghost(&next_piece, board_edges.x + block_pad, board_offset.y)
      DrawText(
        "Score:",
        board_edges.x + block_pad,
        board_offset.y + (block_size * i32(next_piece.size)) + (block_pad * i32(next_piece.size - 1)),
        20,
        fg,
      )
      DrawText(
        fmt.caprintf("%4d0", score),
        board_edges.x + block_pad,
        board_offset.y + (block_size * i32(next_piece.size)) + (block_pad * i32(next_piece.size - 1)) + 20,
        20,
        fg,
      )
      DrawText(
        "Lines:",
        board_edges.x + block_pad,
        board_offset.y + (block_size * i32(next_piece.size)) + (block_pad * i32(next_piece.size - 1)) + 40,
        20,
        fg,
      )
      DrawText(
        fmt.caprintf("%3d", lines),
        board_edges.x + block_pad,
        board_offset.y + (block_size * i32(next_piece.size)) + (block_pad * i32(next_piece.size - 1)) + 60,
        20,
        fg,
      )
      DrawText(
        "Level:",
        board_edges.x + block_pad,
        board_offset.y + (block_size * i32(next_piece.size)) + (block_pad * i32(next_piece.size - 1)) + 80,
        20,
        fg,
      )
      DrawText(
        fmt.caprintf("%2d", level),
        board_edges.x + block_pad,
        board_offset.y + (block_size * i32(next_piece.size)) + (block_pad * i32(next_piece.size - 1)) + 100,
        20,
        fg,
      )
      if !frozen do draw_piece(&active_piece)

      if paused {
        DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), { bg_dim.r, bg_dim.g, bg_dim.b, 0x50 })
      }

    EndDrawing()
  }
}

reset :: proc() {
  board = [20][10]u8{}
  new_piece()
  score = 0
  level = 0
  lines = 0
  drop_speed = 30
}

draw_piece :: proc(ref: ^Piece) {
  for i in 0..<ref.size do for j in 0..<ref.size {
    color := ref.data[j, i]
    if color != 0 {
      raylib.DrawRectangle(
        i32(i+ref.pos.x)*(block_size+block_pad) + board_offset.x,
        i32(j+ref.pos.y)*(block_size+block_pad) + board_offset.y,
        block_size,
        block_size,
        colors[color]
      )
    }
  }
}

draw_ghost :: proc(ref: ^Piece, x, y: i32, size : i32 = block_size, pad : i32 = block_pad) {
  for i in 0..<ref.size do for j in 0..<ref.size {
    color := ref.data[j, i]
    if color != 0 {
      raylib.DrawRectangle(
        i32(i)*(size+pad) + x,
        i32(j)*(size+pad) + y,
        size,
        size,
        colors[color]
      )
    }
  }
}

new_piece :: proc() {
  active_piece = next_piece
  next_piece = pieces[rand.choice_enum(PieceID)]
}

check_collision :: proc(ref: ^Piece) -> bool {
  for i in 0..<ref.size do for j in 0..<ref.size {
    color := ref.data[j, i]
    x, y := ref.pos.x+i, ref.pos.y+j
    if color != 0 {
      if x < 0 || x > 9 \
      || y < 0 || y > 19 \
      || board[y][x] != 0
      {
        return true
      }
    }
  }
  return false
}

place_piece :: proc(ref: ^Piece) {
  for i in 0..<ref.size do for j in 0..<ref.size {
    color := ref.data[j, i]
    if color != 0 {
      y := ref.pos.y+j
      if y < 20 do board[ref.pos.y+j][ref.pos.x+i] = color
    }
  }
  check_needed = true
  new_piece()
}

mask_bottommost :: proc(ref: ^Piece) -> Piece {
  mask : Piece
  for i in 0..<ref.size do for j in 0..<ref.size {
    if j == ref.size - 1 || ref.data[j+1, i] == 0 {
      mask.data[j, i] = ref.data[j, i]
    }
  }
  return mask
}

hard_drop :: proc(ref: ^Piece) {
  mask := mask_bottommost(ref)
  distance: int
  found: bool
  for i in 0..<ref.size do for j in 0..<ref.size {
    color := mask.data[j, i]
    if color != 0 && ref.pos.y+j == 19 do found = true
  }
  for !found {
    distance += 1
    for i in 0..<ref.size do for j in 0..<ref.size {
      color := mask.data[j, i]
      y := ref.pos.y+j+distance+1
      if color != 0 {
        if y >= 20 || board[y][ref.pos.x+i] != 0 {
          found = true
          break
        }
      }
    }
  }
  ref.pos.y += distance
  place_piece(ref)
}

rotate :: proc(ref: ^Piece, direction: bool) {
  switch ref.size {
  case 3:
    transpose :: proc(ref: ^Piece) {
      ref.data = cast (matrix[4,4]u8) intrinsics.transpose((matrix[3,3]u8)(ref.data))
    }
    if direction do transpose(ref)
    for i in 0..<3 {
      ref.data[i, 0] ~= ref.data[i, 2]
      ref.data[i, 2] ~= ref.data[i, 0]
      ref.data[i, 0] ~= ref.data[i, 2]
    }
    if !direction do transpose(ref)
  case 4:
    transpose :: proc(ref: ^Piece) { ref.data = intrinsics.transpose(ref.data) }
    if direction do transpose(ref)
    for i in 0..<4 do for j in 0..<2 {
      ref.data[i, j] ~= ref.data[i, 3-j]
      ref.data[i, 3-j] ~= ref.data[i, j]
      ref.data[i, j] ~= ref.data[i, 3-j]
    }
    if !direction do transpose(ref)
  }
}

handle_keymap :: proc(m: KeyMap) {
  if !m.canCollide {
    m.callback(&active_piece)
  } else {
    tmp_piece := active_piece
    m.callback(&tmp_piece)
    if !check_collision(&tmp_piece) {
      m.callback(&active_piece)
    }
  }
}

