local dt = 0.1

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
  texture = function(texture_table, anchorX, anchorY)
    return {
      texture_table=texture_table,
      anchorX = anchorX or 0,
      anchorY = anchorY or 0,
      draw = function(self, txtrx, txtry)
        for y, texturestring in pairs(self.texture_table) do
          for x, txtr in pairs(texturestring) do if txtr then
            local char = txtr[1]
            local charCol = txtr[2]
            local backCol = txtr[3]
            local drawX = txtrx+x+self.anchorX-1
            local drawY = txtry+y+self.anchorY-1
            local nearest_light = world.lights.sun
            local light_distance = distance(nearest_light.x, nearest_light.y, drawX, drawY)

            for _, light in pairs(world.lights) do
              if distance(light.x, light.y, drawX, drawY) < light_distance then nearest_light = light end
            end

            if light_distance < nearest_light.power/6 then charCol = nearest_light.color
            elseif light_distance < nearest_light.power/3 then backCol = darker[backCol]
            elseif light_distance < nearest_light.power/2 then backCol = darker[backCol] charCol = darker[charCol] char = "\127"
            elseif light_distance < nearest_light.power/1 then if char == " " then char = "\127" end backCol = darker[backCol] backCol = darker[backCol] charCol = darker[charCol] charCol = darker[charCol]
          else backCol = darker[darker[darker[backCol]]] charCol = darker[darker[charCol]] if char == " " then char = "\127" end
            end

            term.setCursorPos(drawX, drawY)
            term.blit(char, charCol, backCol)
          end end
        end
      end
    }
  end,
  block = function(texture, name, hardness, glowing_strenght, solid, afterblock)
    return {
      texture=texture,
      name=name,
      hardness=hardness,
      glowing_strenght=glowing_strenght,
      solid=solid,
      afterblock=afterblock,
      draw = function(self, x, y)
        self.texture:draw(x, y)
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
  item = function(texture, name, use_function, glowing_strenght)
    return {
      texture = texture,
      name = name,
      use_function = use_function,
      glowing_strenght = glowing_strenght,
      draw = function(x, y)
      end
    }
  end
}

references = {
  blocks = {
    biomes = {
      normal = {
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
      },
      ice = {
        dirt = new.block(
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
          "icewall"
        ),
        grass = new.block(
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
        stone = new.block(
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
        stonewall = new.block(
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
        plant = new.block(
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
        leaves = new.block(
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
      }
    },
    air = new.block(
      new.texture(
        {
          {
            {" ", "3", "3"}
          }
        }
      ),
      "air",
      1000,
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
  },
  entitys = {
    player = new.entity(
      1, 1,
      new.texture(
        {
          {nil, {"\2", "0", "6"}, nil},
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
          if var1 == keys.d then
            self.x = self.x + 1
          elseif var1 == keys.a then
            self.x = self.x - 1
          elseif var1 == keys.space and self:stands_on_solid() then
            self.jumppower = 3
          end
        end
      end
    )
  },
  items = {},
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

world = {
  blocks = {},
  entitys = {
    player = get_instance_of(references.entitys.player, {x=1,y=1})
  },
  lights = {
    sun = new.light(1, 1, 4, "4")
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
      world.blocks[y][x] = block
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
      block:draw(x, y)
    end
  end
  for _, entity in pairs(world.entitys) do
    entity:draw()
  end
end

function update(event, var1, var2, var3)
  world.lights.sun.x = world.entitys.player.x
  if world.lights.sun.power == 1000 then
    sunmode = -1
  elseif world.lights.sun.power == 4 then
    sunmode = 1
  end
  world.lights.sun.power = world.lights.sun.power+sunmode
  for _, entity in pairs(world.entitys) do
    entity:update(event, var1, var2, var3)
  end
end

local w, h = term.getSize()
generate_world(w*3, h*2, 20)
local sunmode = 1
local buffer = window.create(term.current(), 1, 1, w, h)

while true do
  term.redirect(buffer)
  buffer.setVisible(false)
  buffer.reposition(
    -math.floor(w/2)-world.entitys.player.x,
    -math.floor(h/2)-world.entitys.player.y,
    w+world.entitys.player.x,
    h+world.entitys.player.y)
  term.clear()
  draw_things()
  buffer.reposition(
    math.floor(w/2)-world.entitys.player.x,
    math.floor(h/2)-world.entitys.player.y
  )
  local bufx, bufy = buffer.getPosition()
  if bufx > 1 then buffer.reposition(1, bufy) end
  if bufy > 1 then buffer.reposition(bufx, 1) end
  buffer.redraw()
  buffer.setVisible(true)
  term.redirect(term.native())
  local startTime = os.clock()
  local timer = os.startTimer(dt)
  event, var1, var2, var3 = os.pullEventRaw()
  update(event, var1, var2, var3)
  os.cancelTimer(timer)
  if event ~= "timer" then sleep(dt-(startTime-os.clock())) end
end
