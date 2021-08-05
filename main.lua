local system = require("entitylove")

function createPlayer(x, y)
  local player = system:conform({}) -- Conform empty table to be EntityLove compatible.
  
  player.x = x
  player.y = y
  system:setRectangleCollision(player, 32, 32)
  
  player.colorTimer = 0
  
  -- EntityLove calls special event functions if it's in the table. Ex: :draw(), :update(), :ready(), :added(), :removed()...
  function player:draw() -- Draw color is auto set to white.
    love.graphics.setColor((self.x % 255) / 255, (self.y % 255) / 255, ((self.x + self.y) % 255) / 255, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.collisionShape.w, self.collisionShape.h)
  end
  
  function player:update(dt)
    player.colorTimer = player.colorTimer + dt * 1000
    
    if love.keyboard.isDown("left") then
      self.x = self.x - 1
    end
    if love.keyboard.isDown("right") then
      self.x = self.x + 1
    end
    if love.keyboard.isDown("up") then
      self.y = self.y - 1
    end
    if love.keyboard.isDown("down") then
      self.y = self.y + 1
    end
    
    self.x = math.min(math.max(self.x, 0), love.graphics.getWidth() - self.collisionShape.w)
    self.y = math.min(math.max(self.y, 0), love.graphics.getHeight() - self.collisionShape.h)
  end
  
  return player
end


function love.load()
  system:add(createPlayer(100, 100))
end

function love.update(dt)
  system:update(dt)
end

function love.draw()
  system:draw()
end