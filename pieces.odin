package main

import "vendor:raylib"

Piece :: struct {
  size: int,
  id: PieceID,
  data: matrix[4,4]u8,
  pos: [2]int,
}

PieceID :: enum{ O, S, Z, T, L, J, I }

pieces : [7]Piece = {
  piece_o,
  piece_s,
  piece_z,
  piece_t,
  piece_l,
  piece_j,
  piece_i,
}
colors : [9]raylib.Color = {
  bg2,
  yellow,
  green,
  red,
  purple,
  orange,
  blue,
  aqua,
  fg,
}

piece_i : Piece : {
  size = 4,
  id = .I,
  data = {
    0, 7, 0, 0,
    0, 7, 0, 0,
    0, 7, 0, 0,
    0, 7, 0, 0,
  },
  pos = { 3, 0 },
}
piece_t : Piece : {
  size = 3,
  id = .T,
  data = {
    0, 4, 0, 0,
    4, 4, 4, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
  },
  pos = { 3, 0 },
}
piece_s : Piece : {
  size = 3,
  id = .S,
  data = {
    0, 2, 2, 0,
    2, 2, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
  },
  pos = { 3, 0 },
}
piece_z : Piece : {
  size = 3,
  id = .Z,
  data = {
    3, 3, 0, 0,
    0, 3, 3, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
  },
  pos = { 3, 0 },
}
piece_l : Piece : {
  size = 3,
  id = .L,
  data = {
    0, 5, 0, 0,
    0, 5, 0, 0,
    0, 5, 5, 0,
    0, 0, 0, 0,
  },
  pos = { 4, 0 },
}
piece_j : Piece : {
  size = 3,
  id = .J,
  data = {
    0, 6, 0, 0,
    0, 6, 0, 0,
    6, 6, 0, 0,
    0, 0, 0, 0,
  },
  pos = { 4, 0 },
}
piece_o : Piece : {
  size = 2,
  id = .O,
  data = {
    1, 1, 0, 0,
    1, 1, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
  },
  pos = { 4, 0 },
}

