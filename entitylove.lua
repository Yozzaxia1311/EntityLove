-- Basic class implementation. [Referenced from Classic](https://github.com/rxi/classic)

local class = {}
class.__class = class

function class:init() end

function class:extend()
  local c = {}
  
  for k, v in pairs(self) do
    if k:find("__") == 1 then
      c[k] = v
    end
  end
  
  c.__class = c
  c.super = self
  setmetatable(c, self)
  
  return c
end

function class:is(typ)
  local mt = getmetatable(self)
  
  while mt do
    if mt == typ then
      return true
    end
    
    mt = getmetatable(mt)
  end
  
  return false
end

function class:__call(...)
  local inst = setmetatable({}, self)
  
  inst:init(...)
  
  return inst
end

-- Important util functions.

local _floor = math.floor
local _ceil = math.ceil
local _sqrt = math.sqrt
local _min = math.min
local _max = math.max
local _remove = _remove

local function _dist2d(x, y, x2, y2)
  return _sqrt(((x - x2) ^ 2) + ((y - y2) ^ 2))
end

local function _clamp(v, min, max)
  return _min(_max(v, max), min)
end

local function _trueIfContainsTrue(w)
  if w then
    for _, v in pairs(w) do
      if v then return true end
    end
  end
  return false
end

local function _falseIfContainsFalse(w)
  if w then
    for _, v in pairs(w) do
      if not v then return false end
    end
  else
    return false
  end
  return true
end

local function _contains(t, va)
  for _, v in pairs(t) do
    if v == va then
      return true
    end
  end
  
  return false
end

local function _intersects(t, t2, fully)
  if fully then
    for _, v in pairs(t) do
      if not _contains(t2, v) then
        return false
      end
    end
    return true
  else
    for _, v in pairs(t) do
      for _, v2 in pairs(t2) do
        if v == v2 then
          return true
        end
      end
    end
  end
  return false
end

local function _icontains(t, va)
  for i = 1, #t do
    if t[i] == va then
      return true
    end
  end
  
  return false
end

local function _removeValueArray(t, va)
  if t[#t] == va then t[#t] = nil return end
  
  for i=1, #t do
    if t[i] == va then
      _remove(t, i)
      break
    end
  end
end

local function _quickRemoveValueArray(t, va)
  if t[#t] == va then t[#t] = nil return end
  
  for i=1, #t do
    if t[i] == va then
      t[i] = t[#t]
      t[#t] = nil
      
      return
    end
  end
end

-- Constants.

local entitySystem = class:extend()

entitySystem.HASH_SIZE = 96
entitySystem.COL_RECT = 1
entitySystem.COL_IMAGE = 2
entitySystem.COL_CIRCLE = 3

-- Collision.

local function _rectOverlapsRect(x1, y1, w1, h1, x2, y2, w2, h2)
  return x1 < x2 + w2 and
    x2 < x1 + w1 and
    y1 < y2 + h2 and
    y2 < y1 + h1
end

local function _pointOverlapsRect(x1, y1, x2, y2, w2, h2)
  return x1 < x2 + w2 and
  x2 < x1 and
  y1 < y2 + h2 and
  y2 < y1
end

local function _circleOverlapsCircle(x1, y1, r1, x2, y2, r2)
  return _dist2d(x1, y1, x2, y2) <= r1 + r2
end

local function _pointOverlapsCircle(x1, y1, x2, y2, r2)
  return _dist2d(x1, y1, x2, y2) <= r2
end

local function _circleOverlapsRect(x1, y1, r1, x2, y2, w2, h2)
  return _pointOverlapsRect(x1, y1, x2, y2, w2, h2) or
    _pointOverlapsCircle(x2, y2, x1, y1, r1) or
    _pointOverlapsCircle(x2 + w2, y2, x1, y1, r1) or
    _pointOverlapsCircle(x2 + w2, y2 + h2, x1, y1, r1) or
    _pointOverlapsCircle(x2, y2 + h2, x1, y1, r1)
end

local function _imageOverlapsRect(x, y, w, h, data, x2, y2, w2, h2)
  if _rectOverlapsRect(x, y, w, h, x2, y2, w2, h2) then
    local neww, newh = w-1, h-1
    for xi=_clamp(_floor(x2-x), 0, neww), _clamp(_ceil(x2-x)+w2, 0, neww) do
      for yi=_clamp(_floor(y2-y), 0, newh), _clamp(_ceil(y2-y)+h2, 0, newh) do
        local _, _, _, a = data:getPixel(xi, yi)
        if a > 0 and _rectOverlapsRect(x + xi, y + yi, 1, 1, x2, y2, w2, h2) then
          return true
        end
      end
    end
  end
  return false
end

local function _imageOverlapsCircle(x, y, w, h, data, x2, y2, r2)
  if _circleOverlapsRect(x2, y2, r2, x, y, w, h) then
    local neww, newh = w-1, h-1
    
    for xi=_clamp(_floor(x2-x)-r2, 0, neww), _clamp(_ceil(x2-x)+r2, 0, neww) do
      for yi=_clamp(_floor(y2-y)-r2, 0, newh), _clamp(_ceil(y2-y)+r2, 0, newh) do
        local _, _, _, a = data:getPixel(xi, yi)
        if a > 0 and _circleOverlapsRect(x2, y2, r2, x + xi, y + yi, 1, 1) then
          return true
        end
      end
    end
  end
  return false
end

local function _imageOverlapsImage(x, y, w, h, data, x2, y2, w2, h2, data2)
  if _rectOverlapsRect(x, y, w, h, x2, y2, w2, h2) then
    local neww, newh = w-1, h-1
    local neww2, newh2 = w2-1, h2-1
    
    for xi=_clamp(_floor(x2-x), 0, neww), _clamp(_ceil(x2-x)+w2, 0, neww) do
      for yi=_clamp(_floor(y2-y), 0, newh), _clamp(_ceil(y2-y)+h2, 0, newh) do
        for xi2=_clamp(_floor(x-x2), 0, neww2), _clamp(_ceil(x-x2)+w, 0, neww2) do
          for yi2=_clamp(_floor(y-y2), 0, newh2), _clamp(_ceil(y-y2)+h, 0, newh2) do
            local _, _, _, a = data:getPixel(xi, yi)
            local _, _, _, a2 = data2:getPixel(xi2, yi2)
            if a > 0 and a2 > 0 and _rectOverlapsRect(x + xi, y + yi, 1, 1, x2 + xi2, y2 + yi2, 1, 1) then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

-- Entity collision checks.

local _entityCollision = {
    {
      function(self, e, x, y)
          return _rectOverlapsRect(self.x + (x or 0), self.y + (y or 0),
            self.collisionShape.w, self.collisionShape.h,
            e.x, e.y, e.collisionShape.w, e.collisionShape.h)
        end,
      function(self, e, x, y)
          return _imageOverlapsRect(e.x, e.y, e.collisionShape.w, e.collisionShape.h, e.collisionShape.data,
            self.x + (x or 0), self.y + (y or 0), self.collisionShape.w, self.collisionShape.h)
        end,
      function(self, e, x, y)
          return _circleOverlapsRect(e.x, e.y, e.collisionShape.r,
            self.x + (x or 0), self.y + (y or 0), self.collisionShape.w, self.collisionShape.h)
        end
    },
    {
      function(self, e, x, y)
          return _imageOverlapsRect(self.x + (x or 0), self.y + (y or 0),
            self.collisionShape.w, self.collisionShape.h, self.collisionShape.data,
            e.x, e.y, e.collisionShape.w, e.collisionShape.h)
        end,
      function(self, e, x, y)
          return _imageOverlapsImage(self.x + (x or 0), self.y + (y or 0),
            self.collisionShape.w, self.collisionShape.h, self.collisionShape.data,
            e.x, e.y, e.collisionShape.w, e.collisionShape.h, e.collisionShape.data)
        end,
      function(self, e, x, y)
          return _imageOverlapsCircle(self.x + (x or 0), self.y + (y or 0),
            self.collisionShape.w, self.collisionShape.h, self.collisionShape.data,
            e.x, e.y, e.collisionShape.r)
        end
    },
    {
      function(self, e, x, y)
          return _circleOverlapsRect(self.x + (x or 0), self.y + (y or 0), self.collisionShape.r,
            e.x, e.y, e.collisionShape.w, e.collisionShape.h)
        end,
      function(self, e, x, y)
          return _imageOverlapsCircle(e.x, e.y, e.collisionShape.w, e.collisionShape.h, e.collisionShape.data,
            self.x + (x or 0), self.y + (y or 0), self.collisionShape.r)
        end,
      function(self, e, x, y)
          return _circleOverlapsCircle(self.x + (x or 0), self.y + (y or 0), self.collisionShape.r,
            e.x, e.y, e.collisionShape.r)
        end
    }
  }

-- Entity processing system.

function entitySystem:init()
  self.entities = {}
  self.updates = {}
  self.groups = {}
  self.static = {}
  self.all = {}
  self.addQueue = {}
  self.removeQueue = {}
  self.readyQueue = {}
  self.recycle = {}
  self.hashes = {}
  self._HS =  {}
  self.doSort = false
  self.inLoop = false
  self.drawCollision = false
end

function entitySystem:updateHashForEntity(e)
  if e.collisionShape and not e.invisibleToHash then
    if not e.currentHashes then
      e.currentHashes = {}
    end
    
    local xx, yy, ww, hh = e.x, e.y, e.collisionShape.w, e.collisionShape.h
    local hs = entitySystem.HASH_SIZE
    local cx, cy = _floor((xx - 2) / hs), _floor((yy - 2) / hs)
    local cx2, cy2 = _floor((xx + ww + 2) / hs), _floor((yy + hh + 2) / hs)
    local emptyBefore = #e.currentHashes == 0
    local check = {}
    
    for x = cx, cx2 do
      for y = cy, cy2 do
        if not self.hashes[x] then
          self.hashes[x] = {[y] = {x = x, y = y, data = {e}, isRemoved = false}}
          self._HS[x] = 1
        elseif not self.hashes[x][y] then
          self.hashes[x][y] = {x = x, y = y, data = {e}, isRemoved = false}
          self._HS[x] = self._HS[x] + 1
        elseif not _icontains(self.hashes[x][y].data, e) then
          self.hashes[x][y].data[#self.hashes[x][y].data+1] = e
          self.hashes[x][y].data[#self.hashes[x][y].data].isRemoved = false
        end
        
        if not _icontains(e.currentHashes, self.hashes[x][y]) then
          e.currentHashes[#e.currentHashes+1] = self.hashes[x][y]
        end
        
        if self.hashes[x] and self.hashes[x][y] then
          check[#check + 1] = self.hashes[x][y]
        end
      end
    end
    
    if not emptyBefore then
      for _, v in ipairs(e.currentHashes) do
        if v.isRemoved or not _icontains(check, v) then
          if not v.isRemoved then
            _quickRemoveValueArray(v.data, e)
            
            if #v.data == 0 then
              v.isRemoved = true
              self.hashes[v.x][v.y] = nil
              self._HS[v.x] = self._HS[v.x] - 1
              
              if self._HS[v.x] == 0 then
                self.hashes[v.x] = nil
                self._HS[v.x] = nil
              end
            end
          end
          
          _quickRemoveValueArray(e.currentHashes, v)
        end
      end
    end
  elseif e.currentHashes and #e.currentHashes ~= 0 then -- If there's no collision, then remove from hash.
    for i = 1, #e.currentHashes do
      local v = e.currentHashes[i]
      
      if not v.isRemoved then
        _quickRemoveValueArray(v.data, e)
        
        if #v.data == 0 then
          v.isRemoved = true
          self.hashes[v.x][v.y] = nil
          self._HS[v.x] = self._HS[v.x] - 1
          
          if self._HS[v.x] == 0 then
            self.hashes[v.x] = nil
            self._HS[v.x] = nil
          end
        end
      end
    end
    
    e.currentHashes = nil
  end
end

function entitySystem:getSurroundingEntities(xx, yy, ww, hh)
  local result
  local hs = entitySystem.HASH_SIZE
  
  for x = _floor((xx - 2) / hs), _floor((xx + ww + 2) / hs) do
    for y = _floor((yy - 2) / hs), _floor((yy + hh + 2) / hs) do
      if self.hashes[x] and self.hashes[x][y] then
        local hash = self.hashes[x][y]
        
        if not result and #hash.data > 0 then
          result = {unpack(hash.data)}
        else
          for i = 1, #hash.data do
            if not _icontains(result, hash.data[i]) then
              result[#result+1] = hash.data[i]
            end
          end
        end
      end
    end
  end
  
  return result or {}
end

function entitySystem:emptyRecycling(c, num)
  if not num or num < 1 then
    self.recycling[c] = {}
  elseif num < self.recycling[c] then
    for i=num, #self.recycling[c] do
      self.recycling[c][i] = nil
    end
  end
end

function entitySystem:getRecycled(c, ...)
  if not c then error("Class does not exist.") end
  
  local e
  local vr = self.recycle[c]
  
  if vr and #vr > 0 then
    e = vr[#vr]
    e.recycling = true
    e:init(...)
    e.recycling = false
    vr[#vr] = nil
  end
  
  if not e then e = c(...) end
  
  return e
end

function entitySystem:sortLayers()
  local keys = {}
  local vals = {}
  
  for k, v in pairs(self.entities) do
    keys[#keys + 1] = v._layer
    vals[v._layer] = v
    self.entities[k] = nil
  end
  
  table.sort(keys)
  
  for i=1, #keys do
    self.entities[i] = vals[keys[i]]
  end
end

function entitySystem:getLayer(l)
  for i=1, #self.entities do
    local v = self.entities[i]
    
    if v._layer == l then
      return v
    end
  end
end

function entitySystem:add(c, ...)
  local e = self:getRecycled(c, ...)
  
  if not e.static then
    local done = false
    
    for i=1, #self.entities do
      local v = self.entities[i]
      if v._layer == e._layer then
        v.data[#v.data + 1] = e
        done = true
        break
      end
    end
    
    if not done then
      self.entities[#self.entities + 1] = {layer = e._layer, data = {e}}
      self.doSort = true
    end
    
    self.updates[#self.updates + 1] = e
  else
    self.static[#self.static + 1] = e
  end
  
  self.all[#self.all+1] = e
  
  for i = 1, #e.groupNames do
    self:addToGroup(e, e.groupNames[i])
  end
  
  e.isRemoved = false
  e.isAdded = true
  e.justAddedIn = true
  e.lastHashX = nil
  e.lastHashY = nil
  e.lastHashX2 = nil
  e.lastHashY2 = nil
  e.system = self
  e.currentHashes = nil
  if not e.invisibleToHash then e:updateHash(true) end
  e:added()
  
  if self.inLoop then
    e:begin()
  else
    self.readyQueue[#self.readyQueue + 1] = e
  end
  
  e.previousX = e.x
  e.previousY = e.y
  
  if e.calcGrav then
    e:calcGrav()
  end
  
  return e
end

function entitySystem:addExisting(e)
  if e.isAdded then return e end
  if not e then return end
  
  if not e.static then
    local done = false
    
    for i=1, #self.entities do
      local v = self.entities[i]
      if v._layer == e._layer then
        v.data[#v.data + 1] = e
        done = true
        break
      end
    end
    
    if not done then
      self.entities[#self.entities + 1] = {layer = e._layer, data = {e}}
      self.doSort = true
    end
    
    self.updates[#self.updates + 1] = e
  else
    self.static[#self.static + 1] = e
  end
  
  self.all[#self.all+1] = e
  
  for i = 1, #e.groupNames do
    self:addToGroup(e, e.groupNames[i])
  end
  
  e.isRemoved = false
  e.isAdded = true
  e.justAddedIn = true
  e.lastHashX = nil
  e.lastHashY = nil
  e.lastHashX2 = nil
  e.lastHashY2 = nil
  e.system = self
  e.currentHashes = nil
  if not e.invisibleToHash then e:updateHash(true) end
  e:added()
  
  if self.inLoop then
    e:begin()
  else
    self.readyQueue[#self.readyQueue + 1] = e
  end
  
  e.previousX = e.x
  e.previousY = e.y
  
  if e.calcGrav then
    e:calcGrav()
  end
  
  return e
end

function entitySystem:queueAdd(c, ...)
  if not c then return end
  self.addQueue[#self.addQueue + 1] = self:getRecycled(c, ...)
  return self.addQueue[#self.addQueue]
end

function entitySystem:queueAddExisting(e)
  if not e or not e.isRemoved or e.isAdded or _icontains(self.addQueue, e) then return end
  self.addQueue[#self.addQueue + 1] = e
  return self.addQueue[#self.addQueue]
end

function entitySystem:addToGroup(e, g)
  if not self.groups[g] then
    self.groups[g] = {}
  end
  
  if not _icontains(self.groups[g], e) then
    self.groups[g][#self.groups[g] + 1] = e
  end
  
  if not _icontains(e.groupNames, g) then
    e.groupNames[#e.groupNames + 1] = g
  end
end

function entitySystem:removeFromGroup(e, g)
  _quickRemoveValueArray(self.groups[g], e)
  _quickRemoveValueArray(e.groupNames, g)
  
  if #self.groups[g] == 0 then
    self.groups[g] = nil
  end
end

function entitySystem:removeFromAllGroups(e)
  for k, _ in pairs(self.groups) do
    self:removeFromGroup(e, k)
  end
end

function entitySystem:makeStatic(e)
  if not e.static then
    _quickRemoveValueArray(self.updates, e)
    
    local al = self:getLayer(e._layer)
    
    _quickRemoveValueArray(al.data, e)
    
    if #al.data == 0 then
      _removeValueArray(self.entities, al)
    end
    
    self.static[#self.static + 1] = e
    
    e.static = true
    e.staticX = e.x
    e.staticY = e.y
    if e.collisionShape then
      e.staticW = e.collisionShape.w
      e.staticH = e.collisionShape.h
    end
    
    e.lastHashX = nil
    e.lastHashY = nil
    e.lastHashX2 = nil
    e.lastHashY2 = nil
    e.currentHashes = nil
    
    e:staticToggled()
  end
end

function entitySystem:revertFromStatic(e)
  if e.static then
    _quickRemoveValueArray(self.static, e)
    
    local done = false
    
    for i=1, #self.entities do
      local v = self.entities[i]
      if v._layer == e._layer then
        v.data[#v.data + 1] = e
        done = true
        break
      end
    end
    
    if not done then
      self.entities[#self.entities + 1] = {layer = e._layer, data = {e}}
      self.doSort = true
    end
    
    self.updates[#self.updates + 1] = e
    
    if e.collisionShape and e.staticX == e.x and e.staticY == e.y and
      e.staticW == e.collisionShape.w and e.staticH == e.collisionShape.h then
      local xx, yy, ww, hh = e.x, e.y, e.collisionShape.w, e.collisionShape.h
      local hs = entitySystem.HASH_SIZE
      local cx, cy = _floor((xx - 2) / hs), _floor((yy - 2) / hs)
      local cx2, cy2 = _floor((xx + ww + 2) / hs), _floor((yy + hh + 2) / hs)
      
      for x = cx, cx2 do
        for y = cy, cy2 do
          if self.hashes[x] and self.hashes[x][y] and not self.hashes[x][y].isRemoved then
            _quickRemoveValueArray(self.hashes[x][y].data, e)
            
            if #self.hashes[x][y].data == 0 then
              self.hashes[x][y].isRemoved = true
              self.hashes[x][y] = nil
              self._HS[x] = self._HS[x] - 1
              
              if self._HS[x] == 0 then
                self.hashes[x] = nil
                self._HS[x] = nil
              end
            end
          end
        end
      end
    else
      for x, xt in pairs(self.hashes) do
        for y, yt in pairs(xt) do
          if _icontains(yt.data, e) then
            _quickRemoveValueArray(yt.data, e)
          end
          
          if #yt.data == 0 and not yt.isRemoved then
            yt.isRemoved = true
            self.hashes[x][y] = nil
            self._HS[x] = self._HS[x] - 1
            
            if self._HS[x] == 0 then
              self.hashes[x] = nil
              self._HS[x] = nil
            end
          end
        end
      end
    end
    
    e.static = false
    e.staticX = nil
    e.staticY = nil
    e.staticW = nil
    e.staticH = nil
    e.lastHashX = nil
    e.lastHashY = nil
    e.lastHashX2 = nil
    e.lastHashY2 = nil
    e.currentHashes = nil
    
    if not e.invisibleToHash then
      e:updateHash()
    end
    
    e:staticToggled()
  end
end

function entitySystem:setLayer(e, l)
  if e._layer ~= l then
    if not e.isAdded or e.static then
      e._layer = l
    else
      local al = self:getLayer(e._layer)
      
      _quickRemoveValueArray(al.data, e)
      
      if #al.data == 0 then
        _removeValueArray(self.entities, al)
      end
      
      e._layer = l
      
      local done = false
      
      for i=1, #self.entities do
        local v = self.entities[i]
        
        if v._layer == e._layer then
          v.data[#v.data + 1] = e
          done = true
          break
        end
      end
      
      if not done then
        self.entities[#self.entities + 1] = {layer = e._layer, data = {e}}
        self.doSort = true
      end
    end
  end
end

function entitySystem:remove(e)
  if not e or e.isRemoved then return end
  
  e.isRemoved = true
  e:removed()
  self:removeFromAllGroups(e)
  
  local al = self:getLayer(e._layer)
  
  if e.static then
    _quickRemoveValueArray(self.static, e)
  else
    _quickRemoveValueArray(al.data, e)
    _quickRemoveValueArray(self.updates, e)
  end
  
  if not e.static and #al.data == 0 then
    _removeValueArray(self.entities, al)
  end
  
  _quickRemoveValueArray(self.all, e)
  _quickRemoveValueArray(self.readyQueue, e)
  
  if e.currentHashes then
    for _, v in ipairs(e.currentHashes) do
      if not v.isRemoved then
        _quickRemoveValueArray(v.data, e)
        
        if #v.data == 0 then
          v.isRemoved = true
          self.hashes[v.x][v.y] = nil
          self._HS[v.x] = self._HS[v.x] - 1
          
          if self._HS[v.x] == 0 then
            self.hashes[v.x] = nil
            self._HS[v.x] = nil
          end
        end
      end
    end
  elseif e.static then
    if e.collisionShape and e.staticX == e.x and e.staticY == e.y and
      e.staticW == e.collisionShape.w and e.staticH == e.collisionShape.h then
      local xx, yy, ww, hh = e.x, e.y, e.collisionShape.w, e.collisionShape.h
      local hs = entitySystem.HASH_SIZE
      local cx, cy = _floor((xx - 2) / hs), _floor((yy - 2) / hs)
      local cx2, cy2 = _floor((xx + ww + 2) / hs), _floor((yy + hh + 2) / hs)
      
      for x = cx, cx2 do
        for y = cy, cy2 do
          if self.hashes[x] and self.hashes[x][y] and not self.hashes[x][y].isRemoved then
            _quickRemoveValueArray(self.hashes[x][y].data, e)
            
            if #self.hashes[x][y].data == 0 then
              self.hashes[x][y].isRemoved = true
              self.hashes[x][y] = nil
              self._HS[x] = self._HS[x] - 1
              
              if self._HS[x] == 0 then
                self.hashes[x] = nil
                self._HS[x] = nil
              end
            end
          end
        end
      end
    else
      for x, xt in pairs(self.hashes) do
        for y, yt in pairs(xt) do
          _quickRemoveValueArray(yt.data, e)
          
          if #yt.data == 0 and not yt.isRemoved then
            yt.isRemoved = true
            self.hashes[x][y] = nil
            self._HS[x] = self._HS[x] - 1
            
            if self._HS[x] == 0 then
              self.hashes[x] = nil
              self._HS[x] = nil
            end
          end
        end
      end
    end
  end
  
  e.lastHashX = nil
  e.lastHashY = nil
  e.lastHashX2 = nil
  e.lastHashY2 = nil
  e.currentHashes = nil
  e.system = nil
  
  e.isAdded = false
  e.justAddedIn = false
  
  if e.recycle then
    if not self.recycle[e.__class] then
      self.recycle[e.__class] = {e}
    elseif not _icontains(self.recycle[e.__class], e) then
      self.recycle[e.__class][#self.recycle[e.__class] + 1] = e
    end
  end
end

function entitySystem:queueRemove(e)
  if not e or e.isRemoved or _icontains(self.removeQueue, e) then return end
  self.removeQueue[#self.removeQueue+1] = e
end

function entitySystem:clear()
  for _, v in ipairs(self.all) do
    self:remove(v)
  end
  
  self.all = {}
  section.sections = {}
  section.current = nil
  self.entities = {}
  self.updates = {}
  self.groups = {}
  self.static = {}
  self.addQueue = {}
  self.removeQueue = {}
  self.hashes = {}
  self._HS = {}
  self.doSort = false
  self.readyQueue = {}
  
  collectgarbage()
  collectgarbage()
end

function entitySystem:draw()
  for i=1, #self.entities do
    for k=1, #self.entities[i].data do
      if states.switched then
        return
      end
      local v = self.entities[i].data[k]
      if v.canDraw and not v.isRemoved and v.draw then
        love.graphics.setColor(1, 1, 1, 1)
        v:_draw()
      end
    end
  end
  if entitySystem.drawCollision and not states.switched then
    love.graphics.setColor(1, 1, 1, 1)
    for i=1, #self.entities do
      for k=1, #self.entities[i].data do
        self.entities[i].data[k]:drawCollision()
      end
    end
  end
end

function entitySystem:update(dt)
  while self.readyQueue[1] do
    self.readyQueue[1]:ready()
    _remove(self.readyQueue, 1)
  end
  
  self.inLoop = true
  
  for i=1, #self.updates do
    if states.switched then
      return
    end
    
    local v = self.updates[i]
    v.previousX = v.x
    v.previousY = v.y
    
    if not v.isRemoved and v.beforeUpdate and v.canUpdate then
      v:beforeUpdate(dt)
      if not v.invisibleToHash then v:updateHash() end
    end
  end
  
  for i=1, #self.updates do
    if states.switched then
      return
    end
    
    local v = self.updates[i]
    
    if not v.isRemoved and v.update and v.canUpdate then
      v:update(dt)
      if not v.invisibleToHash then v:updateHash() end
    end
  end
  
  for i=1, #self.updates do
    if states.switched then
      return
    end
    
    local v = self.updates[i]
    
    if not v.isRemoved and v.afterUpdate and v.canUpdate then
      v:afterUpdate(dt)
      if not v.invisibleToHash then v:updateHash() end
    end
    
    v.justAddedIn = false
  end
  
  self.inLoop = false
  
  if states.switched then
    return
  end
  
  for i=#self.removeQueue, 1, -1 do
    self:remove(self.removeQueue[i])
    self.removeQueue[i] = nil
  end
  
  for i=#self.addQueue, 1, -1 do
    self:addExisting(self.addQueue[i])
    self.addQueue[i] = nil
  end
  
  if self.doSort then
    self.doSort = false
    self:sortLayers()
  end
end

-- Base entity class.

entity = class:extend()

function entity:init()
  if not self.recycling then
    self.collisionShape = nil
    self._layer = 1
    self.isRemoved = true
    self.isAdded = false
    self.recycle = false
  end
  
  self.system = nil
  self.currentHashes = nil
  self.groupNames = {}
  self.x = 0
  self.y = 0
  self.canUpdate = true
  self.canDraw = true
end

function entity:setLayer(l)
  if self.system then
    self.system:setLayer(self, l)
  else
    self._layer = l
  end
end

function entity:getLayer()
  return self._layer
end

function entity:makeStatic()
  if self.system then
    self.system:makeStatic(self)
  else
    self.static = true
    self.staticX = self.x
    self.staticY = self.y
    if self.collisionShape then
      self.staticW = self.collisionShape.w
      self.staticH = self.collisionShape.h
    end
    
    self.lastHashX = nil
    self.lastHashY = nil
    self.lastHashX2 = nil
    self.lastHashY2 = nil
    self.currentHashes = nil
    
    self:staticToggled()
  end
end

function entity:revertFromStatic()
  if self.system then
    self.system:revertFromStatic(self)
  else
    self.static = false
    self.staticX = nil
    self.staticY = nil
    self.staticW = nil
    self.staticH = nil
    self.lastHashX = nil
    self.lastHashY = nil
    self.lastHashX2 = nil
    self.lastHashY2 = nil
    self.currentHashes = nil
    
    self:staticToggled()
  end
end

function entity:removeFromGroup(g)
  if self.system then
    self.system:removeFromGroup(self, g)
  else
    _quickRemoveValueArray(self.groupNames, g)
  end
end

function entity:inGroup(g)
  return _icontains(self.groupNames, g)
end

function entity:removeFromAllGroups()
  if self.system then
    self.system:removeFromAllGroups(self, g)
  else
    self.groupNames = {}
  end
end

function entity:addToGroup(g)
  if self.system then
    self.system:addToGroup(self, g)
  elseif not _icontains(self.groupNames, g) then
    self.groupNames[#self.groupNames + 1] = g
  end
end

function entity:getGroup(name)
  assert(self.system, "Entity system not found. Cannot retrieve any group.")
  
  return self.system.groups[names]
end

function entity:setRectangleCollision(w, h)
  if not self.collisionShape then
    self.collisionShape = {}
  end
  
  self.collisionShape.type = entitySystem.COL_RECT
  self.collisionShape.w = w or 1
  self.collisionShape.h = h or 1
  
  self.collisionShape.r = nil
  self.collisionShape.data = nil
  
  self:updateHash()
end

entity._imgCache = {}

function entity:setImageCollision(data)
  if not self.collisionShape then
    self.collisionShape = {}
  end
  
  self.collisionShape.type = entitySystem.COL_IMAGE
  self.collisionShape.w = data:getWidth()
  self.collisionShape.h = data:getHeight()
  self.collisionShape.data = data
  
  if not entity._imgCache[self.collisionShape.data] then
    entity._imgCache[self.collisionShape.data] = love.graphics.newImage(self.collisionShape.data)
  end
  
  self.collisionShape.image = entity._imgCache[self.collisionShape.data]
  
  self.collisionShape.r = nil
  
  self:updateHash()
end

function entity:setCircleCollision(r)
  if not self.collisionShape then
    self.collisionShape = {}
  end
  
  self.collisionShape.type = entitySystem.COL_CIRCLE
  self.collisionShape.w = (r or 1) * 2
  self.collisionShape.h = (r or 1) * 2
  self.collisionShape.r = r or 1
  
  self.collisionShape.data = nil
  
  self:updateHash()
end

function entity:collision(e, x, y, notme)
  return e and (not notme or e ~= self) and self.collisionShape and e.collisionShape and
    _entityCollision[self.collisionShape.type][e.collisionShape.type](self, e, x, y)
end

function entity:drawCollision()
  if self.collisionShape.type == entitySystem.COL_RECT then
    love.graphics.rectangle("line", _floor(self.x), _floor(self.y),
      self.collisionShape.w, self.collisionShape.h)
  elseif self.collisionShape.type == entitySystem.COL_IMAGE then
    self.collisionShape.image:draw(_floor(self.x), _floor(self.y))
  elseif self.collisionShape.type == entitySystem.COL_CIRCLE then
    love.graphics.circle("line", _floor(self.x), _floor(self.y), self.collisionShape.r)
  end
end

function entity:collisionTable(t, x, y, notme, func)
  local result = {}
  if not t then return result end
  for i=1, #t do
    local v = t[i]
    if self:collision(v, x, y, notme) and (func == nil or func(v)) then
      result[#result+1] = v
    end
  end
  return result
end

function entity:collisionNumber(t, x, y, notme, func)
  local result = 0
  if not t then return result end
  for i=1, #t do
    if self:collision(t[i], x, y, notme) and (func == nil or func(t[i])) then
      result = result + 1
    end
  end
  return result
end

function entity:updateHash(doAnyway)
  if (doAnyway or self.isAdded) and self.collisionShape then
    local xx, yy, ww, hh = self.x, self.y, self.collisionShape.w, self.collisionShape.h
    local hs = entitySystem.HASH_SIZE
    local cx, cy = _floor((xx - 2) / hs), _floor((yy - 2) / hs)
    local cx2, cy2 = _floor((xx + ww + 2) / hs), _floor((yy + hh + 2) / hs)
    
    if doAnyway or self.lastHashX ~= cx or self.lastHashY ~= cy or self.lastHashX2 ~= cx2 or self.lastHashY2 ~= cy2 then
      self.lastHashX = cx
      self.lastHashY = cy
      self.lastHashX2 = cx2
      self.lastHashY2 = cy2
      
      self.system:updateHashForEntity(self)
    end
  end
end

function entity:getSurroundingEntities(dxx, dyy)
  if self.invisibleToHash then
    return {}
  end
  
  if dxx or dyy or not self.currentHashes then
    local dx, dy = dxx or 0, dyy or 0
    local xx, yy, ww, hh = self.x - _min(dx, 0), self.y - _min(dy, 0),
      self.collisionShape.w + _max(dx, 0), self.collisionShape.h + _max(dy, 0)
    
    return self.system.getSurroundingEntities(xx, yy, ww, hh)
  end
  
  self:updateHash()
  
  local result = self.currentHashes[1] and {unpack(self.currentHashes[1].data)} or {}
  
  for i = 2, #self.currentHashes do
    for j = 1, #self.currentHashes[i].data do
      if not _icontains(result, self.currentHashes[i].data[j]) then
        result[#result + 1] = self.currentHashes[i].data[j]
      end
    end
  end
  
  return result
end

function entity:remove()
  if self.system then
    self.system:remove(self)
  elseif not e.isRemoved then
    e.isRemoved = true
    e:removed()
    self:removeFromAllGroups()
    
    e.lastHashX = nil
    e.lastHashY = nil
    e.lastHashX2 = nil
    e.lastHashY2 = nil
    e.currentHashes = nil
    
    e.isAdded = false
    e.justAddedIn = false
  end
end

function entity:ready() end
function entity:beforeUpdate(dt) end
function entity:update(dt) end
function entity:afterUpdate(dt) end
function entity:draw() end
function entity:added() end
function entity:removed() end
function entity:staticToggled() end

return entitySystem, entity