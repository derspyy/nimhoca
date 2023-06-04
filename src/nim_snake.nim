import std/[random, os, options]

randomize()

import sdl2

const
  size = (40, 30)
  time = (500, 200)

type
  Direction = enum
    up, down, left, right
  Snake = object
    head: (uint, uint)
    body: seq[(uint, uint)]
    food: (uint, uint)
    direction: Direction
    wait_time: int
  SDLException = object of Defect

proc genPos(): (uint, uint) =
  let x = rand(0..size[0]-1)
  let y = rand(0..size[1]-1)
  (x.uint ,y.uint)

proc spawnFood(self: Snake): (uint, uint) =
  var food = genPos()
  while contains(self.body, food) or food == self.head:
    food = genPos()
  food

proc updateTime(self: Snake): int =
  let time = ((time[1] - time[0]) * self.body.len() / (size[0] * size[1]).int).int + time[0]
  time

proc rectFromPos(x: (uint, uint)): Rect =
  return rect(
    cint(x[0] * 20),
    cint(x[1] * 20),
    cint(20),
    cint(20)
  )

if not sdl2.init(INIT_VIDEO or INIT_EVENTS):
  try:
    raise SDLException.newException("sdl2 couldn't be initialized:" & $getError())
  finally: 
    sdl2.quit()

let window = createWindow(
  title = "nimhoca", # >;]
  x = SDL_WINDOWPOS_CENTERED,
  y = SDL_WINDOWPOS_CENTERED,
  w = size[0] * 20,
  h = size[1] * 20,
  flags = SDL_WINDOW_SHOWN
)

if window.isNil():
  try:
    raise SDLException.newException("window could not be created:" & $getError())
  finally: 
    window.destroy()

let canvas = createRenderer(
  window = window,
  index = -1,
  flags = Renderer_PresentVsync
)

if canvas.isNil():
  try:
    raise SDLException.newException("renderer could not be created:" & $getError())
  finally:
    canvas.destroy()

var game = Snake(
  head: genPos(),
  body: @[],
  food: genPos(),
  direction: up,
  wait_time: time[0]
)

var event = defaultEvent 

block gameloop:
  while true:
    var direction = none(Direction)
    while pollEvent(event):
      case event.kind
      of KeyDown:
        case event.key.keysym.scancode
        of SDL_SCANCODE_UP:
          if game.direction != down:
            direction = some(up)
        of SDL_SCANCODE_DOWN:
          if game.direction != up:
            direction = some(down)
        of SDL_SCANCODE_LEFT:
          if game.direction != right:
            direction = some(left)
        of SDL_SCANCODE_RIGHT:
          if game.direction != left:
            direction = some(right)
        else:
          discard
      of QuitEvent:
        break gameloop
      else:
        discard

      if direction.isSome():
        game.direction = direction.get()

    if game.body.len() > 0:
      discard game.body.pop()
      game.body.insert(game.head, 0)

    case game.direction
    of up:
      if game.head[1] == 0:
        game.head = (game.head[0], (size[1] - 1).uint)
      else:
        game.head = (game.head[0], game.head[1] - 1)
    of down:
      if game.head[1] == size[1] - 1:
        game.head = (game.head[0], 0'u)
      else:
        game.head = (game.head[0], game.head[1] + 1)
    of left:
      if game.head[0] == 0:
        game.head = ((size[0] - 1).uint, game.head[1])
      else:
        game.head = (game.head[0] - 1, game.head[1])
    of right:
      if game.head[0] == size[0] - 1:
        game.head = (0'u, game.head[1])
      else:
        game.head = (game.head[0] + 1, game.head[1])

    if contains(game.body, game.head):
      break gameloop

    if game.head == game.food:
      game.body.add(game.head)
      game.wait_time = updateTime(game)
      game.food = game.spawnFood()

    # GRAY
    canvas.setDrawColor(128, 128, 128, 255)
    canvas.clear()

    # GREEN
    canvas.setDrawColor(0, 255, 0, 255)
    var square: Rect = rectFromPos(game.head)
    canvas.fillRect(square)
    for x in game.body:
      square = rectFromPos(x)
      canvas.fillRect(square)

    # RED
    canvas.setDrawColor(255, 0, 0, 255)
    square = rectFromPos(game.food)
    canvas.fillRect(square)

    canvas.present()

    sleep(game.wait_time)

  
