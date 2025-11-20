-- Constants.

local entitySystem = {}

entitySystem.COL_RECT = 1
entitySystem.COL_IMAGE = 2
entitySystem.COL_CIRCLE = 3

entitySystem.SOLID_TYPE_NONE = 1
entitySystem.SOLID_TYPE_SOLID = 2
entitySystem.SOLID_TYPE_ONEWAY = 3

entitySystem.SLOPE_MODE_PLATFORMER = 1
entitySystem.SLOPE_MODE_TOPDOWN = 2

-- Important util functions.

local _remove = table.remove

local _floor = math.floor
local _ceil = math.ceil
local _sqrt = math.sqrt
local _min = math.min
local _max = math.max
local _sin = math.sin
local _cos = math.cos
local _atan2 = math.atan2
local _abs = math.abs

local function _sign(x)
  return x > 0 and 1 or (x < 0 and -1 or 0)
end

local function _round(v)
  return _floor(0.5 + v)
end

local function _approach(v, to, am)
  if v < to then 
    return _min(v + am, to)
  elseif v > to then
    return _max(v - am, to)
  end
  
  return v
end

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

local function _removeValueArray(t, va)
  if t[#t] == va then t[#t] = nil return end
  
  for i=1, #t do
    if t[i] == va then
      _remove(t, i)
      break
    end
  end
end

local function _quickRemove(t, i)
  t[i] = t[#t]
  t[#t] = nil
end

local function _findIndexArray(t, va)
  for i=1, #t do
    if t[i] == va then
      return i
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
  return _round(_dist2d(x1, y1, x2, y2)) <= r1 + r2
end

local function _pointOverlapsCircle(x1, y1, x2, y2, r2)
  return _round(_dist2d(x1, y1, x2, y2)) <= r2
end

-- Circle overlaps rectangle function adapted from [YellowAfterLife](https://yal.cc/rectangle-circle-intersection-test/).
local function _circleOverlapsRect(x1, y1, r1, x2, y2, w2, h2)
  return ((x1 - _max(x2, _min(x1, x2 + w2))) ^ 2) + ((y1 - _max(y2, _min(y1, y2 + h2))) ^ 2) < r1 ^ 2
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
  if _rectOverlapsRect(x, y, data:getWidth(), data:getHeight(), x2, y2,
    data2:getWidth(), data2:getHeight()) then
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
          return _imageOverlapsCircle(e.position.x + (x or 0), e.position.y + (y or 0),
            e.collisionShape.data,
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

function entitySystem_new(self, hs, defaultSlopeMode)
  local new = {}
  
  new.layers = {}
  new._updates = {}
  new.groups = {}
  new.static = {}
  new.all = {}
  new._readyQueue = {}
  new._hashes = {}
  new._HS = {}
  new._doSort = false
  new.inLoop = false
  new.inDrawLoop = false
  new.debugDrawCollision = false
  new.hashSize = hs or 96
  new._entityRemovedInLoop = false
  new._tempEnt = {invisibleToHash = true}
  new._defaultSlopeMode = defaultSlopeMode or entitySystem.SLOPE_MODE_TOPDOWN
  
  return setmetatable(new, {__index = entitySystem})
end

function entitySystem:update(dt)
  while self._readyQueue[1] do
    if self._readyQueue[1].ready and not self._readyQueue[1].isRemoved then
      self._readyQueue[1]:ready()
    end
    _remove(self._readyQueue, 1)
  end
  
  self.inLoop = true
  
  local i = 1
  while i <= #self._updates do
    local e = self._updates[i]
    
    if e ~= -1 then
      e.previousX = e.position.x
      e.previousY = e.position.y
      
      if e.beforeUpdate and e.canUpdate then
        e:beforeUpdate(dt)
      end
    end
    
    if not e.isRemoved then
      i = i + 1
    end
  end
  
  i = 1
  while i <= #self._updates do
    local e = self._updates[i]
    
    if e ~= -1 then
      if e.update and e.canUpdate then
        e:update(dt)
      end
    end
    
    if not e.isRemoved then
      i = i + 1
    end
  end
  
  i = 1
  while i <= #self._updates do
    local e = self._updates[i]
    
    if e ~= -1 then
      if e.afterUpdate and e.canUpdate then
        e:afterUpdate(dt)
      end
    end
    
    if not e.isRemoved then
      i = i + 1
    end
  end
  
  self.inLoop = false
end

function entitySystem:draw()
  local r, g, b, a = love.graphics.getColor()
  
  if self._doSort then
    self._doSort = false
    self:_sortLayers()
  end
  
  self.inDrawLoop = true
  
  for _, layer in ipairs(self.layers) do
    local i = 1
    
    while i <= #layer.data do
      local e = layer.data[i]
      
      if e.draw and e.canDraw then
        love.graphics.setColor(1, 1, 1, 1)
        e:draw()
      end
      
      if not e.isRemoved then
        i = i + 1
      end
    end
  end
  
  if self.debugDrawCollision then
    love.graphics.setColor(1, 1, 1, 1)
    for i = 1, #self.layers do
      for j = 1, self.layers[i].data do
        self:drawCollision(self.layers[i].data[j])
      end
    end
  end
  
  self.inDrawLoop = false
  
  love.graphics.setColor(r, g, b, a)
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
    
    self._updates[#self._updates + 1] = e
  else
    self.static[#self.static + 1] = e
  end
  
  self.all[#self.all+1] = e
  
  e.isRemoved = false
  e.isAdded = true
  e._lastHashX = nil
  e._lastHashY = nil
  e._lastHashX2 = nil
  e._lastHashY2 = nil
  e.system = self
  e._currentHashes = nil
  if not e.invisibleToHash then self:updateEntityHash(e, true) end
  if e.added then e:added() end
  
  if self.inLoop then
    if e.ready then e:ready() end
  else
    self._readyQueue[#self._readyQueue + 1] = e
  end
  
  e.previousX = e.position.x
  e.previousY = e.position.y
  
  return e
end

function entitySystem:remove(e)
  self:_conform(e)
  
  e.isRemoved = true
  if e.removed then e:removed() end
  
  self:removeFromAllGroups(e)
  
  if e.static then
    _quickRemoveValueArray(self.static, e)
  else
    local ld = self:_getLayerData(e._layer)
    
    if ld then
      _removeValueArray(ld.data, e)
      
      if #ld.data == 0 then
        _removeValueArray(self.layers, ld)
      end
    end
    
    _removeValueArray(self._updates, e)
  end
  
  _quickRemoveValueArray(self.all, e)
  _quickRemoveValueArray(self._readyQueue, e)
  
  if e._currentHashes then
    for _, v in ipairs(e._currentHashes) do
      if not v.isRemoved then
        _quickRemoveValueArray(v.data, e)
        
        if #v.data == 0 then
          v.isRemoved = true
          self._hashes[v.x][v.y] = nil
          self._HS[v.x] = self._HS[v.x] - 1
          
          if self._HS[v.x] == 0 then
            self._hashes[v.x] = nil
            self._HS[v.x] = nil
          end
        end
      end
    end
  elseif e.static then
    if e.collisionShape and e._staticX == e.position.x and e._staticY == e.position.y and
      e._staticW == e.collisionShape.w and e._staticH == e.collisionShape.h then
      local xx, yy, ww, hh = e.position.x, e.position.y, e.collisionShape.w, e.collisionShape.h
      local hs = self.hashSize
      local cx, cy = _floor((xx - 2) / hs), _floor((yy - 2) / hs)
      local cx2, cy2 = _ceil((xx + ww + 2) / hs), _ceil((yy + hh + 2) / hs)
      
      for x = cx, cx2 do
        for y = cy, cy2 do
          if self._hashes[x] and self._hashes[x][y] and not self._hashes[x][y].isRemoved then
            _quickRemoveValueArray(self._hashes[x][y].data, e)
            
            if #self._hashes[x][y].data == 0 then
              self._hashes[x][y].isRemoved = true
              self._hashes[x][y] = nil
              self._HS[x] = self._HS[x] - 1
              
              if self._HS[x] == 0 then
                self._hashes[x] = nil
                self._HS[x] = nil
              end
            end
          end
        end
      end
    else
      for x, xt in pairs(self._hashes) do
        for y, yt in pairs(xt) do
          _quickRemoveValueArray(yt.data, e)
          
          if #yt.data == 0 and not yt.isRemoved then
            yt.isRemoved = true
            self._hashes[x][y] = nil
            self._HS[x] = self._HS[x] - 1
            
            if self._HS[x] == 0 then
              self._hashes[x] = nil
              self._HS[x] = nil
            end
          end
        end
      end
    end
    
    e._staticX = nil
    e._staticY = nil
    e._staticW = nil
    e._staticH = nil
  end
  
  e._lastHashX = nil
  e._lastHashY = nil
  e._lastHashX2 = nil
  e._lastHashY2 = nil
  e._currentHashes = nil
  e.system = nil
  
  e.isAdded = false
end

function entitySystem:clear()
  for _, e in ipairs(self.all) do
    self:remove(e)
  end
  
  self.all = {}
  self.layers = {}
  self._updates = {}
  self.groups = {}
  self.static = {}
  self._hashes = {}
  self._HS = {}
  self._doSort = false
  self._readyQueue = {}
  self._removeQueue = {}
  
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
      
      if al then
        _removeValueArray(al.data, e)
        
        if #al.data == 0 then
          _removeValueArray(self.layers, al)
        end
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
    
    if v.layer == l then
      return v
    end
  end
end

function entitySystem:makeStatic(e)
  self:_conform(e)
  
  if not e.static and not e.isRemoved then
    _removeValueArray(self._updates, e)
    
    local al = self:_getLayerData(e._layer)
    
    if al then
      _removeValueArray(al.data, e)
      
      if #al.data == 0 then
        _removeValueArray(self.layers, al)
      end
    end
    
    if not _icontains(self.static, e) then
      self.static[#self.static + 1] = e
    end
    
    e.static = true
    e._staticX = e.position.x
    e._staticY = e.position.y
    if e.collisionShape then
      e._staticW = e.collisionShape.w
      e._staticH = e.collisionShape.h
    end
    
    e._lastHashX = nil
    e._lastHashY = nil
    e._lastHashX2 = nil
    e._lastHashY2 = nil
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
    
    self._updates[#self._updates + 1] = e
    
    if e.collisionShape and e._staticX == e.position.x and e._staticY == e.position.y and
      e._staticW == e.collisionShape.w and e._staticH == e.collisionShape.h then
      local xx, yy, ww, hh = e.position.x, e.position.y, e.collisionShape.w, e.collisionShape.h
      local hs = self.hashSize
      local cx, cy = _floor((xx - 2) / hs), _floor((yy - 2) / hs)
      local cx2, cy2 = _ceil((xx + ww + 2) / hs), _ceil((yy + hh + 2) / hs)
      
      for x = cx, cx2 do
        for y = cy, cy2 do
          if self._hashes[x] and self._hashes[x][y] and not self._hashes[x][y].isRemoved then
            _quickRemoveValueArray(self._hashes[x][y].data, e)
            
            if #self._hashes[x][y].data == 0 then
              self._hashes[x][y].isRemoved = true
              self._hashes[x][y] = nil
              self._HS[x] = self._HS[x] - 1
              
              if self._HS[x] == 0 then
                self._hashes[x] = nil
                self._HS[x] = nil
              end
            end
          end
        end
      end
    else
      for x, xt in pairs(self._hashes) do
        for y, yt in pairs(xt) do
          if _icontains(yt.data, e) then
            _quickRemoveValueArray(yt.data, e)
          end
          
          if #yt.data == 0 and not yt.isRemoved then
            yt.isRemoved = true
            self._hashes[x][y] = nil
            self._HS[x] = self._HS[x] - 1
            
            if self._HS[x] == 0 then
              self._hashes[x] = nil
              self._HS[x] = nil
            end
          end
        end
      end
    end
    
    e.static = false
    e._staticX = nil
    e._staticY = nil
    e._staticW = nil
    e._staticH = nil
    e._lastHashX = nil
    e._lastHashY = nil
    e._lastHashX2 = nil
    e._lastHashY2 = nil
    e._currentHashes = nil
    e.system = self
    
    if not e.invisibleToHash then self:updateEntityHash(e) end
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
  
  if not e.invisibleToHash then self:updateEntityHash(e) end
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
  
  e.collisionShape.r = nil
  
  if not e.invisibleToHash then self:updateEntityHash(e) end
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
  
  if not e.invisibleToHash then self:updateEntityHash(e) end
end

function entitySystem:pointInEntity(e, x, y)
  self:_conform(e)
  
  self:setRectangleCollision(self._tempEnt, 1, 1)
  
  return e.collisionShape and self:collision(self._tempEnt, e, x, y)
end

function entitySystem:rectangleInEntity(e, x, y, w, h)
  self:_conform(e)
  
  self:setRectangleCollision(self._tempEnt, w, h)
  
  return e.collisionShape and self:collision(self._tempEnt, e, x, y)
end

function entitySystem:imageInEntity(e, x, y, data)
  self:_conform(e)
  
  self:setImageCollision(self._tempEnt, data)
  
  return e.collisionShape and self:collision(self._tempEnt, e, x, y)
end

function entitySystem:circleInEntity(e, x, y, r)
  self:_conform(e)
  
  self:setCircleCollision(self._tempEnt, r)
  
  return e.collisionShape and self:collision(self._tempEnt, e, x, y)
end

function entitySystem:collision(e, other, x, y)
  self:_conform(e)
  
  return other and other ~= e and e.collisionShape and other.collisionShape and
    _entityCollision[e.collisionShape.type][other.collisionShape.type](e, other, x, y)
end

function entitySystem:collisionTable(e, table, x, y)
  self:_conform(e)
  
  local result = {}
  
  for i = 1, #table do
    if type(table[i]) == "table" and self:collision(e, table[i], x, y) then
      result[#result+1] = table[i]
    end
  end
  
  return result
end

function entitySystem:collisionNumber(e, table, x, y)
  self:_conform(e)
  
  local result = 0
  
  for i = 1, #table do
    if type(table[i]) == "table" and self:collision(e, table[i], x, y) then
      result = result + 1
    end
  end
  
  return result
end

function entitySystem:drawCollision(e)
  self:_conform(e)
  
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(1, 1, 1, 1)
  
  if e.collisionShape.type == entitySystem.COL_RECT then
    love.graphics.rectangle("line", _floor(e.position.x), _floor(e.position.y),
      e.collisionShape.w, e.collisionShape.h)
  elseif e.collisionShape.type == entitySystem.COL_IMAGE then
    -- No drawing support
  elseif e.collisionShape.type == entitySystem.COL_CIRCLE then
    love.graphics.circle("line", _floor(e.position.x), _floor(e.position.y), e.collisionShape.r)
  end
  
  love.graphics.setColor(r, g, b, a)
end

function entitySystem:updateEntityHash(e, forceUpdate)
  self:_conform(e)
  
  if e.collisionShape and not e.invisibleToHash then
    if (forceUpdate or e.isAdded) then
      local xx, yy, ww, hh = e.position.x, e.position.y, e.collisionShape.w, e.collisionShape.h
      local hs = self.hashSize
      local cx, cy = _floor((xx - 2) / hs), _floor((yy - 2) / hs)
      local cx2, cy2 = _ceil((xx + ww + 2) / hs), _ceil((yy + hh + 2) / hs)
      
      if forceUpdate or e._lastHashX ~= cx or e._lastHashY ~= cy or
        e._lastHashX2 ~= cx2 or e._lastHashY2 ~= cy2 or not e._currentHashes then
        if not e._currentHashes then
          e._currentHashes = {}
        end
        
        e._lastHashX = cx
        e._lastHashY = cy
        e._lastHashX2 = cx2
        e._lastHashY2 = cy2
        
        local emptyBefore = #e._currentHashes == 0
        local check = {}
        
        for x = cx, cx2 do
          for y = cy, cy2 do
            if not self._hashes[x] then
              self._hashes[x] = {[y] = {x = x, y = y, data = {e}, isRemoved = false}}
              self._HS[x] = 1
            elseif not self._hashes[x][y] then
              self._hashes[x][y] = {x = x, y = y, data = {e}, isRemoved = false}
              self._HS[x] = self._HS[x] + 1
            elseif not _icontains(self._hashes[x][y].data, e) then
              self._hashes[x][y].data[#self._hashes[x][y].data+1] = e
              self._hashes[x][y].data[#self._hashes[x][y].data].isRemoved = false
            end
            
            if not _icontains(e._currentHashes, self._hashes[x][y]) then
              e._currentHashes[#e._currentHashes+1] = self._hashes[x][y]
            end
            
            if self._hashes[x] and self._hashes[x][y] then
              check[#check + 1] = self._hashes[x][y]
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
                  self._hashes[v.x][v.y] = nil
                  self._HS[v.x] = self._HS[v.x] - 1
                  
                  if self._HS[v.x] == 0 then
                    self._hashes[v.x] = nil
                    self._HS[v.x] = nil
                  end
                end
              end
              
              _quickRemoveValueArray(e._currentHashes, v)
            end
          end
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
          self._hashes[v.x][v.y] = nil
          self._HS[v.x] = self._HS[v.x] - 1
          
          if self._HS[v.x] == 0 then
            self._hashes[v.x] = nil
            self._HS[v.x] = nil
          end
        end
      end
    end
    
    e._currentHashes = nil
  end
end

function entitySystem:getEntitiesAt(xx, yy, ww, hh)
  local result
  local hs = self.hashSize
  
  for x = _floor((xx - 2) / hs), _ceil((xx + ww + 2) / hs) do
    for y = _floor((yy - 2) / hs), _ceil((yy + hh + 2) / hs) do
      if self._hashes[x] and self._hashes[x][y] then
        local hash = self._hashes[x][y]
        
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
  
  if e.invisibleToHash or e.isRemoved then
    return {}
  end
  
  self:updateEntityHash(e)
  
  if extentsLeft or extentsRight or extentsUp or extentsDown or not e._currentHashes then
    return self:getEntitiesAt(e.position.x - (extentsLeft or 0), e.position.y - (extentsUp or 0),
      (extentsLeft or 0) + (extentsRight or 0), (extentsUp or 0) + (extentsDown or 0))
  end
  
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

function entitySystem:pos(e, x, y)
  self:_conform(e)
  
  if (x or y) and (e.position.x ~= x or e.position.y ~= y) then
    e.position.x = x or e.position.x
    e.position.y = y or e.position.y
    if not e.invisibleToHash then self:updateEntityHash(e) end
  end
end

function entitySystem:move(e)
  self:_conform(e)
  
  local vx, vy = e.velocity.x, e.velocity.y
  local colX, colY = false, false
  local prioritizeY = (e.slopeMode == self.SLOPE_MODE_TOPDOWN) and (_abs(e.velocity.y) > _abs(e.velocity.x))
  
  if vx ~= 0 or vy ~= 0 then
    if e.collisionShape then
      local all = self:getSurroundingEntities(e, _abs(_min(e.velocity.x, 0)),
        _max(e.velocity.x, 0),
      _abs(_min(e.velocity.y, 0)), _max(e.velocity.y, 0))
      local against = {}
      
      for i=1, #all do
        local v = all[i]
        if v ~= e and v.collisionShape and
          (not v.exclusivelySolidFor or _icontains(v.exclusivelySolidFor, e)) and
          (not v.excludeSolidFor or not _icontains(v.excludeSolidFor, e)) then
          if v.solidType == self.SOLID_TYPE_SOLID then
            if not self:collision(v, e) and not _icontains(against, v) then
              against[#against+1] = v
            end
          end
        end
      end
      
      if #against > 0 then
        if vx ~= 0 then
          local vxSign = vx > 0 and 1 or -1
          local toX = e.position.x + vx
          local prevX = e.position.x
          
          repeat
            e.position.x = _approach(e.position.x, toX, e.collisionShape.w)
            
            if self:collisionNumber(e, against) > 0 then
              e.position.x = _round(e.position.x + vxSign)
              
              while self:collisionNumber(e, against) > 0 do
                e.position.x = e.position.x - vxSign * 0.5
              end
              
              colX = true
              e.collisionShock.x = e.position.x - prevX
              e.prevVel.x = e.velocity.x
              e.velocity.x = 0
              
              if not prioritizeY and e.prevVel.x ~= 0 and e.maxSlope > 0 then
                local xsl = e.prevVel.x - e.collisionShock.x
                local yStep = 1
                local xStep = 0
                local dst = _abs(xsl)
                local yTolerance = _ceil(dst) * e.maxSlope
                
                while xStep ~= dst do
                  if self:collisionNumber(e, against, xsl - xStep, -yStep) == 0 then
                    e.position.x = e.position.x + xsl - xStep
                    e.position.y = e.position.y - yStep
                    if xStep == 0 then
                      e.velocity.x = e.prevVel.x
                      e.prevVel.x = 0
                    end
                    break
                  elseif self:collisionNumber(e, against, xsl - xStep, yStep) == 0 then
                    e.position.x = e.position.x + xsl - xStep
                    e.position.y = e.position.y + yStep
                    if xStep == 0 then
                      e.velocity.x = e.prevVel.x
                      e.prevVel.x = 0
                    end
                    break
                  end
                  if yStep > yTolerance then
                    yStep = 1
                    xStep = _min(xStep + 1, dst)
                    yTolerance = _ceil(dst - xStep) * e.maxSlope
                  else
                    yStep = yStep + 1
                  end
                end
              end
            end
          until colX or e.position.x == toX
        end
        
        if vy ~= 0 then
          local vySign = vy > 0 and 1 or -1
          local toY = e.position.y + vy
          local prevY = e.position.y
          
          repeat
            e.position.y = _approach(e.position.y, toY, e.collisionShape.h)
            
            if self:collisionNumber(e, against) > 0 then
              e.position.y = _round(e.position.y + vySign)
              
              while self:collisionNumber(e, against) > 0 do
                e.position.y = e.position.y - vySign * 0.5
              end
              
              colY = true
              e.collisionShock.y = e.position.y - prevY
              e.prevVel.y = e.velocity.y
              e.velocity.y = 0
              
              if prioritizeY and e.prevVel.y ~= 0 and e.maxSlope > 0 then
                local ysl = e.prevVel.y - e.collisionShock.y
                local xStep = 1
                local yStep = 0
                local dst = _abs(ysl)
                local xTolerance = _ceil(dst) * e.maxSlope
                
                while yStep ~= dst do
                  if self:collisionNumber(e, against, -xStep, ysl - yStep) == 0 then
                    e.position.y = e.position.y + ysl - yStep
                    e.position.x = e.position.x - xStep
                    if yStep == 0 then
                      e.velocity.y = e.prevVel.y
                      e.prevVel.y = 0
                    end
                    break
                  elseif self:collisionNumber(e, against, xStep, ysl - yStep) == 0 then
                    e.position.y = e.position.y + ysl - yStep
                    e.position.x = e.position.x + xStep
                    if yStep == 0 then
                      e.velocity.y = e.prevVel.y
                      e.prevVel.y = 0
                    end
                    break
                  end
                  if xStep > xTolerance then
                    xStep = 1
                    yStep = _min(yStep + 1, dst)
                    xTolerance = _ceil(dst - yStep) * e.maxSlope
                  else
                    xStep = xStep + 1
                  end
                end
              end
            end
          until colY or e.position.y == toY
        end
      else
        e.position.x, e.position.y = e.position.x + vx, e.position.y + vy
      end
    else
      e.position.x, e.position.y = e.position.x + vx, e.position.y + vy
    end
    
    self:updateEntityHash(e)
  end
end

function entitySystem:_conform(t)
  assert(type(t) == "table", "Value given is not a table!")
  
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
    if t.velocity == nil then
      t.velocity = {}
    end
    t.velocity.x = t.velocity.x or 0
    t.velocity.y = t.velocity.y or 0
    if t.collisionShock == nil then
      t.collisionShock = {}
    end
    t.collisionShock.x = t.collisionShock.x or 0
    t.collisionShock.y = t.collisionShock.y or 0
    if t.prevVel == nil then
      t.prevVel = {}
    end
    t.prevVel.x = t.prevVel.x or 0
    t.prevVel.y = t.prevVel.y or 0
    t.maxSlope = 3
    t.slopeMode = self._defaultSlopeMode
    t.blockCollision = true
    t.solidType = self.SOLID_TYPE_NONE
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

return setmetatable(entitySystem, {__call = entitySystem_new})