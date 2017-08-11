local dt = 0.01

darker = {
  ["0"] = "8",
  ["1"] = "8",
  ["2"] = "a",
  ["3"] = "9",
  ["4"] = "1",
  ["5"] = "d",
  ["6"] = "2",
  ["7"] = "f",
  ["8"] = "7",
  ["9"] = "b",
  ["a"] = "7",
  ["b"] = "f",
  ["c"] = "7",
  ["d"] = "7",
  ["e"] = "7",
  ["f"] = "f",
}

breakstages = {
  ".", ",", "·", ":", ";", "i", "|", "I", "ß", "#", "@"
}

function get_instance_of(thing, vars)
  local tempthing = {}
  for k, v in pairs(thing) do
    tempthing[k] = v
  end
  if vars then
    for k, v in pairs(vars) do
      tempthing[k] = v
    end
  end
  return tempthing
end

function distance(x1, y1, x2, y2)
  return math.sqrt((x1-x2)^2+(y1-y2)^2)
end

new = {
  texture = function(texture_table, anchorX, anchorY, noshader)
    return {
      texture_table=texture_table,
      anchorX = anchorX or 0,
      anchorY = anchorY or 0,
      noshader=noshader,
      draw = function(self, txtrx, txtry)
        for y, texturestring in pairs(self.texture_table) do
          for x, txtr in pairs(texturestring) do if txtr then
            local char = txtr[1]
            local charCol = txtr[2]
            local backCol = txtr[3]
            local drawX = txtrx+x+self.anchorX-1
            local drawY = txtry+y+self.anchorY-1
            if not self.noshader then
              local nearest_light = world.lights.sun
              local light_distance = distance(nearest_light.x, nearest_light.y, drawX, drawY)

              for _, light in pairs(world.lights) do
                if distance(light.x, light.y, drawX, drawY) < light_distance then nearest_light = light end
              end

              if light_distance < nearest_light.power/12 then charCol = nearest_light.color
              elseif light_distance < nearest_light.power/2 then
              elseif light_distance < nearest_light.power/3 then backCol = darker[backCol]
              elseif light_distance < nearest_light.power/2 then backCol = darker[backCol] charCol = darker[charCol] char = "\127"
              elseif light_distance < nearest_light.power/1 then if char == " " then char = "\127" end backCol = darker[backCol] backCol = darker[backCol] charCol = darker[charCol] charCol = darker[charCol]
              else backCol = darker[darker[darker[backCol]]] charCol = darker[darker[charCol]] if char == " " then char = "\127" end
              end
            end
            term.setCursorPos(drawX, drawY)
            term.blit(char, charCol, backCol)
            end
          end
        end
      end
    }
  end,
  block = function(texture, name, hardness, glowing_strenght, solid, afterblock)
    return {
      texture=texture,
      name=name,
      hardness=hardness,
      breakstage=0,
      glowing_strenght=glowing_strenght,
      solid=solid,
      afterblock=afterblock,
      draw = function(self, x, y)
        local old_texture = self.texture.texture_table[1][1][1]
        if self.breakstage>0 then
          if breakstages[self.breakstage] then
            self.texture.texture_table[1][1][1] = breakstages[self.breakstage]
          else
            self.texture.texture_table[1][1][1] = breakstages[#breakstages]
          end
        end
        self.texture:draw(x, y)
        self.texture.texture_table[1][1][1] = old_texture
      end
    }
  end,
  light = function(x, y, power, color)
    return {
      x=x, y=y,
      power=power,
      color=color
    }
  end,
  blockgen = function(size, blocks, onblocks, count, custom_update)
    return {
      size=size,
      blocks=blocks,
      count=count,
      onblocks=onblocks,
      custom_update=custom_update,
      generate = function(self, orbx, orby, biome)
        if world.blocks[orby] and world.blocks[orby][orbx] then
          local rightblock = false
          for _, blockname in pairs(self.onblocks) do
            if biome[blockname] and world.blocks[orby][orbx].name == biome[blockname].name then rightblock = true end
            if world.blocks[orby][orbx].name == blockname then rightblock = true end
            if rightblock then break end
          end
          if rightblock then
            for blocky, yrow in pairs(world.blocks) do
              for blockx, block in pairs(yrow) do
                if distance(orbx, orby, blockx, blocky) <= self.size then
                  local block = self.blocks[math.random(#self.blocks)]
                  if biome[block] then
                    block = get_instance_of(biome[block])
                  else
                    block = get_instance_of(references.blocks[block])
                  end
                  world.blocks[blocky][blockx] = block
                end
              end
            end
            if self.custom_update then self.custom_update(orbx, orby, biome) end
            return true
          else
            return false
          end
        else
          return true
        end
      end
    }
  end,
  entity = function(x, y, texture, gravity, name, is_name_shown, custom_update, gravity, glowing_strenght)
    return {
      gravity=gravity,
      glowing_strenght=glowing_strenght,
      x=x, y=y,
      texture=texture,
      gravity=gravity,
      name=name,
      jumppower=0,
      is_name_shown=is_name_shown,
      custom_update=custom_update,
      is_right_solid = function(self)
        local solid = false
        for y = self.y-self.texture.anchorY-2, self.y-self.texture.anchorY do
          if world.blocks[y][self.x+1].solid then
            solid = true
          end
        end
        return solid
      end,
      is_left_solid = function(self)
        local solid = false
        for y = self.y-self.texture.anchorY-2, self.y-self.texture.anchorY do
          if world.blocks[y][self.x-1].solid then
            solid = true
          end
        end
        return solid
      end,
      is_top_solid = function(self)
        return false
      end,
      stands_on_solid = function(self)
        return world.blocks[self.y+2][self.x].solid
      end,
      update = function(self)
        if self.jumppower ~= 0 then
          self.y = self.y - 1
          self.jumppower = self.jumppower-1
        elseif not self:stands_on_solid() then
          self.y = self.y + 1
        end
        if self.custom_update then self:custom_update(event, var1, var2, var3) end
      end,
      draw = function(self)
        self.texture:draw(self.x, self.y, 10, 10)
        if self.is_name_shown then
          term.setCursorPos(self.x-math.ceil(#self.name/2)+1, self.y-2)
          term.setTextColor(colors.white)
          term.setBackgroundColor(colors.lightGray)
          term.write(self.name)
        end
      end
    }
  end,
  item = function(texture, name, use_function, glowing_strenght, toolpower)
    return {
      texture = texture,
      toolpower=toolpower or 0,
      name = name,
      use_function = use_function,
      glowing_strenght = glowing_strenght,
      draw = function(self, x, y)
        self.texture:draw(x, y)
      end
    }
  end,
  slot = function(x, y, col, backcol, shortcut, itemtypes)
    return {
      x=x, y=y,
      col=col,
      backcol=backcol,
      shortcut=shortcut,
      itemtypes=itemtypes,
      draw = function(self)
        term.setCursorPos(self.x+1, self.y)
        term.blit("__", self.backcol..self.backcol, self.col..self.col)
        term.setCursorPos(self.x, self.y+1)
        term.blit("|\0\0|", self.backcol..self.backcol..self.backcol..self.backcol, self.col..self.col..self.col..self.col)
        term.setCursorPos(self.x, self.y+2)
        term.blit("|\0\0|", self.backcol..self.backcol..self.backcol..self.backcol, self.col..self.col..self.col..self.col)
        term.setCursorPos(self.x+1, self.y+3)
        term.blit("\175\175", self.backcol..self.backcol, self.col..self.col)
        if self.shortcut then
          term.setCursorPos(self.x+3, self.y+3)
          term.blit(self.shortcut, "e", self.col)
        end
        if self.item then
          self.item.texture:draw(self.x, self.y)
        end
      end,
      update = function(self, event, var1, var2, var3)
        if event == "mouse_click" and var2>=self.x+1 and var3>=self.y+1 then
          if var2<=self.x+2 and var3<=self.y+2 then
            if var1 == 1 then
              if dragitem~=nil and self.item==nil then self.item = dragitem dragitem = nil
              else dragitem = self.item self.item = nil
              end
            end
          end
        end
      end
    }
  end
}

references = {
  blocks = {
    air = new.block(
      new.texture(
        {
          {
            {" ", "3", "3"}
          }
        }
      ),
      "air",
      false,
      2,
      false,
      "air"
    ),
    log = new.block(
      new.texture(
        {
          {
            {"b", "7", "c"}
          }
        }
      ),
      "log",
      5,
      0,
      false,
      "air"
    ),
    planks = new.block(
      new.texture(
        {
          {
            {"_", "7", "c"}
          }
        }
      ),
      "planks",
      6,
      0,
      true,
      "air"
    ),
    dirt = new.block(
      new.texture(
        {
          {
            {" ", "7", "c"}
          }
        }
      ),
      "dirt",
      5,
      0,
      true,
      "air"
    ),
    grass = new.block(
      new.texture(
        {
          {
            {"M", "5", "d"}
          }
        }
      ),
      "grass",
      1,
      0,
      true,
      "dirt"
    ),
    stone = new.block(
      new.texture(
        {
          {
            {" ", "f", "7"}
          }
        }
      ),
      "stone",
      10,
      0,
      true,
      "stonewall"
    ),
    stonewall = new.block(
      new.texture(
        {
          {
            {"´", "7", "8"}
          }
        }
      ),
      "stonewall",
      100,
      0,
      false,
      "air"
    ),
    plant = new.block(
      new.texture(
        {
          {
            {"p", "d", "3"}
          }
        }
      ),
      "plant",
      2,
      0,
      false,
      "air"
    ),
    leaves = new.block(
      new.texture(
        {
          {
            {"w", "5", "d"}
          }
        }
      ),
      "leaves",
      2,
      0,
      false,
      "air"
    ),
    icedirt = new.block(
      new.texture(
        {
          {
            {"\127", "0", "3"}
          }
        }
      ),
      "icedirt",
      7,
      0,
      true,
      "air"
    ),
    icegrass = new.block(
      new.texture(
        {
          {
            {" ", "3", "0"}
          }
        }
      ),
      "icegrass",
      3,
      0,
      true,
      "icedirt"
    ),
    icestone = new.block(
      new.texture(
        {
          {
            {"\127", "9", "3"}
          }
        }
      ),
      "ice",
      6,
      0,
      true,
      "icewall"
    ),
    icestonewall = new.block(
      new.texture(
        {
          {
            {"\127", "3", "0"}
          }
        }
      ),
      "icewall",
      10,
      0,
      false,
      "air"
    ),
    iceplant = new.block(
      new.texture(
        {
          {
            {"\165", "b", "3"}
          }
        }
      ),
      "iceflower",
      3,
      0,
      false,
      "air"
    ),
    iceleaves = new.block(
      new.texture(
        {
          {
            {"w", "3", "0"}
          }
        }
      ),
      "leaves",
      2,
      0,
      false,
      "air"
    ),
  },
  entitys = {
    player = new.entity(
      1, 1,
      new.texture(
        {
          {nil, {"\2", "4", "6"}, nil},
          {{"\138", "d", "5"}, {"H", "5", "d"}, {"\133", "d", "5"}},
          {nil, {"M", "9", "b"}, nil}
        },
        -1,
        -1
      ),
      1,
      "player01",
      true,
      function(self, event, var1, var2, var3)
        if event == "key" then
          if var1 == keys.d and not self:is_right_solid() then
            self.x = self.x + 1
          elseif var1 == keys.a and not self:is_left_solid() then
            self.x = self.x - 1
          elseif var1 == keys.space and self:stands_on_solid() then
            self.jumppower = 3
          end
        elseif string.sub(event, 1, 5) == "mouse" then
          local mouse_button = var1
          local mouse_x = var2
          local mouse_y = var3
          local window_x, window_y = term.getSize()
          local map_x = math.ceil(mouse_x+self.x-window_x/2)+1
          local map_y = math.ceil(mouse_y+self.y-window_y/2)+1
          if world.blocks[map_y] and world.blocks[map_y][map_x] and world.blocks[map_y][map_x].hardness then
            world.blocks[map_y][map_x].breakstage = world.blocks[map_y][map_x].breakstage + 1
          end
        end
      end
    )
  },
  items = {
    compass = new.item(
      new.texture(
        {
          {{"\159", "3", "7"}, {"\144", "7", "3"}},
          {{"\138", "0", "7"}, {"\133", "e", "7"}}
        },
        1,
        1,
        true
      ),
      "compass",
      function()
      end,
      0
    ),
    pickaxe = new.item(
      new.texture(
        {
          {{"\159", "3", "7"}, {"\144", "7", "3"}},
          {{"\138", "0", "7"}, {"\133", "e", "7"}}
        },
        1,
        1,
        true
      ),
      "iron pickaxe",
      function()
      end,
      0,
      1
    )
  },
  blockgens = {
    new.blockgen(4, {"stonewall"}, {"stone"}, 3),
    new.blockgen(
      3,
      {"leaves"},
      {"air"},
      3,
      function(spawnx, spawny)
        local treey = spawny
        while true do
          if world.blocks[treey] and world.blocks[treey][spawnx] and not world.blocks[treey][spawnx].solid then
            world.blocks[treey][spawnx] = get_instance_of(references.blocks.log)
            treey=treey+1
          else
            break
          end
        end
      end
    )
  }
}

references.blocks.biomes = {
  normal = {
    dirt = references.blocks.dirt,
    grass = references.blocks.grass,
    stone = references.blocks.stone,
    stonewall = references.blocks.stonewall,
    plant = references.blocks.plant,
    leaves = references.blocks.leaves
  },
  ice = {
    dirt = references.blocks.icedirt,
    grass = references.blocks.icegrass,
    stone = references.blocks.icestone,
    stonewall = references.blocks.icestonewall,
    plant = references.blocks.iceplant,
    leaves = references.blocks.iceleaves
  },
}

slots = {
  hotbar = {
    new.slot(1, 1, "3", "9", "1"),
    new.slot(5, 1, "3", "9", "2"),
    new.slot(9, 1, "3", "9", "3"),
    new.slot(13, 1, "3", "9", "4"),
    new.slot(17, 1, "3", "9", "5"),
    new.slot(21, 1, "3", "9", "6"),
  }
}

slots.hotbar[2].item = get_instance_of(references.items.pickaxe)
slots.hotbar[1].item = get_instance_of(references.items.compass)
world = {
  blocks = {},
  entitys = {
    player = get_instance_of(references.entitys.player, {x=1,y=1})
  },
  lights = {
    sun = new.light(1, 1, 200, "4")
  }
}

function generate_world(world_w, world_h, world_surface)
  local biome = references.blocks.biomes.normal
  local biomename = "normal"
  local surface_height = world_surface
  local mode = 0
  for x = 1, world_w do
    for y = 1, world_h do
      local block
      if y < surface_height then
        block = references.blocks.air
      elseif y == surface_height then
        block = biome.grass
      elseif y < surface_height+5 then
        block = biome.dirt
      elseif y > surface_height then
        block = biome.stone
      end
      if y == surface_height-1 and math.random(10) == 1 then
        block = biome.plant
      end

      if not world.blocks[y] then world.blocks[y] = {} end
      world.blocks[y][x] = get_instance_of(block)
      if math.random(1, 10) then
        mode = math.random(3)-2
      end
    end

    for _, blockgen in pairs(references.blockgens) do
      local gencount = 0
      if math.random(blockgen.count) == 1 then
        blockgen:generate(x-blockgen.size-1, math.random(world_w), biome)
      end
    end

    if math.random(1, 40) == 1 then
      for changebiomename, changebiome in pairs(references.blocks.biomes) do
        if changebiomename ~= biomename then
          biome = changebiome
          biomename = changebiomename
        end
      end
    end

    surface_height=surface_height+mode
  end
end

function draw_things()
  for y, yblocks in pairs(world.blocks) do
    for x, block in pairs(yblocks) do
      if block.hardness and block.breakstage>=block.hardness then
        local afterblock = references.blocks[block.afterblock]
        if not afterblock then afterblock = references.blocks.air end
        world.blocks[y][x] = get_instance_of(afterblock)
      end
      block:draw(x, y)
    end
  end
  for _, entity in pairs(world.entitys) do
    entity:draw()
  end
end

function draw_slots()
  for _, slottable in pairs(slots) do
    for _, slot in pairs(slottable) do
      slot:draw()
    end
  end
end
local sunmode = 1
function update(event, var1, var2, var3)
  world.lights.sun.x = world.entitys.player.x
  if world.lights.sun.power == 300 then
    sunmode = -1
  elseif world.lights.sun.power == 4 then
    sunmode = 1
  end
  world.lights.sun.power = world.lights.sun.power+0.2*sunmode
  for _, entity in pairs(world.entitys) do
    entity:update(event, var1, var2, var3)
  end
  for _, slottable in pairs(slots) do
    for _, slot in pairs(slottable) do
      slot:update(event, var1, var2, var3)
    end
  end
end

local w, h = term.getSize()
generate_world(w*3, h*2, 20)
local sunmode = 3
local buffer = window.create(term.current(), 1, 1, w, h)

while true do
  term.redirect(buffer)
  buffer.setVisible(false)
  buffer.reposition(-math.floor(w/2)-world.entitys.player.x, -math.floor(h/2)-world.entitys.player.y, w+world.entitys.player.x, h+world.entitys.player.y)
  term.clear()
  draw_things()
  buffer.reposition(math.floor(w/2)-world.entitys.player.x, math.floor(h/2)-world.entitys.player.y)
  buffer.redraw()
  buffer.setVisible(true)
  term.redirect(term.native())
  draw_slots()
  local startTime = os.clock()
  local timer = os.startTimer(dt)
  event, var1, var2, var3 = os.pullEventRaw()
  update(event, var1, var2, var3)
  os.cancelTimer(timer)
  if event ~= "timer" then sleep(dt-(startTime-os.clock())) end
end
