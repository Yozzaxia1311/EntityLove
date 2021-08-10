-- This demo demonstrates collision using the built-in spatial hashing.

io.stdout:setvbuf("no")

local system = require("entitylove")

function drawFunc()
  if self.collisionShape.type == system.COL_CIRCLE then
    love.graphics.circle("fill", self.position.x, self.position.y, self.collisionShape.r)
  else
    love.graphics.rectangle("fill", self.position.x, self.position.y, self.collisionShape.w, self.collisionShape.h)
  end
end

function createParticle(x, y)
  local particle = {}
  
  system:pos(particle, x, y)
  
  if love.math.random(0, 1) == 1 then
    system:setRectangleCollision(particle, love.math.random(16, 32), love.math.random(16, 32))
  else
    system:setCircleCollision(particle, love.math.random(8, 16))
  end
  
  particle.draw = drawFunc
  
  return particle
end

function love.load()
  for i = 1, 100 do
    system:add(createParticle(love.math.random(0, love.graphics.getWidth() - 24), love.math.random(0, love.graphics.getHeight() - 64)))
  end
end

function love.update(dt)
  system:update(dt)
end

function love.draw()
  system:draw()
  
  love.graphics.print("Arrow keys to move!", 5, love.graphics.getHeight() - 18)
end