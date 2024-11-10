pub trait Draw {
  draw(Self) -> Unit
}

pub struct Point {
  x : Int
  y : Int
} derive(Eq, Show)

pub struct Rect {
  top_left : Point
  bottom_right : Point
} derive(Eq, Show)

pub fn draw(self : Rect) -> Unit {
  @wasm4.rect(
    self.top_left.x,
    self.top_left.y,
    self.bottom_right.x - self.top_left.x,
    self.bottom_right.y - self.top_left.y,
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

pub trait Object: Draw + Eq {
  rect(Self) -> Rect
}

pub impl Object for Rect with rect(self) { self }

pub enum QuadTree[T] {
  Leaf(Rect, @immut/list.T[T])
  Tree(
    Rect,
    @immut/list.T[T],
    QuadTree[T],
    QuadTree[T],
    QuadTree[T],
    QuadTree[T]
  )
} derive(Show)

pub fn QuadTree::new[T : Object](rect : Rect) -> QuadTree[T] {
  Leaf(rect, @immut/list.T::Nil)
}

pub fn draw[T : Object](self : QuadTree[T]) -> Unit {
  match self {
    Leaf(rect, objects) => {
      @wasm4.set_draw_colors(index=1, 0)
      @wasm4.set_draw_colors(index=2, 2)
      rect.draw()
      @wasm4.set_draw_colors(index=2, 3)
      objects.iter().each(Draw::draw)
    }
    Tree(rect, objects, up_left, up_right, down_left, down_right) => {
      @wasm4.set_draw_colors(index=1, 0)
      @wasm4.set_draw_colors(index=2, 2)
      rect.draw()
      @wasm4.set_draw_colors(index=2, 3)
      objects.iter().each(Draw::draw)
      [up_left, up_right, down_left, down_right].iter().each(Draw::draw)
    }
  }
}

pub fn rect[T](self : QuadTree[T]) -> Rect {
  match self {
    Leaf(rect, _) => rect
    Tree(rect, _, _, _, _, _) => rect
  }
}

const MIN_SIZE = 10

pub fn insert[T : Object](self : QuadTree[T], object : T) -> QuadTree[T] {
  let obj = object.rect()
  fn insert_aux(tree) -> QuadTree[T] {
    match tree {
      Leaf(rect, Nil) => Leaf(rect, @immut/list.Cons(object, @immut/list.Nil))
      Leaf(rect, objects) =>
        if rect.bottom_right.x - rect.top_left.x <= MIN_SIZE {
          Leaf(rect, @immut/list.Cons(object, objects))
        } else {
          let middle_x = (rect.top_left.x + rect.bottom_right.x) / 2
          let middle_y = (rect.top_left.y + rect.bottom_right.y) / 2
          let up_left = Leaf(
            {
              top_left: rect.top_left,
              bottom_right: { x: middle_x, y: middle_y },
            },
            @immut/list.Nil,
          )
          let up_right = Leaf(
            {
              top_left: { x: middle_x, y: rect.top_left.y },
              bottom_right: { x: rect.bottom_right.x, y: middle_y },
            },
            @immut/list.Nil,
          )
          let down_left = Leaf(
            {
              top_left: { x: rect.top_left.x, y: middle_y },
              bottom_right: { x: middle_x, y: rect.bottom_right.y },
            },
            @immut/list.Nil,
          )
          let down_right = Leaf(
            {
              top_left: { x: middle_x, y: middle_y },
              bottom_right: rect.bottom_right,
            },
            @immut/list.Nil,
          )
          let tree = Tree(
            rect,
            @immut/list.Nil,
            up_left,
            up_right,
            down_left,
            down_right,
          )
          @immut/list.Cons(object, objects)
          .iter()
          .fold(init=tree, QuadTree::insert)
        }
      Tree(rect, objects, up_left, up_right, down_left, down_right) =>
        if obj.inside(up_left.rect()) {
          Tree(
            rect,
            objects,
            insert_aux(up_left),
            up_right,
            down_left,
            down_right,
          )
        } else if obj.inside(up_right.rect()) {
          Tree(
            rect,
            objects,
            up_left,
            insert_aux(up_right),
            down_left,
            down_right,
          )
        } else if obj.inside(down_left.rect()) {
          Tree(
            rect,
            objects,
            up_left,
            up_right,
            insert_aux(down_left),
            down_right,
          )
        } else if obj.inside(down_right.rect()) {
          Tree(
            rect,
            objects,
            up_left,
            up_right,
            down_left,
            insert_aux(down_right),
          )
        } else {
          Tree(
            rect,
            @immut/list.Cons(object, objects),
            up_left,
            up_right,
            down_left,
            down_right,
          )
        }
    }
  }

  insert_aux(self)
}

pub fn delete[T : Object](self : QuadTree[T], object : T) -> QuadTree[T] {
  let obj = object.rect()
  fn delete_aux(self : QuadTree[T]) -> QuadTree[T] {
    match self {
      Leaf(rect, objects) => Leaf(rect, objects.filter(fn { t => t != object }))
      Tree(rect, objects, up_left, up_right, down_left, down_right) => {
        let objects = objects.filter(fn { t => t != object })
        let up_left = if obj.inside(up_left.rect()) {
          delete_aux(up_left)
        } else {
          up_left
        }
        let up_right = if obj.inside(up_right.rect()) {
          delete_aux(up_right)
        } else {
          up_right
        }
        let down_left = if obj.inside(down_left.rect()) {
          delete_aux(down_left)
        } else {
          down_left
        }
        let down_right = if obj.inside(down_right.rect()) {
          delete_aux(down_right)
        } else {
          down_right
        }
        match (up_left, up_right, down_left, down_right) {
          (
            Leaf(_, @immut/list.Nil),
            Leaf(_, @immut/list.Nil),
            Leaf(_, @immut/list.Nil),
            Leaf(_, @immut/list.Nil),
          ) => Leaf(rect, objects)
          _ => Tree(rect, objects, up_left, up_right, down_left, down_right)
        }
      }
    }
  }

  delete_aux(self)
}

pub fn search[T : Object](self : QuadTree[T], rect : Rect) -> @immut/list.T[T] {
  let mut result = @immut/list.Nil
  fn aux(self) -> Unit {
    match self {
      Leaf(_, list) =>
        result = list
          .filter(fn(o : T) { o.rect().intersect(rect) })
          .concat(result)
      Tree(_, list, up_left, up_right, down_left, down_right) => {
        result = list.filter(fn(o) { o.rect().intersect(rect) }).concat(result)
        if rect.inside(up_left.rect()) {
          aux(up_left)
        }
        if rect.inside(up_right.rect()) {
          aux(up_right)
        }
        if rect.inside(down_left.rect()) {
          aux(down_left)
        }
        if rect.inside(down_right.rect()) {
          aux(down_right)
        }
      }
    }
  }

  aux(self)
  result
}
