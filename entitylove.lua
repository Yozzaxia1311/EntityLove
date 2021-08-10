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
local _sin = math.sin
local _cos = math.cos
local _atan2 = math.atan2
local _abs = math.abs
local _remove = table.remove

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
  return _dist2d(x1, y1, x2, y2) <= r1 + r2
end

local function _roundCircleOverlapsCircle(x1, y1, r1, x2, y2, r2)
  return _round(_dist2d(x1, y1, x2, y2)) <= r1 + r2
end

local function _pointOverlapsCircle(x1, y1, x2, y2, r2)
  return _dist2d(x1, y1, x2, y2) <= r2
end

local function _roundPointOverlapsCircle(x1, y1, x2, y2, r2)
  return _round(_dist2d(x1, y1, x2, y2)) <= r2
end

-- Circle overlaps rectangle function adapted from [YellowAfterLife](https://yal.cc/rectangle-circle-intersection-test/).
local function _circleOverlapsRect(x1, y1, r1, x2, y2, w2, h2)
  local dx = x1 - _max(x2, _min(x1, x2 + w2))
  local dy = y1 - _max(y2, _min(y1, y2 + h2))
  return (dx * dx + dy * dy) < (r1 * r1)
end

local function _roundCircleOverlapsRect(x1, y1, r1, x2, y2, w2, h2)
  local dx = x1 - _max(x2, _min(x1, x2 + w2))
  local dy = y1 - _max(y2, _min(y1, y2 + h2))
  return (dx * dx + dy * dy) < (r1 * r1)
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

local function _roundImageOverlapsCircle(x, y, data, x2, y2, r2)
  if _roundCircleOverlapsRect(x2, y2, r2, x, y, data:getWidth(), data:getHeight()) then
    local neww, newh = data:getWidth()-1, data:getHeight()-1
    
    for xi=_clamp(_floor(x2-x)-r2, 0, neww), _clamp(_ceil(x2-x)+r2, 0, neww) do
      for yi=_clamp(_floor(y2-y)-r2, 0, newh), _clamp(_ceil(y2-y)+r2, 0, newh) do
        local _, _, _, a = data:getPixel(xi, yi)
        if a > 0 and _roundCircleOverlapsRect(x2, y2, r2, x + xi, y + yi, 1, 1) then
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

local _entityRoundedCollision = {
    {
      function(e, other, x, y)
          return _rectOverlapsRect(e.position.x + (x or 0), e.position.y + (y or 0),
            _round(e.collisionShape.w), _round(e.collisionShape.h),
            _round(other.position.x), _round(other.position.y), _round(other.collisionShape.w), _round(other.collisionShape.h))
        end,
      function(e, other, x, y)
          return _imageOverlapsRect(_round(other.position.x), _round(other.position.y), other.collisionShape.data,
            e.position.x + (x or 0), e.position.y + (y or 0), _round(e.collisionShape.w), _round(e.collisionShape.h))
        end,
      function(e, other, x, y)
          return _roundCircleOverlapsRect(_round(other.position.x), _round(other.position.y), _round(other.collisionShape.r),
            e.position.x + (x or 0), e.position.y + (y or 0), _round(e.collisionShape.w), _round(e.collisionShape.h))
        end
    },
    {
      function(e, other, x, y)
          return _imageOverlapsRect(e.position.x + (x or 0), e.position.y + (y or 0), e.collisionShape.data,
            _round(other.position.x), _round(other.position.y), _round(other.collisionShape.w), _round(other.collisionShape.h))
        end,
      function(e, other, x, y)
          return _imageOverlapsImage(e.position.x + (x or 0), e.position.y + (y or 0), e.collisionShape.data,
            _round(other.position.x), _round(other.position.y), other.collisionShape.data)
        end,
      function(e, other, x, y)
          return _roundImageOverlapsCircle(e.position.x + (x or 0), e.position.y + (y or 0), e.collisionShape.data,
            _round(other.position.x), _round(other.position.y), _round(other.collisionShape.r))
        end
    },
    {
      function(e, other, x, y)
          return _roundCircleOverlapsRect(e.position.x + (x or 0), e.position.y + (y or 0), _round(e.collisionShape.r),
            _round(other.position.x), _round(other.position.y), _round(other.collisionShape.w), _round(other.collisionShape.h))
        end,
      function(e, other, x, y)
          return _roundImageOverlapsCircle(_round(other.position.x), _round(other.position.y), other.collisionShape.data,
            e.position.x + (x or 0), e.position.y + (y or 0), _round(e.collisionShape.r))
        end,
      function(e, other, x, y)
          return _roundCircleOverlapsCircle(e.position.x + (x or 0), e.position.y + (y or 0), _round(e.collisionShape.r),
            _round(other.position.x), _round(other.position.y), _round(other.collisionShape.r))
        end
    }
  }

-- Entity processing system.

function entitySystem:init()
  self.layers = {}
  self._updates = {}
  self.groups = {}
  self.static = {}
  self.all = {}
  self._readyQueue = {}
  self._hashes = {}
  self._HS =  {}
  self._doSort = false
  self.inLoop = false
  self.drawCollision = false
  self._imgCache = {}
  self._updateHoles = {}
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
    
    i = i + 1
  end
  
  i = 1
  while i <= #self._updates do
    local e = self._updates[i]
    
    if e ~= -1 then
      if e.update and e.canUpdate then
        e:update(dt)
      end
    end
    
    i = i + 1
  end
  
  i = 1
  while i <= #self._updates do
    local e = self._updates[i]
    
    if e ~= -1 then
      if e.afterUpdate and e.canUpdate then
        e:afterUpdate(dt)
      end
    end
    
    i = i + 1
  end
  
  if #self._updateHoles > 0 then
    self:_removeHoles(self._updates)
    self._updateHoles = {}
  end
  
  self.inLoop = false
end

function entitySystem:draw()
  local r, g, b, a = love.graphics.getColor()
  
  if self._doSort then
    self._doSort = false
    self:_sortLayers()
  end
  
  self.inLoop = true
  
  for _, layer in ipairs(self.layers) do
    local i = 1
    
    while i <= #layer.data do
      local e = layer.data[i]
      
      if e ~= -1 and e.draw and e.canDraw then
        love.graphics.setColor(1, 1, 1, 1)
        e:draw()
      end
      
      i = i + 1
    end
    
    if #layer.holes > 0 then
      self:_removeHoles(layer.data)
      layer.holes = {}
    end
  end
  
  if self.drawCollision then
    love.graphics.setColor(1, 1, 1, 1)
    for i = 1, #self.layers do
      for j = 1, self.layers[i].data do
        self:drawCollision(self.layers[i].data[j])
      end
    end
  end
  
  self.inLoop = false
  
  love.graphics.setColor(r, g, b, a)
end

function entitySystem:add(e)
  self:_conform(e)
  
  if not e.static then
    local done = false
    
    for i=1, #self.layers do
      local v = self.layers[i]
      
      if v.layer == e._layer then
        local nextHole = next(v.holes)
        if nextHole then
          v.data[nextHole] = e
          v.holes[nextHole] = nil
        else
          v.data[#v.data + 1] = e
        end
        done = true
        break
      end
    end
    
    if not done then
      self.layers[#self.layers + 1] = {layer = e._layer, data = {e}, holes = {}}
      self._doSort = true
    end
    
    local nextHole = next(self._updateHoles)
    if nextHole then
      self._updates[nextHole] = e
      self._updateHoles[nextHole] = nil
    else
      self._updates[#self._updates + 1] = e
    end
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

function entitySystem:_removeHoles(t)
  for i = 1, #t do
    if t[i] == -1 then
      _quickRemove(t, i)
    end
  end
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
    if al then
      local i = _findIndexArray(al.data, e)
      if i then
        al.data[i] = -1
        al.holes[i] = true
      end
    end
    
    local i = _findIndexArray(self._updates, e)
    if i then
      self._updates[i] = -1
      self._updateHoles[i] = true
    end
  end
  
  if not e.static and al and next(al.data) == nil then
    _removeValueArray(self.layers, al)
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
      local hs = entitySystem.HASH_SIZE
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
  self._updateHoles = {}
  
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
        local i = _findIndexArray(al.data, e)
        if i then
          al.data[i] = -1
          al.holes[i] = true
        end
        
        if #al.data == 0 then
          _removeValueArray(self.layers, al)
        end
      end
      
      e._layer = l
      
      local done = false
      
      for i=1, #self.layers do
        local v = self.layers[i]
        
        if v.layer == e._layer then
          local nextHole = next(v.holes)
          if nextHole then
            v.data[nextHole] = e
            v.holes[nextHole] = nil
          else
            v.data[#v.data + 1] = e
          end
          done = true
          break
        end
      end
      
      if not done then
        self.layers[#self.layers + 1] = {layer = e._layer, data = {e}, holes = {}}
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
    local i = _findIndexArray(self._updates, e)
    if i then
      self._updates[i] = -1
      self._updateHoles[i] = true
    end
    
    local al = self:_getLayerData(e._layer)
    
    if al then
      local i = _findIndexArray(al.data, e)
      if i then
        al.data[i] = -1
        al.holes[i] = true
      end
      
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
        local nextHole = next(v.holes)
        if nextHole then
          v.data[nextHole] = e
          v.holes[nextHole] = nil
        else
          v.data[#v.data + 1] = e
        end
        done = true
        break
      end
    end
    
    if not done then
      self.layers[#self.layers + 1] = {layer = e._layer, data = {e}, holes = {}}
      self._doSort = true
    end
    
    local nextHole = next(self._updateHoles)
    if nextHole then
      self._updates[nextHole] = e
      self._updateHoles[nextHole] = nil
    else
      self._updates[#self._updates + 1] = e
    end
    
    if e.collisionShape and e._staticX == e.position.x and e._staticY == e.position.y and
      e._staticW == e.collisionShape.w and e._staticH == e.collisionShape.h then
      local xx, yy, ww, hh = e.position.x, e.position.y, e.collisionShape.w, e.collisionShape.h
      local hs = entitySystem.HASH_SIZE
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
  
  if not self._imgCache[e.collisionShape.data] then
    self._imgCache[e.collisionShape.data] = love.graphics.newImage(e.collisionShape.data)
  end
  
  e.collisionShape.image = self._imgCache[e.collisionShape.data]
  
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

function entitySystem:collision(e, other, x, y)
  self:_conform(e)
  
  return other and other ~= e and e.collisionShape and other.collisionShape and
    _entityCollision[e.collisionShape.type][other.collisionShape.type](e, other, x, y)
end

function entitySystem:_rCollision(e, other, x, y)
  return other and other ~= e and e.collisionShape and other.collisionShape and
    _entityRoundedCollision[e.collisionShape.type][other.collisionShape.type](e, other, x, y)
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

function entitySystem:_rCollisionNumber(e, table, x, y)
  local result = 0
  
  for i = 1, #table do
    if type(table[i]) == "table" and self:_rCollision(e, table[i], x, y) then
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

function entitySystem:updateEntityHash(e, forceUpdate)
  self:_conform(e)
  
  if e.collisionShape and not e.invisibleToHash then
    if (forceUpdate or e.isAdded) then
      local xx, yy, ww, hh = e.position.x, e.position.y, e.collisionShape.w, e.collisionShape.h
      local hs = entitySystem.HASH_SIZE
      local cx, cy = _floor((xx - 2) / hs), _floor((yy - 2) / hs)
      local cx2, cy2 = _ceil((xx + ww + 2) / hs), _ceil((yy + hh + 2) / hs)
      
      if forceUpdate or e._lastHashX ~= cx or e._lastHashY ~= cy or e._lastHashX2 ~= cx2 or e._lastHashY2 ~= cy2 or not e._currentHashes then
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
  local hs = entitySystem.HASH_SIZE
  
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

function entitySystem:move(e, x, y, solids, resolverX, resolverY)
  self:_conform(e)
  
  local vx, vy = (x or 0), (y or 0)
  local colX, colY = false, false
  
  if vx ~= 0 or vy ~= 0 then
    if solids and e.collisionShape then
      local against = {unpack(solids)}
      
      for k, v in ipairs(against) do
        if v == e or not v.collisionShape then
          _quickRemove(against, k)
        end
      end
      
      if #against > 0 then
        if vx ~= 0 and vy ~= 0 then
          local vxSign, vySign = vx > 0 and 1 or -1, vy > 0 and 1 or -1
          local toX, toY = e.position.x + vx, e.position.y + vy
          local angle = _atan2(vy, vx)
          local dist = (e.collisionShape.w > e.collisionShape.h) and e.collisionShape.w or e.collisionShape.h
          local moveX, moveY = _abs(_sin(angle) * dist), _abs(_cos(angle) * dist)
          
          repeat
            if not colX then
              e.position.x = _approach(e.position.x, toX, moveX)
              
              if self:_rCollisionNumber(e, against) > 0 then
                e.position.x = _round(e.position.x + vxSign)
                
                if resolverX then
                  resolverX(against)
                else
                  while self:_rCollisionNumber(e, against) > 0 do
                    e.position.x = e.position.x - vxSign * 0.5
                  end
                end
                
                colX = true
              end
            end
            
            if not colY then
              e.position.y = _approach(e.position.y, toY, moveY)
              
              if self:_rCollisionNumber(e, against) > 0 then
                e.position.y = _round(e.position.y + vySign)
                
                if resolverY then
                  resolverY(against)
                else
                  while self:_rCollisionNumber(e, against) > 0 do
                    e.position.y = e.position.y - vySign * 0.5
                  end
                end
                
                colY = true
              end
            end
          until (colX and colY) or (colX and e.position.y == toY) or (colY and e.position.x == toX) or (e.position.x == toX and e.position.y == toY)
        elseif vx ~= 0 then
          local vxSign = vx > 0 and 1 or -1
          local toX = e.position.x + vx
          
          repeat
            e.position.x = _approach(e.position.x, toX, e.collisionShape.w)
            
            if self:_rCollisionNumber(e, against) > 0 then
              e.position.x = _round(e.position.x + vxSign)
              
              if resolverX then
                resolverX(against)
              else
                while self:_rCollisionNumber(e, against) > 0 do
                  e.position.x = e.position.x - vxSign * 0.5
                end
              end
              
              colX = true
            end
          until colX or e.position.x == toX
        else
          local vySign = vy > 0 and 1 or -1
          local toY = e.position.y + vy
          
          repeat
            e.position.y = _approach(e.position.y, toY, e.collisionShape.h)
            
            if self:_rCollisionNumber(e, against) > 0 then
              e.position.y = _round(e.position.y + vySign)
              
              if resolverY then
                resolverY(against)
              else
                while self:_rCollisionNumber(e, against) > 0 do
                  e.position.y = e.position.y - vySign * 0.5
                end
              end
              
              colY = true
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
  
  return colX, colY
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