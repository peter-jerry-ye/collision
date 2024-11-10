pub struct Tank {
  id : UInt
  team : Int
  direction : @lib.Direction
  rect : @lib.Rect
} derive(Show)

pub fn op_equal(self : Tank, other : Tank) -> Bool {
  self.id == other.id
}

pub const SIZE = 8

pub fn Tank::new(
  id : UInt,
  pos : @lib.Point,
  ~team : Int = 0,
  ~direction : @lib.Direction = Up
) -> Tank {
  {
    id,
    team,
    direction,
    rect: { top_left: pos, bottom_right: { x: pos.x + SIZE, y: pos.y + SIZE } },
  }
}

pub fn rect(self : Tank) -> @lib.Rect {
  self.rect
}

pub fn draw(self : Tank) -> Unit {
  @wasm4.set_draw_colors(index=1, 1)
  @wasm4.set_draw_colors(index=2, 3)
  self.rect.draw()
  @wasm4.set_draw_colors(index=1, 2)
  @wasm4.set_draw_colors(index=2, 0)
  @wasm4.text(
    "\{self.team}",
    self.rect.top_left.x + 1,
    self.rect.top_left.y + 1,
  )
  match self.direction {
    Left =>
      @wasm4.line(
        self.rect.top_left.x,
        self.rect.top_left.y,
        self.rect.top_left.x,
        self.rect.bottom_right.y,
      )
    Right =>
      @wasm4.line(
        self.rect.bottom_right.x,
        self.rect.top_left.y,
        self.rect.bottom_right.x,
        self.rect.bottom_right.y,
      )
    Up =>
      @wasm4.line(
        self.rect.top_left.x,
        self.rect.top_left.y,
        self.rect.bottom_right.x,
        self.rect.top_left.y,
      )
    Down =>
      @wasm4.line(
        self.rect.top_left.x,
        self.rect.bottom_right.y,
        self.rect.bottom_right.x,
        self.rect.bottom_right.y,
      )
  }
}
