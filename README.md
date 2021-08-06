# EntityLove

EntityLove is a entity handling system with built in z-indexing, collision, and spatial hashing support.

# How to Use

First, create the system:

```lua
local system = require("entitylove")
```

Then, create the entity using your class implementation of choice (or an empty table will work, too!):

```lua
local entity = class:extend()

function entity:new(x, y)
  -- Manipulate all the EntityLove entity bits to your liking!
  self.position = {} -- EntityLove uses `self.position` and
                     -- `self.collisionShape` for collision and spatial hashing.
  self.position.x = x
  self.position.y = y
  system:setRectangleCollision(self, 32, 32) -- `self.collisionShape` is set here.
  system:addToGroup(self, "myGroup") -- Retrieve group table using `system.groups["groupName"]`.
                                     -- Entities will be removed from all groups when `system:remove(e)` is called.
end

-- EntityLove checks for special event functions to call.
function entity:update(dt)
  -- Logic here!
end

function entity:draw() -- EntityLove auto sets color to white.
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

---

# Documentation

## `entitySystem`

**`:add(e)`**

**`e`: table**

Adds entity into the system. Calls `e:added()`.

---

**`:queueAdd(e)`**

**`e`: table**

Queues entity to be added outside the update loop.

---

**`:remove(e)`**

**`e`: table - entity**

Removes entity from the system. Calls `e:removed()`, and removes the entity from all groups.

---

**`:queueRemove(e)`**

**`e`: table - entity**

Queues entity to be removed outside the update loop.

---

**`:addToGroup(e, name)`**

**`e`: table - entity, `name`: string**

Puts entity in group `name`, or creates a new one if it doesn't exist.

---

**`:removeFromGroup(e, name)`**

**`e`: table - entity, `name`: string**

Removes entity from `name` group. 

---

**`:removeFromAllGroups(e)`**

**`e`: table - entity**

Removes entity from all groups.

---

**`:inGroup(e, name)`**

**`e`: table - entity, `name`: string**

Checks if entity is in `name` group.

---

**`:setLayer(e, layer)`**

**`e`: table - entity, `layer`: number**

Sets z-index of entity. Higher number will have draw priority.


---

**`:getLayer(e)`**

**`e`: table - entity**

Gets z-index of entity.


---

**`:setRectangleCollision(e, w, h)`**

**`e`: table - entity, `w`: number, `h`: number**

Sets `e.collisionShape` to use a rectangle of size `w`*`h`.


---

**`:setImageCollision(e, img)`**

**`e`: table - entity, `img`: ImageData**

Sets `e.collisionShape` to use an ImageData object.


---

**`:setCircleCollision(e, r)`**

**`e`: table - entity, `r`: number**

Sets `e.collisionShape` to be a circle of radius `r`.


---

**`:getEntitiesAt(x, y, w, h)`**

**`x`: number, `y`: number, `w`: number, `h`: number**

Retreives entities in a rectangle defined by `x`, `y`, `w`, and `h`. Uses spatial hashes.


---

**`:getSurroundingEntities(e, extentsLeft, extentsRight, extentsUp, extentsDown)`**

**`e`: table - entity, `extentsLeft`: number, `extentsRight`: number, `extentsUp`: number, `extentsDown`: number**

Retreives entities around `e`, with extents. Uses spatial hashes.

---
