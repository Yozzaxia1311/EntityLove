-- This demo demonstrates collision using the built-in spatial hashing.

io.stdout:setvbuf("no")

local system = require("entitylove")

function createParticle(x, y, speed)
  local particle = {}
  
  particle.position = {}
  particle.position.x = x
  particle.position.y = y
  if love.math.random(0, 1) == 1 then
    system:setRectangleCollision(particle, love.math.random(16, 32), love.math.random(16, 32))
  else
    system:setCircleCollision(particle, love.math.random(8, 16))
  end
  
  particle.moveTimer = 0
  particle.speed = speed
  particle.startY = particle.position.y
  particle.variation = love.math.random(32, 250)
  
  function particle:draw()
    if system:collisionNumber(self, system:getSurroundingEntities(self)) > 0 then
      love.graphics.setColor(1, 0, 0, 1)
    else
      love.graphics.setColor(1, 1, 1, 1)
    end
    
    if self.collisionShape.type == system.COL_CIRCLE then
      love.graphics.circle("fill", self.position.x, self.position.y, self.collisionShape.r)
    else
      love.graphics.rectangle("fill", self.position.x, self.position.y, self.collisionShape.w, self.collisionShape.h)
    end
  end
  
  function particle:update(dt)
    self.moveTimer = self.moveTimer + (dt * 100)
    
    if self.position.x < -self.collisionShape.w or self.position.x > love.graphics.getWidth() then
      system:remove(self)
    else
      self.position.x = self.position.x + (self.speed * dt)
      self.position.y = particle.startY + (math.cos(math.rad(self.moveTimer)) * self.variation)
    end
  end
  
  return particle
end

local timer = 0
local timerEntityCount = 0
local static = false

function love.keypressed(k)
  if k == "space" then
    static = not static
    
    if static then
      for i = 1, #system.all do
        system:makeStatic(system.all[i])
      end
    else
      for i = 1, #system.all do
        system:revertFromStatic(system.all[i])
      end
    end
  end
end

function love.update(dt)
  local spawn = false
  
  timer = timer + dt
  while timer > 0.2 do
    timer = timer - 0.2
    spawn = true
  end
  
  if spawn and not static then
    system:add(createParticle(-14, 250, 100))
    system:add(createParticle(love.graphics.getWidth() - 2, 330, -100))
  end
  
  system:update(dt)
  
  timerEntityCount = timerEntityCount + dt
  if timerEntityCount > 1 and not static then
    timerEntityCount = 0
    print("Entities", #system.all)
  end
end

function love.draw()
  system:draw()
  
  love.graphics.print("Press Space to toggle static.")
end