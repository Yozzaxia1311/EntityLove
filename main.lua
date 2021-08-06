local system = require("entitylove")

function createPlayer(x, y)
  local player = {position = {}}
  
  player.position.x = x
  player.position.y = y
  system:setRectangleCollision(player, 32, 32)
  
  player.colorTimer = 0
  
  -- EntityLove calls special event functions if it's in the table. Ex: :draw(), :update(), :ready(), :added(), :removed()...
  function player:draw() -- Draw color is auto set to white.
    love.graphics.setColor((self.position.x % 255) / 255,
      (self.position.y % 255) / 255, ((self.position.x + self.position.y) % 255) / 255, 1)
    love.graphics.rectangle("fill", self.position.x, self.position.y, self.collisionShape.w, self.collisionShape.h)
  end
  
  function player:update(dt)
    player.colorTimer = player.colorTimer + dt * 1000
    
    if love.keyboard.isDown("left") then
      self.position.x = self.position.x - (180 * dt)
    end
    if love.keyboard.isDown("right") then
      self.position.x = self.position.x + (180 * dt)
    end
    if love.keyboard.isDown("up") then
      self.position.y = self.position.y - (180 * dt)
    end
    if love.keyboard.isDown("down") then
      self.position.y = self.position.y + (180 * dt)
    end
    
    self.position.x = math.min(math.max(self.position.x, 0), love.graphics.getWidth() - self.collisionShape.w)
    self.position.y = math.min(math.max(self.position.y, 0), love.graphics.getHeight() - self.collisionShape.h)
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