# EntityLove

EntityLove is a entity handling system with built in z-indexing, collision, and spatial hashing support.

![img](https://github.com/Yozzaxia1311/EntityLove/blob/main/demo.gif)

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
                                     -- Entities will be removed from all groups
                                     -- when `system:remove(e)` is called.
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

**`.HASH_SIZE`: enum = 96**: Hash cell size.

**`.COL_RECT`: enum = 1**: Rectangle collider type.

**`.COL_IMAGE`: enum = 2**: Image collider type.

**`.COL_CIRCLE`: enum = 3**: Circle collider type.

---

**`:update(dt)`**

**`dt`: number**

Updates entities and their position in the spatial hash, passing delta time `dt`. Entities marked as "static" via `:makeStatic()` will not be called.

---

**`:draw()`**

Calls entity draw functions. Entities marked as "static" via `:makeStatic()` will not be called. The draw color is auto set as white.

---

**`:add(e)`**

**`e`: table**

Adds entity into the system. Calls `e:added()`.

---

**`:remove(e)`**

**`e`: table - entity**

Removes entity from the system. Calls `e:removed()`, and removes the entity from all groups.

---

**`:clear()`**

Removes every entity.

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

**returns boolean**

Checks if entity is in `name` group.

---

**`:setLayer(e, layer)`**

**`e`: table - entity, `layer`: number**

Sets z-index of entity. Higher numbers will have draw priority.


---

**`:getLayer(e)`**

**`e`: table - entity**

**returns number**

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

**returns table**

Retreives entities in a rectangle defined by `x`, `y`, `w`, and `h`. Uses spatial hashes.


---

**`:getSurroundingEntities(e, extentsLeft, extentsRight, extentsUp, extentsDown)`**

**`e`: table - entity, `extentsLeft`: number, `extentsRight`: number, `extentsUp`: number, `extentsDown`: number**

**returns table**

Retreives entities around `e`, with extents. Uses spatial hashes.

---

**`:collision(e, other, ox, oy, notme)`**

**`e`: table - entity, `other`: table - entity, `ox`: number, `oy`: number, `notme`: boolean**

**returns boolean**

Checks if `e` and `other` are colliding. `e` will be offset by `ox` and `oy`, if provided. If `notme`, then the function will return `false` if both entities are the same.

---

**`:collisionTable(e, table, ox, oy, notme)`**

**`e`: table - entity, `table`: table, `ox`: number, `oy`: number, `notme`: boolean**

**returns table**

Checks if `e` and any entity in `table` are colliding, then returns a table of colliding entities. `e` will be offset by `ox` and `oy`, if provided. If `notme`, then the function will ignore checks between `e` and itself.

---

**`:collisionNumber(e, table, ox, oy, notme)`**

**`e`: table - entity, `table`: table, `ox`: number, `oy`: number, `notme`: boolean**

**returns number**

Checks if `e` and any entity in `table` are colliding, then returns the number of colliding entities. `e` will be offset by `ox` and `oy`, if provided. If `notme`, then the function will ignore checks between `e` and itself.

---

**`:makeStatic(e)`**

**`e`: table - entity**

Marks `e` as "static", keeping it accounted for in the system, but removing it from the update and draw loops until made "unstatic" via `revertFromStatic`. Useful for unmoving objects in high abundance, such as solids. This function calls `e:staticToggled()`.

---

**`:revertFromStatic(e)`**

**`e`: table - entity**

Reverts "static" state from `e`, making it a normal entity. This function calls `e:staticToggled()`.

## Entity Event Functions and Variables

### Note: entity variables interface with the system, but are not required. Variables documented below are initialized manually by the user. EntityLove will conform the entity with default values, if it's needed.

**`.isRemoved`: readonly boolean**: if `self` is removed from the system.

**`.isAdded`: readonly boolean**: if `self` is added to the system.

**`.position`: table**: position used by EntityLove. Can be conveniently set as a 2D vector.

- **`.x`: number**: X axis.
- **`.y`: number**: Y axis.

**`.collisionShape`: readonly table**: collision used by EntityLove.

- **`.w`: readonly number**: Width of collider.
- **`.h`: readonly number**: Height of collider.
- **`.type`: readonly number**: type of collider, correlating to the enums in `entitySystem`.
- **`.data`: readonly ImageData**: ImageData of collider, if set with `entitySystem:setImageCollision(e, data)`.
- **`.r`: readonly number**: Radius of collider circle, if set with `entitySystem:setCircleCollision(e, r)`.

**`.static`: readonly boolean**: If the entity is marked as "static". Read `entitySystem:makeStatic(e)` documention for more details.

**`.canUpdate`: boolean**: If the entity should be updated. The system will still iterate over it, but will not call `self:update(dt)`.

**`.canDraw`: boolean**: If the entity should be drawn. The system will still iterate over it, but will not call `self:draw()`.

**`.system`: readonly table**: Reference variable for the `entitySystem` this entity is in.

---

**`:update(dt)`**

**`dt`: number**

Called once per `entitySystem:update(dt)`. Delta time is passed.

---

**`:beforeUpdate(dt)`**

**`dt`: number**

Called once per `entitySystem:update(dt)`, before the system has called any entity's `self:update(dt)`. Delta time is passed.

---

**`:update(dt)`**

**`dt`: number**

Called once per `entitySystem:update(dt)`, after the system has called all entity's `self:update(dt)`. Delta time is passed.

---

**`:added()`**

Called when `self` has been added to an `entitySystem`.

---

**`:ready()`**

Called after every entities has been added, and the system is about to iterate through its first update loop.

---

**`:removed()`**

Called when `self` is removed from the system.

---

**`:staticToggled()`**

Called when `self` is marked as "static" by the system. Read `entitySystem:makeStatic(e)` documention for more details.

---
