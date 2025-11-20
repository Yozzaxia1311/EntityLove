-- This demo demonstrates collision using the built-in spatial hashing.

io.stdout:setvbuf("no")
local entitylove = require("entitylove")
local system = entitylove()

local function drawParticle(self)
  if self.collisionShape.type == entitylove.COL_CIRCLE then
    love.graphics.circle("fill", self.position.x, self.position.y, self.collisionShape.r)
  else
    if system:pointInEntity(self, love.mouse.getX(), love.mouse.getY()) then
      love.graphics.setColor(1, 0, 0, 1)
      if love.mouse.isDown(1) then
        system:remove(self)
      end
    end
    
    love.graphics.rectangle("fill", self.position.x, self.position.y,
      self.collisionShape.w, self.collisionShape.h)
  end
end

local function createParticle(x, y)
  local particle = {}
  
  system:pos(particle, x, y)
  
  if love.math.random(0, 1) == 1 then
    system:setRectangleCollision(particle, love.math.random(16, 32), love.math.random(16, 32))
  else
    system:setCircleCollision(particle, love.math.random(8, 16))
  end
  
  particle.draw = drawParticle
  particle.solidType = entitylove.SOLID_TYPE_SOLID
  
  return particle
end

local function updatePlayer(self, dt)
  local moveDirX, moveDirY = 0, 0
  
  if love.keyboard.isDown("left") then
    moveDirX = moveDirX - 1
  end
  if love.keyboard.isDown("right") then
    moveDirX = moveDirX + 1
  end
  if love.keyboard.isDown("up") then
    moveDirY = moveDirY - 1
  end
  if love.keyboard.isDown("down") then
    moveDirY = moveDirY + 1
  end
  
  if moveDirX ~= 0 or moveDirY ~= 0 then
    self.velocity.x, self.velocity.y = moveDirX * 120 * dt, moveDirY * 120 * dt
    system:move(self)
  end
end

local function drawPlayer(self)
  system:drawCollision(self)
end

function createPlayer(x, y)
  local player = {}
  
  system:pos(player, x, y)
  system:setRectangleCollision(player, 32, 32)
  
  player.update = updatePlayer
  player.draw = drawPlayer
  player.maxSlopeX = 4
  player.maxSlopeY = 6
  
  return player
end

function love.load()
  for i = 1, 100 do
    system:add(createParticle(love.math.random(0, love.graphics.getWidth() - 24),
      love.math.random(0, love.graphics.getHeight() - 64)))
  end
  
  system:add(createPlayer(love.graphics.getWidth() / 2, love.graphics.getHeight() - 18))
end

function love.update(dt)
  system:update(dt)
end

function love.draw()
  system:draw()
  
  love.graphics.print("Arrow keys to move!", 5, love.graphics.getHeight() - 18)
end