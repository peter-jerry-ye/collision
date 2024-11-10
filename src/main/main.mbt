pub fn start() -> Unit {
  @wasm4.set_draw_colors(index=1, 1)
  @wasm4.set_draw_colors(index=2, 2)
}

let rect : @lib.Rect = @lib.Rect::{
  top_left: { x: 0, y: 0 },
  bottom_right: { x: 160, y: 160 },
}

let tree : Ref[@lib.QuadTree[@lib.Rect]] = { val: @lib.QuadTree::new(rect) }

let origin : Ref[@lib.Point?] = { val: None }

let current : Ref[@lib.Point?] = { val: None }

const MIN_SIZE = 2

pub fn update() -> Unit {
  let mouse = @wasm4.get_mouse()
  if mouse.left {
    match origin.val {
      None => {
        origin.val = Some({ x: mouse.x, y: mouse.y })
        current.val = Some({ x: mouse.x, y: mouse.y })
        @wasm4.rect(mouse.x, mouse.y, 1, 1)
      }
      Some({ x, y }) => {
        current.val = Some({ x: mouse.x, y: mouse.y })
        @wasm4.rect(
          @math.minimum(x, mouse.x),
          @math.minimum(y, mouse.y),
          (x - mouse.x).abs(),
          (y - mouse.y).abs(),
        )
      }
    }
  } else {
    match current.val {
      None => ()
      Some({ x, y }) => {
        guard let Some({ x: x0, y: y0 }) = origin.val
        origin.val = None
        current.val = None
        if (x - x0).abs() > MIN_SIZE && (y - y0).abs() > MIN_SIZE {
          tree.val = tree.val.insert(
            {
              top_left: { x: @math.minimum(x0, x), y: @math.minimum(y0, y) },
              bottom_right: { x: @math.maximum(x0, x), y: @math.maximum(y0, y) },
            },
          )
        }
      }
    }
  }
  if mouse.right {
    tree.val = delete_from_tree(tree.val, { x: mouse.x, y: mouse.y })
  }
  tree.val.draw()
}

fn delete_from_tree[T : @lib.Object](
  tree : @lib.QuadTree[T],
  point : @lib.Point
) -> @lib.QuadTree[T] {
  let rects = tree.search({ top_left: point, bottom_right: point })
  rects.fold(init=tree, @lib.delete)
}
