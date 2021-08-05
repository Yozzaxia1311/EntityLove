# EntityLove

EntityLove is a entity handling system with built in z-indexing, collision, and spatial hashing support.

# How to Use

First, create the system:
```lua
local system = require("entitylove")
```

Then, create the entity using your class implementation of choice (or an empty table will work, too!), and conform it to EntityLove:
```lua
local entity = class:extend()

function entity:new(x, y)
  system:conform(self) -- Will add everything needed by EntityLove!
  
  -- Manipulate all the EntityLove bits to your liking!
  self.x = x
  self.y = y
  system:setRectangleCollision(self, 32, 32) -- Spatial hashing is enable by default.
  system:addToGroup(self, "myGroup") -- Retrieve group table using `system.groups["groupName"]`.
                                     -- Entities will be removed from all groups when `system:remove(e)` is used.
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
```lua
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

# Documentation
## `entitySystem`
### `:conform(t)`
`t`: table - Converts table to be usable by an `entitySystem`.

### `:add(e)`
`e`: table - Adds entity into the system. Calls `e:added()`.

### `:queueAdd(e)`
`e`: table - Queues entity to be added outside the update loop.
