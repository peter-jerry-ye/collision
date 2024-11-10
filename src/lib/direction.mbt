pub enum Direction {
  Left
  Right
  Up
  Down
} derive(Eq, Show)

pub fn clockwise(self : Direction) -> Direction {
  match self {
    Left => Up
    Up => Right
    Right => Down
    Down => Left
  }
}

pub fn counter_clockwise(self : Direction) -> Direction {
  match self {
    Left => Down
    Down => Right
    Right => Up
    Up => Left
  }
}

pub trait Draw {
  draw(Self) -> Unit
}

pub struct Point {
  x : Int
  y : Int
} derive(Eq, Show)

pub fn move(self : Point, direction : Direction, distance : Int) -> Point {
  match direction {
    Up => { ..self, y: self.y - distance }
    Down => { ..self, y: self.y + distance }
    Left => { ..self, x: self.x - distance }
    Right => { ..self, x: self.x + distance }
  }
}

pub struct Rect {
  top_left : Point
  bottom_right : Point
} derive(Eq, Show)

pub fn move(self : Rect, direction : Direction, distance : Int) -> Rect {
  {
    top_left: self.top_left.move(direction, distance),
    bottom_right: self.bottom_right.move(direction, distance),
  }
}

pub fn draw(self : Rect) -> Unit {
  @wasm4.rect(
    self.top_left.x,
    self.top_left.y,
    self.bottom_right.x - self.top_left.x + 1,
    self.bottom_right.y - self.top_left.y + 1,
  )
}

pub fn intersect(self : Rect, other : Rect) -> Bool {
  if self.bottom_right.x < other.top_left.x ||
    self.top_left.x > other.bottom_right.x {
    return false
  }
  if self.bottom_right.y < other.top_left.y ||
    self.top_left.y > other.bottom_right.y {
    return false
  }
  true
}

pub fn inside(self : Rect, other : Rect) -> Bool {
  self.bottom_right.x <= other.bottom_right.x &&
  self.top_left.x >= other.top_left.x &&
  self.bottom_right.y <= other.bottom_right.y &&
  self.top_left.y >= other.top_left.y
}
