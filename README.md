# EntityLove

EntityLove is a entity handling system with built in z-indexing, collision, and spatial hashing support.

## How to Use

First, create the system:
```
local system = require("entitylove") -- Everything you need, right here!
```

Then, create the entity using your class implementation of choice (or an empty table will work, too!), and conform it to EntityLove:
```
local entity = class:extend()

function entity:new(x, y)
  system:conform(self) -- Should be called first!
  
  -- Manipulate all the EntityLove bits to your liking!
  self.x = x
  self.y = y
  system:setImageCollision(self, love.image.newImageData("image/path/here.png"))
  system:addToGroup(self, "myGroup") -- Retrieve group table using `system.groups["groupName"]`. Entities will be removed from all groups when removed.
end

-- EntityLove checks for special event functions to call.
function entity:update(dt)
  -- Logic here!
end

function entity:draw() -- Current color auto sets to white.
  -- Drawing here!
end

-- Check documention below for more entity events.
```

Lastly, add it:
```
function love.load()
  system:add(entity(100, 100))
end

function love.update(dt)
  system:update(dt) -- Update EntityLove.
end

function love.draw()
  system:draw() -- Draw EntityLove.
end
```