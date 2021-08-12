# EntityLove

EntityLove is a entity handling system with built in z-indexing, collision, and spatial hashing support.

<img src="https://github.com/Yozzaxia1311/EntityLove/blob/main/demo.gif" width="600px">

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

function entity:draw() -- EntityLove auto-sets color to white.
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

**`.inLoop`: readonly boolean**: If currently in update loop.

**`.inDrawLoop`: readonly boolean**: If currently in draw loop.

**`.drawCollision`: readonly boolean**: draws collision for active entities. Useful for debugging.

**`.groups`: readonly table**: table of groups.

**`.all`: readonly table**: table of all entities.

**`.layers`: readonly table**: table of layers.

- **`[index].layer`: readonly number**: Z index.
- **`[index].data`: readonly table**: table of entities on this z index.

**`.static`: readonly table**: table of "static" entities. Read `:makeStatic(e)` documention for more details.

---

**`:update(dt)`**

**`dt`: number**

Updates entities and their position in the spatial hash, passing delta time `dt`. Entities marked as "static" via `:makeStatic()` will not be called.

---

**`:draw()`**

Calls entity draw functions. Entities marked as "static" via `:makeStatic()` will not be called. The draw color is auto-set to white.

---

**`:add(e)`**

**`e`: table - entity**

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

**`:pos(e, x, y)`**

**`e`: table - entity, `x`: number, `y`: number**

Sets position of `e` and updates its spatial hash.


---

**`:move(e, x, y, solid, resolverX, resolverY)`**

**`e`: table - entity, `x`: number, `y`: number, `solids`: table, `resolverX`: function(against: table), `resolverY`: function(against: table)**

**returns boolean, boolean**

Moves position of `e` and updates its spatial hash. `e` will not move into any entity in `solids`, and may use a custom collision resolver `resolveX` and `resolveY`, where `against` is a table of valid solid entities. Returns if solid shift happened along X or Y axis.


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

**`:collision(e, other, ox, oy)`**

**`e`: table - entity, `other`: table - entity, `ox`: number, `oy`: number**

**returns boolean**

Checks if `e` and `other` are colliding. `e` will be offset by `ox` and `oy`, if provided. This function will return `false` if both entities are the same.

---

**`:collisionTable(e, table, ox, oy)`**

**`e`: table - entity, `table`: table, `ox`: number, `oy`: number**

**returns table**

Checks if `e` and any entity in `table` are colliding, then returns a table of colliding entities. `e` will be offset by `ox` and `oy`, if provided. This function will ignore checks between `e` and itself. For performance reasons, this function expects `table` to be an array.

---

**`:collisionNumber(e, table, ox, oy)`**

**`e`: table - entity, `table`: table, `ox`: number, `oy`: number**

**returns number**

Checks if `e` and any entity in `table` are colliding, then returns the number of colliding entities. `e` will be offset by `ox` and `oy`, if provided. This function will ignore checks between `e` and itself. For performance reasons, this function expects `table` to be an array.

---

**`:updateEntityHash(e)`**

**`e`: table - entity**

Manually updates the spatial hash for `e`.

---

**`:makeStatic(e)`**

**`e`: table - entity**

Marks `e` as "static", removing it from the update and draw loop, but still keeping it inside its groups and spatial hash. Useful for unmoving objects in high abundance, such as solids. If you need to move a static object and check its collision, then the spatial hash needs be updated manually using `:updateEntityHash(e)`. This function calls `e:staticToggled()`.

---

**`:revertFromStatic(e)`**

**`e`: table - entity**

Reverts "static" state from `e`, making it a normal entity. This function calls `e:staticToggled()`.

## Entity Event Functions and Variables

### Note: entity variables interface with the system, but are not required. Variables documented below are initialized manually by the user. EntityLove will conform the entity with default values, if it's needed.

**`.isRemoved`: readonly boolean**: if `self` is removed from the system.

**`.isAdded`: readonly boolean**: if `self` is added to the system.

**`.position`: table**: position used by EntityLove. Can be conveniently set as a 2D vector. Note: manually changing this variable will not update its spatial hash. To set the position and update the hash, use `entitySystem:pos(e, x, y)`.

- **`.x`: number**: X axis.
- **`.y`: number**: Y axis.

**`.collisionShape`: readonly table**: collision used by EntityLove. Note: manually changing this variable will not update its spatial hash. To set the collider and update the hash, use one of `entitySystem`'s collision setters.

- **`.w`: readonly number**: Width of collider.
- **`.h`: readonly number**: Height of collider.
- **`.type`: readonly number**: type of collider, correlating to the enums in `entitySystem`.
- **`.data`: readonly ImageData**: ImageData of collider, if set with `entitySystem:setImageCollision(e, data)`.
- **`.r`: readonly number**: Radius of collider circle, if set with `entitySystem:setCircleCollision(e, r)`.

**`.static`: readonly boolean**: If the entity is marked as "static". Read `entitySystem:makeStatic(e)` documention for more details.

**`.canUpdate`: boolean**: If the entity should be updated. The system will still iterate over it, but will not call `self:update(dt)`.

**`.canDraw`: boolean**: If the entity should be drawn. The system will still iterate over it, but will not call `self:draw()`.

**`.invisibleToHash`: readonly boolean**: If the entity is processed in the spatial hashing system.

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
