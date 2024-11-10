let rect : @lib.Rect = @lib.Rect::{
  top_left: { x: 0, y: 0 },
  bottom_right: { x: 160, y: 160 },
}

let tree : Ref[@lib.QuadTree[@game.Tank]] = { val: @lib.QuadTree::new(rect) }

let array : Array[@game.Tank] = []

let random : @random.Rand = @random.new()

let id : Ref[UInt] = { val: 0 }

const NUM = 140

pub fn start() -> Unit {
  for i = 0; i < NUM; i = i + 1 {
    id.val += 1
    let mut tank = @game.Tank::new(
      id.val,
      {
        x: random.int(limit=160 - @game.SIZE),
        y: random.int(limit=160 - @game.SIZE),
      },
    )
    loop tree.val.search(tank.rect()) {
      Nil => {
        tree.val = tree.val.insert(tank)
        array.push(tank)
      }
      _ => {
        tank = @game.Tank::new(
          id.val,
          {
            x: random.int(limit=160 - @game.SIZE),
            y: random.int(limit=160 - @game.SIZE),
          },
        )
        continue tree.val.search(tank.rect())
      }
    }
  }
}

const SPEED = 5

let frame : Ref[Int] = { val: 0 }

pub fn update() -> Unit {
  if frame.val % 1 == 0 {
    for i = 0; i < array.length(); i = i + 1 {
      let tank = array[i]
      let collidables = tree.val.ahead(tank.direction, SPEED, tank)
      let actual_distance = collidables
        .map(fn { (_, i) => i })
        .fold(init=SPEED, @math.minimum)
      let actual_distance = match tank.direction {
        Up => @math.minimum(actual_distance, tank.rect.top_left.y)
        Down =>
          @math.minimum(actual_distance, 160 - tank.rect.bottom_right.y - 1)
        Left => @math.minimum(actual_distance, tank.rect.top_left.x)
        Right =>
          @math.minimum(actual_distance, 160 - tank.rect.bottom_right.x - 1)
      }
      let new_tank = {
        ..tank,
        direction: if actual_distance < SPEED {
          tank.direction.clockwise()
        } else {
          tank.direction
        },
        rect: tank.rect.move(tank.direction, actual_distance),
      }
      array[i] = new_tank
      tree.val = tree.val.delete(tank).insert(new_tank)
    }
  }
  frame.val += 1
  array.iter().each(@lib.Draw::draw)
}
