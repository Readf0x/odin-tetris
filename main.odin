#+feature using-stmt
package main

import "core:slice"
import "core:fmt"
import "base:intrinsics"
import "core:math/rand"
import "vendor:raylib"

res : struct { x: i32, y: i32 } : {800, 600}
max_fps :: 30
block_size :: 20
block_pad :: 4

board : [20][10]u8

score : int
check_needed : bool

main :: proc() {
  using raylib

  InitWindow(res.x, res.y, "Tetris")
  SetTargetFPS(max_fps)

  active_piece : Piece
  new_piece(&active_piece)

  frozen : bool

  stored_lines := make([dynamic][10]u8, 0, 4)
  to_clear := make([dynamic]int, 0, 4)
  animated_frames : i32
  for !WindowShouldClose() {

    if !frozen {
      for m in mappings {
        if IsKeyPressed(m.key) || IsKeyPressedRepeat(m.key) ||
          (false if !m.hasKey2 else IsKeyPressed(m.key2) || IsKeyPressedRepeat(m.key2)) ||
          (false if !m.hasKey3 else IsKeyPressed(m.key3) || IsKeyPressedRepeat(m.key3))
        {
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
      }
    }

    exit_early : bool
    if check_needed {
      for j in 0..<20 {
        if exit_early {
          exit_early = false
          break
        }
        for i in 0..<10 {
          color := board[j][i]
          if j == 0 {
            if color != 0 {
              reset(&active_piece)
              exit_early = true
            }
            break
          } else {
            if color == 0 do break
            else if i == 9 do append(&to_clear, j)
          }
        }
      }
      check_needed = false
    }
    if len(to_clear) > 0 && animated_frames == 0 {
      frozen = true
      for line in to_clear {
        append(&stored_lines, board[line])
      }
    }
    if len(to_clear) > 0 && animated_frames > 30 {
      defer clear(&to_clear)
      defer clear(&stored_lines)
      tmp_board : [20][10]u8
      skipped : int
      for i := 19; i >= 0; i -= 1 {
        if slice.contains(to_clear[:], i) {
          skipped += 1
          continue
        }
        tmp_board[i+skipped] = board[i]
      }
      board = tmp_board
      animated_frames = 0
      frozen = false
    }
    if len(to_clear) > 0 {
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

    BeginDrawing()

    ClearBackground(bg0)
    for j in 0..<20 do for i in 0..<10 {
      color := board[j][i]
      raylib.DrawRectangle(i32(i)*(block_size+block_pad), i32(j)*(block_size+block_pad), block_size, block_size, colors[color])
    }
    if !frozen do draw_piece(&active_piece)

    EndDrawing()
  }

  CloseWindow()
}

reset :: proc(ref: ^Piece) {
  board = [20][10]u8{}
  new_piece(ref)
}

draw_piece :: proc(ref: ^Piece) {
  for i in 0..<ref.size do for j in 0..<ref.size {
    color := ref.data[j, i]
    if color != 0 {
      raylib.DrawRectangle(
        i32(i+ref.pos[0])*(block_size+block_pad),
        i32(j+ref.pos[1])*(block_size+block_pad),
        block_size,
        block_size,
        colors[color]
      )
    }
  }
}

new_piece :: proc(ref: ^Piece) {
  ref^ = pieces[rand.choice_enum(PieceID)]
}

check_collision :: proc(p: ^Piece) -> bool {
  for i in 0..<p.size do for j in 0..<p.size {
    color := p.data[j, i]
    x, y := p.pos[0]+i, p.pos[1]+j
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

place_piece :: proc(p: ^Piece) {
  for i in 0..<p.size do for j in 0..<p.size {
    color := p.data[j, i]
    if color != 0 {
      y := p.pos[1]+j
      if y < 20 do board[p.pos[1]+j][p.pos[0]+i] = color
    }
  }
  check_needed = true
  new_piece(p)
}

mask_bottommost :: proc(p: ^Piece) -> Piece {
  mask : Piece
  for i in 0..<p.size do for j in 0..<p.size {
    if j == p.size - 1 || p.data[j+1, i] == 0 {
      mask.data[j, i] = p.data[j, i]
    }
  }
  return mask
}

hard_drop :: proc(p: ^Piece) {
  mask := mask_bottommost(p)
  distance: int
  found: bool
  for i in 0..<p.size do for j in 0..<p.size {
    color := mask.data[j, i]
    if color != 0 && p.pos[1]+j == 19 do found = true
  }
  for !found {
    distance += 1
    for i in 0..<p.size do for j in 0..<p.size {
      color := mask.data[j, i]
      y := p.pos[1]+j+distance+1
      if color != 0 {
        if y >= 20 || board[y][p.pos[0]+i] != 0 {
          found = true
          break
        }
      }
    }
  }
  p.pos[1] += distance
  place_piece(p)
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

