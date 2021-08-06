-- Constants.

local entitySystem = {}

entitySystem.HASH_SIZE = 96
entitySystem.COL_RECT = 1
entitySystem.COL_IMAGE = 2
entitySystem.COL_CIRCLE = 3

-- Important util functions.

local _floor = math.floor
local _ceil = math.ceil
local _sqrt = math.sqrt
local _min = math.min
local _max = math.max
local _remove = table.remove

local function _dist2d(x, y, x2, y2)
  return _sqrt(((x - x2) ^ 2) + ((y - y2) ^ 2))
end

local function _clamp(v, min, max)
  return _min(_max(v, max), min)
end

local function _contains(t, va)
  for _, v in pairs(t) do
    if v == va then
      return true
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

local function _imageOverlapsRect(x, y, data, x2, y2, w2, h2)
  if _rectOverlapsRect(x, y, data:getWidth(), data:getHeight(), x2, y2, w2, h2) then
    local neww, newh = data:getWidth()-1, data:getHeight()-1
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

local function _imageOverlapsCircle(x, y, data, x2, y2, r2)
  if _circleOverlapsRect(x2, y2, r2, x, y, data:getWidth(), data:getHeight()) then
    local neww, newh = data:getWidth()-1, data:getHeight()-1
    
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

local function _imageOverlapsImage(x, y, data, x2, y2, data2)
  if _rectOverlapsRect(x, y, data:getWidth(), data:getHeight(), x2, y2, data2:getWidth(), data2:getHeight()) then
    local neww, newh = data:getWidth()-1, data:getHeight()-1
    local neww2, newh2 = data2:getWidth()-1, data2:getHeight()-1
    
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
      function(e, other, x, y)
          return _rectOverlapsRect(e.position.x + (x or 0), e.position.y + (y or 0),
            e.collisionShape.w, e.collisionShape.h,
            other.position.x, other.position.y, other.collisionShape.w, other.collisionShape.h)
        end,
      function(e, other, x, y)
          return _imageOverlapsRect(other.position.x, other.position.y, other.collisionShape.data,
            e.position.x + (x or 0), e.position.y + (y or 0), e.collisionShape.w, e.collisionShape.h)
        end,
      function(e, other, x, y)
          return _circleOverlapsRect(other.position.x, other.position.y, other.collisionShape.r,
            e.position.x + (x or 0), e.position.y + (y or 0), e.collisionShape.w, e.collisionShape.h)
        end
    },
    {
      function(e, other, x, y)
          return _imageOverlapsRect(e.position.x + (x or 0), e.position.y + (y or 0), e.collisionShape.data,
            other.position.x, other.position.y, other.collisionShape.w, other.collisionShape.h)
        end,
      function(e, other, x, y)
          return _imageOverlapsImage(e.position.x + (x or 0), e.position.y + (y or 0), e.collisionShape.data,
            other.position.x, other.position.y, other.collisionShape.data)
        end,
      function(e, other, x, y)
          return _imageOverlapsCircle(e.position.x + (x or 0), e.position.y + (y or 0), e.collisionShape.data,
            other.position.x, other.position.y, other.collisionShape.r)
        end
    },
    {
      function(e, other, x, y)
          return _circleOverlapsRect(e.position.x + (x or 0), e.position.y + (y or 0), e.collisionShape.r,
            other.position.x, other.position.y, other.collisionShape.w, other.collisionShape.h)
        end,
      function(e, other, x, y)
          return _imageOverlapsCircle(other.position.x, other.position.y, other.collisionShape.data,
            e.position.x + (x or 0), e.position.y + (y or 0), e.collisionShape.r)
        end,
      function(e, other, x, y)
          return _circleOverlapsCircle(e.position.x + (x or 0), e.position.y + (y or 0), e.collisionShape.r,
            other.position.x, other.position.y, other.collisionShape.r)
        end
    }
  }

-- Entity processing system.

function entitySystem:init()
  self.layers = {}
  self.updates = {}
  self.groups = {}
  self.static = {}
  self.all = {}
  self.addQueue = {}
  self.removeQueue = {}
  self.readyQueue = {}
  self.hashes = {}
  self._HS =  {}
  self._doSort = false
  self.inLoop = false
  self.drawCollision = false
  self._imgCache = {}
end

function entitySystem:update(dt)
  while self.readyQueue[1] do
    if self.readyQueue[1].ready then self.readyQueue[1]:ready() end
    _remove(self.readyQueue, 1)
  end
  
  self.inLoop = true
  
  for _, e in ipairs(self.updates) do
    e.previousX = e.position.x
    e.previousY = e.position.y
    
    if e.beforeUpdate and e.canUpdate then
      e:beforeUpdate(dt)
    end
    if not e.invisibleToHash then self:updateEntityHashWhenNeeded(e) end
  end
  
  for _, e in ipairs(self.updates) do    
    if e.update and e.canUpdate then
      e:update(dt)
    end
    if not e.invisibleToHash then self:updateEntityHashWhenNeeded(e) end
  end
  
  for _, e in ipairs(self.updates) do
    if e.afterUpdate and e.canUpdate then
      e:afterUpdate(dt)
    end
    if not e.invisibleToHash then self:updateEntityHashWhenNeeded(e) end
    
    e.justAddedIn = false
  end
  
  self.inLoop = false
  
  for i=#self.removeQueue, 1, -1 do
    self:remove(self.removeQueue[i])
    self.removeQueue[i] = nil
  end
  
  for i=#self.addQueue, 1, -1 do
    self:addExisting(self.addQueue[i])
    self.addQueue[i] = nil
  end
end

function entitySystem:draw()
  if self._doSort then
    self._doSort = false
    self:_sortLayers()
  end
  
  for _, layer in ipairs(self.layers) do
    for _, e in ipairs(layer.data) do
      if e.draw and e.canDraw then
        love.graphics.setColor(1, 1, 1, 1)
        e:draw()
      end
    end
  end
  
  if self.drawCollision then
    love.graphics.setColor(1, 1, 1, 1)
    for _, layer in ipairs(self.layers) do
      for _, e in ipairs(layer.data) do
        self:drawCollision(e)
      end
    end
  end
end

function entitySystem:add(e)
  self:_conform(e)
  
  if not e.static then
    local done = false
    
    for i=1, #self.layers do
      local v = self.layers[i]
      if v.layer == e._layer then
        v.data[#v.data + 1] = e
        done = true
        break
      end
    end
    
    if not done then
      self.layers[#self.layers + 1] = {layer = e._layer, data = {e}}
      self._doSort = true
    end
    
    self.updates[#self.updates + 1] = e
  else
    self.static[#self.static + 1] = e
  end
  
  self.all[#self.all+1] = e
  
  e.isRemoved = false
  e.isAdded = true
  e.justAddedIn = true
  e.lastHashX = nil
  e.lastHashY = nil
  e.lastHashX2 = nil
  e.lastHashY2 = nil
  e.system = self
  e._currentHashes = nil
  if not e.invisibleToHash then self:updateEntityHashWhenNeeded(e, true) end
  if e.added then e:added() end
  
  if self.inLoop then
    if e.ready then e:ready() end
  else
    self.readyQueue[#self.readyQueue + 1] = e
  end
  
  e.previousX = e.position.x
  e.previousY = e.position.y
  
  return e
end

function entitySystem:queueAdd(e)
  self:_conform(e)
  
  self.addQueue[#self.addQueue + 1] = e
  return self.addQueue[#self.addQueue]
end

function entitySystem:remove(e)
  self:_conform(e)
  
  e.isRemoved = true
  if e.removed then e:removed() end
  self:removeFromAllGroups(e)
  
  local al = self:_getLayerData(e._layer)
  
  if e.static then
    _quickRemoveValueArray(self.static, e)
  else
    _quickRemoveValueArray(al.data, e)
    _quickRemoveValueArray(self.updates, e)
  end
  
  if not e.static and #al.data == 0 then
    _removeValueArray(self.layers, al)
  end
  
  _quickRemoveValueArray(self.all, e)
  _quickRemoveValueArray(self.readyQueue, e)
  
  if e._currentHashes then
    for _, v in ipairs(e._currentHashes) do
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
    if e.collisionShape and e.staticX == e.position.x and e.staticY == e.position.y and
      e.staticW == e.collisionShape.w and e.staticH == e.collisionShape.h then
      local xx, yy, ww, hh = e.position.x, e.position.y, e.collisionShape.w, e.collisionShape.h
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
  e._currentHashes = nil
  e.system = nil
  
  e.isAdded = false
  e.justAddedIn = false
end

function entitySystem:queueRemove(e)
  if not e or e.isRemoved or _icontains(self.removeQueue, e) then return end
  self.removeQueue[#self.removeQueue+1] = e
end

function entitySystem:clear()
  for _, e in ipairs(self.all) do
    self:remove(e)
  end
  
  self.all = {}
  self.layers = {}
  self.updates = {}
  self.groups = {}
  self.static = {}
  self.addQueue = {}
  self.removeQueue = {}
  self.hashes = {}
  self._HS = {}
  self._doSort = false
  self.readyQueue = {}
  
  collectgarbage()
  collectgarbage()
end

function entitySystem:setLayer(e, l)
  self:_conform(e)
  
  if e._layer ~= l then
    if not e.isAdded or e.static then
      e._layer = l
    else
      local al = self:_getLayerData(e._layer)
      
      _quickRemoveValueArray(al.data, e)
      
      if #al.data == 0 then
        _removeValueArray(self.layers, al)
      end
      
      e._layer = l
      
      local done = false
      
      for i=1, #self.layers do
        local v = self.layers[i]
        
        if v.layer == e._layer then
          v.data[#v.data + 1] = e
          done = true
          break
        end
      end
      
      if not done then
        self.layers[#self.layers + 1] = {layer = e._layer, data = {e}}
        self._doSort = true
      end
    end
  end
end

function entitySystem:getLayer(e)
  self:_conform(e)
  
  return e._layer
end

function entitySystem:_sortLayers()
  local keys = {}
  local vals = {}
  
  for k, v in pairs(self.layers) do
    keys[#keys + 1] = v.layer
    vals[v.layer] = v
    self.layers[k] = nil
  end
  
  table.sort(keys)
  
  for i=1, #keys do
    self.layers[i] = vals[keys[i]]
  end
end

function entitySystem:_getLayerData(l)
  for i=1, #self.layers do
    local v = self.layers[i]
    
    if v._layer == l then
      return v
    end
  end
end

function entitySystem:makeStatic(e)
  self:_conform(e)
  
  if not e.static and not e.isRemoved then
    _quickRemoveValueArray(self.updates, e)
    
    local al = self:_getLayerData(e._layer)
    
    _quickRemoveValueArray(al.data, e)
    
    if #al.data == 0 then
      _removeValueArray(self.layers, al)
    end
    
    if not _icontains(self.static, e) then
      self.static[#self.static + 1] = e
    end
    
    e.static = true
    e.staticX = e.position.x
    e.staticY = e.position.y
    if e.collisionShape then
      e.staticW = e.collisionShape.w
      e.staticH = e.collisionShape.h
    end
    
    e.lastHashX = nil
    e.lastHashY = nil
    e.lastHashX2 = nil
    e.lastHashY2 = nil
    e._currentHashes = nil
    
    if e.staticToggled then e:staticToggled() end
  end
end

function entitySystem:revertFromStatic(e)
  self:_conform(e)
  
  if e.static and not e.isRemoved then
    _quickRemoveValueArray(self.static, e)
    
    local done = false
    
    for i=1, #self.layers do
      local v = self.layers[i]
      if v.layer == e._layer then
        v.data[#v.data + 1] = e
        done = true
        break
      end
    end
    
    if not done then
      self.layers[#self.layers + 1] = {layer = e._layer, data = {e}}
      self._doSort = true
    end
    
    self.updates[#self.updates + 1] = e
    
    if e.collisionShape and e.staticX == e.position.x and e.staticY == e.position.y and
      e.staticW == e.collisionShape.w and e.staticH == e.collisionShape.h then
      local xx, yy, ww, hh = e.position.x, e.position.y, e.collisionShape.w, e.collisionShape.h
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
    e._currentHashes = nil
    e.system = self
    
    if not e.invisibleToHash then
      self:updateEntityHashWhenNeeded(e)
    end
    
    if e.staticToggled then e:staticToggled() end
  end
end

function entitySystem:addToGroup(e, g)
  self:_conform(e)
  
  if not self.groups[g] then
    self.groups[g] = {}
  end
  if not _icontains(self.groups[g], e) then
    self.groups[g][#self.groups[g] + 1] = e
  end
end

function entitySystem:removeFromGroup(e, g)
  self:_conform(e)
  
  _quickRemoveValueArray(self.groups[g], e)
  
  if #self.groups[g] == 0 then
    self.groups[g] = nil
  end
end

function entitySystem:removeFromAllGroups(e)
  self:_conform(e)
  
  for k, _ in pairs(self.groups) do
    self:removeFromGroup(e, k)
  end
end

function entitySystem:inGroup(e, g)
  self:_conform(e)
  
  return _icontains(self.groups, g)
end

function entitySystem:setRectangleCollision(e, w, h)
  self:_conform(e)
  
  if not e.collisionShape then
    e.collisionShape = {}
  end
  
  e.collisionShape.type = entitySystem.COL_RECT
  e.collisionShape.w = w or 1
  e.collisionShape.h = h or 1
  
  e.collisionShape.r = nil
  e.collisionShape.data = nil
  
  self:updateEntityHashWhenNeeded(e)
end

function entitySystem:setImageCollision(e, data)
  self:_conform(e)
  
  if not e.collisionShape then
    e.collisionShape = {}
  end
  
  e.collisionShape.type = entitySystem.COL_IMAGE
  e.collisionShape.w = data:getWidth()
  e.collisionShape.h = data:getHeight()
  e.collisionShape.data = data
  
  if not self._imgCache[e.collisionShape.data] then
    self._imgCache[e.collisionShape.data] = love.graphics.newImage(e.collisionShape.data)
  end
  
  e.collisionShape.image = self._imgCache[e.collisionShape.data]
  
  e.collisionShape.r = nil
  
  self:updateEntityHashWhenNeeded(e)
end

function entitySystem:setCircleCollision(e, r)
  self:_conform(e)
  
  if not e.collisionShape then
    e.collisionShape = {}
  end
  
  e.collisionShape.type = entitySystem.COL_CIRCLE
  e.collisionShape.w = (r or 1) * 2
  e.collisionShape.h = (r or 1) * 2
  e.collisionShape.r = r or 1
  
  e.collisionShape.data = nil
  
  self:updateEntityHashWhenNeeded(e)
end

function entitySystem:collision(e, other, x, y, notme)
  self:_conform(e)
  
  return e and other and (not notme or other ~= e) and e.collisionShape and other.collisionShape and
    _entityCollision[e.collisionShape.type][other.collisionShape.type](e, other, x, y)
end

function entitySystem:collisionTable(e, table, x, y, notme, func)
  self:_conform(e)
  
  local result = {}
  if not table then return result end
  for i=1, #table do
    if self:collision(e, table[i], x, y, notme) and (func == nil or func(v)) then
      result[#result+1] = table[i]
    end
  end
  return result
end

function entitySystem:collisionNumber(e, table, x, y, notme, func)
  self:_conform(e)
  
  local result = 0
  if not table then return result end
  for i=1, #table do
    if self:collision(e, table[i], x, y, notme) and (func == nil or func(t[i])) then
      result = result + 1
    end
  end
  return result
end

function entitySystem:drawCollision(e)
  self:_conform(e)
  
  if e.collisionShape.type == entitySystem.COL_RECT then
    love.graphics.rectangle("line", _floor(e.position.x), _floor(e.position.y),
      e.collisionShape.w, e.collisionShape.h)
  elseif e.collisionShape.type == entitySystem.COL_IMAGE then
    e.collisionShape.image:draw(_floor(e.position.x), _floor(e.position.y))
  elseif e.collisionShape.type == entitySystem.COL_CIRCLE then
    love.graphics.circle("line", _floor(e.position.x), _floor(e.position.y), e.collisionShape.r)
  end
end

function entitySystem:updateEntityHash(e)
  self:_conform(e)
  
  if e.collisionShape and not e.invisibleToHash then
    if not e._currentHashes then
      e._currentHashes = {}
    end
    
    local xx, yy, ww, hh = e.position.x, e.position.y, e.collisionShape.w, e.collisionShape.h
    local hs = entitySystem.HASH_SIZE
    local cx, cy = _floor((xx - 2) / hs), _floor((yy - 2) / hs)
    local cx2, cy2 = _floor((xx + ww + 2) / hs), _floor((yy + hh + 2) / hs)
    local emptyBefore = #e._currentHashes == 0
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
        
        if not _icontains(e._currentHashes, self.hashes[x][y]) then
          e._currentHashes[#e._currentHashes+1] = self.hashes[x][y]
        end
        
        if self.hashes[x] and self.hashes[x][y] then
          check[#check + 1] = self.hashes[x][y]
        end
      end
    end
    
    if not emptyBefore then
      for _, v in ipairs(e._currentHashes) do
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
          
          _quickRemoveValueArray(e._currentHashes, v)
        end
      end
    end
  elseif e._currentHashes and #e._currentHashes ~= 0 then -- If there's no collision, then remove from hash.
    for i = 1, #e._currentHashes do
      local v = e._currentHashes[i]
      
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
    
    e._currentHashes = nil
  end
end

function entitySystem:updateEntityHashWhenNeeded(e, doAnyway)
  self:_conform(e)
  
  if (doAnyway or e.isAdded) and e.collisionShape then
    local xx, yy, ww, hh = e.position.x, e.position.y, e.collisionShape.w, e.collisionShape.h
    local hs = entitySystem.HASH_SIZE
    local cx, cy = _floor((xx - 2) / hs), _floor((yy - 2) / hs)
    local cx2, cy2 = _floor((xx + ww + 2) / hs), _floor((yy + hh + 2) / hs)
    
    if doAnyway or e.lastHashX ~= cx or e.lastHashY ~= cy or e.lastHashX2 ~= cx2 or e.lastHashY2 ~= cy2 then
      e.lastHashX = cx
      e.lastHashY = cy
      e.lastHashX2 = cx2
      e.lastHashY2 = cy2
      
      self:updateEntityHash(e)
    end
  end
end

function entitySystem:getEntitiesAt(xx, yy, ww, hh)
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

function entitySystem:getSurroundingEntities(e, extentsLeft, extentsRight, extentsUp, extentsDown)
  self:_conform(e)
  assert(extentsLeft < 0 or extentsRight < 0 or extentsUp < 0 or extentsDown < 0, "Extents must be positive!")
  
  if e.invisibleToHash then
    return {}
  end
  
  if extentsLeft or extentsRight or extentsUp or extentsDown or not e._currentHashes then
    return self:getEntitiesAt(e.position.x - extentsLeft, e.position.y + extentsUp,
      extentsLeft + extentsRight, extentsUp + extentsDown)
  end
  
  self:updateEntityHashWhenNeeded(e)
  
  local result = e._currentHashes[1] and {unpack(e._currentHashes[1].data)} or {}
  
  for i = 2, #e._currentHashes do
    for j = 1, #e._currentHashes[i].data do
      if not _icontains(result, e._currentHashes[i].data[j]) then
        result[#result + 1] = e._currentHashes[i].data[j]
      end
    end
  end
  
  return result
end

function entitySystem:_conform(t)
  if not t._entitySystemConformed then
    t._layer = t._layer or 1
    t.isRemoved = true
    t.isAdded = false
    t.static = false
    t._currentHashes = nil
    if t.position == nil then
      t.position = {}
    end
    t.position.x = t.position.x or 0
    t.position.y = t.position.y or 0
    if t.canUpdate == nil then
      t.canUpdate = true
    end
    if t.canDraw == nil then
      t.canDraw = true
    end
    if t.invisibleToHash == nil then
      t.invisibleToHash = false
    end
    t.system = self
    t._entitySystemConformed = true
  end
  
  return t
end

entitySystem:init()

return entitySystem