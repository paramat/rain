-- rain 0.1.4 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL, textures CC BY-SA

-- drift by 4 nodes
-- abm node column at each corner
-- larger rain area

-- Parameters

local SPAWN = true -- Spawn new rainclouds in humid areas away from deserts
local CLEAR = false -- Clear rainclouds when players are near
local DEST = 0.4 -- Desert noise threshold
local HUMT = -2 -- Humidity noise threshold

-- Nodes

minetest.register_node("rain:cloud", {
	description = "Rain Cloud",
	tiles = {"rain_cloud.png"},
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
})

minetest.register_node("rain:rain", {
	description = "Rain",
	drawtype = "plantlike",
	tiles = {
		{
			name="rain_rain.png",
			animation={type="vertical_frames",
			aspect_w=16, aspect_h=16, length=0.2}
		}
	},
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
})

minetest.register_node("rain:abmne", {
	description = "ABM trigger NE",
	drawtype = "airlike",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
})

minetest.register_node("rain:abmnw", {
	description = "ABM trigger NW",
	drawtype = "airlike",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
})

minetest.register_node("rain:abmse", {
	description = "ABM trigger SE",
	drawtype = "airlike",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
})

minetest.register_node("rain:abmsw", {
	description = "ABM trigger SW",
	drawtype = "airlike",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
})

-- ABM

-- Spawn raincloud

minetest.register_abm({
	nodenames = {"default:dirt_with_grass"},
	interval = 11,
	chance = 4096,
	action = function(pos, node)
		if not SPAWN then
			return
		end
		local x = pos.x
		local y = pos.y
		local z = pos.z

		local desnoise = minetest.get_perlin(9130, 3, 0.5, 250) -- check biome and humidity
		local humnoise = minetest.get_perlin(72384, 4, 0.66, 500)
		if not (desnoise:get2d({x=x+150,y=z+50}) < DEST
		and humnoise:get2d({x=x+250,y=z+250}) > HUMT) then
			return
		end

		local c_air = minetest.get_content_id("air")
		local c_rain = minetest.get_content_id("rain:rain")
		local c_abmne = minetest.get_content_id("rain:abmne")
		local c_abmnw = minetest.get_content_id("rain:abmnw")
		local c_abmse = minetest.get_content_id("rain:abmse")
		local c_abmsw = minetest.get_content_id("rain:abmsw")
		local c_cloud = minetest.get_content_id("rain:cloud")

		local vm = minetest.get_voxel_manip() -- large flat volume for cloud check
		local pos1 = {x=x-160, y=64, z=z-160}
		local pos2 = {x=x+159, y=64, z=z+159}
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()

		for vi in area:iterp(emin, emax) do -- check volume is clear of cloud
			if data[vi] == c_cloud then
				return
			end
		end

		local vm = minetest.get_voxel_manip() -- spawn cloud and rain columns
		local pos1 = {x=x-32, y=1, z=z-32}
		local pos2 = {x=x+31, y=79, z=z+31}
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()
		local vvii = emax.x - emin.x + 1 -- vertical vi interval
		-- local nvii = (emax.y - emin.y + 1) * vvii

		for y = 64, 79 do
		for k = -32, 31 do
			local vi = area:index(x-32, y, z + k)
			for i = -32, 31 do
				if data[vi] == c_air then
					data[vi] = c_cloud
				end
				if y == 64 and k == 31 and i == 31 then -- abm column
					local vir = vi - vvii
					for fall = 1, 63 do
						if data[vir] == c_air then
							data[vir] = c_abmne
						else
							break
						end
						vir = vir - vvii
					end
				elseif y == 64 and k == 31 and i == -32 then -- abm column
					local vir = vi - vvii
					for fall = 1, 63 do
						if data[vir] == c_air then
							data[vir] = c_abmnw
						else
							break
						end
						vir = vir - vvii
					end
				elseif y == 64 and k == -32 and i == 31 then -- abm column
					local vir = vi - vvii
					for fall = 1, 63 do
						if data[vir] == c_air then
							data[vir] = c_abmse
						else
							break
						end
						vir = vir - vvii
					end
				elseif y == 64 and k == -32 and i == -32 then -- abm column
					local vir = vi - vvii
					for fall = 1, 63 do
						if data[vir] == c_air then
							data[vir] = c_abmsw
						else
							break
						end
						vir = vir - vvii
					end
				elseif y == 64 and i >= -24 and i <= 23 -- rain columns
				and k >= -24 and k <= 23 and math.random() < 0.25 then
					local vir = vi - vvii
					for fall = 1, 63 do
						if data[vir] == c_air then
							data[vir] = c_rain
						else
							break
						end
						vir = vir - vvii
					end
				end
				vi = vi + 1
			end
		end
		end

		vm:set_data(data)
		vm:write_to_map()
		vm:update_map()
	end,
})

-- Dissolve over desert or drift raincloud southward

minetest.register_abm({
	nodenames = {"rain:abmne", "rain:abmnwx", "rain:abmse", "rain:abmsw"},
	interval = 11,
	chance = 64,
	action = function(pos, node)
		local x = pos.x
		local z = pos.z
		local c_node = minetest.get_content_id(node.name)

		local c_air = minetest.get_content_id("air")
		local c_desand = minetest.get_content_id("default:desert_sand")
		local c_rain = minetest.get_content_id("rain:rain")
		local c_abmne = minetest.get_content_id("rain:abmne")
		local c_abmnw = minetest.get_content_id("rain:abmnw")
		local c_abmse = minetest.get_content_id("rain:abmse")
		local c_abmsw = minetest.get_content_id("rain:abmsw")
		local c_cloud = minetest.get_content_id("rain:cloud")

		local pos1 = {x=0, y=1, z=0}
		local pos2 = {x=0, y=79, z=0}
		if c_node == c_abmne then
			pos1.x = x - 63
			pos1.z = z - 67
			pos2.x = x
			pos2.z = z
		elseif c_node == c_abmnw then
			pos1.x = x
			pos1.z = z - 67
			pos2.x = x + 63
			pos2.z = z
		elseif c_node == c_abmse then
			pos1.x = x - 63
			pos1.z = z - 4
			pos2.x = x
			pos2.z = z + 63
		elseif c_node == c_abmsw then
			pos1.x = x
			pos1.z = z - 4
			pos2.x = x + 63
			pos2.z = z + 63
		end

		local vm = minetest.get_voxel_manip()
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()
		local vvii = emax.x - emin.x + 1 -- vertical vi interval

		local desert = false -- check ground for desert sand
		for vi in area:iterp({x=pos1.x, y=1, z=pos1.z}, {x=pos2.x, y=47, z=pos2.z}) do
			if data[vi] == c_desand then
				desert = true
				break
			end
		end

		if desert or CLEAR then -- erase cloud and rain
			for vi in area:iterp(pos1, pos2) do
				if data[vi] == c_cloud
				or data[vi] == c_rain
				or data[vi] == c_abmne
				or data[vi] == c_abmnw
				or data[vi] == c_abmse
				or data[vi] == c_abmsw then
					data[vi] = c_air
				end
			end
			vm:set_data(data)
			vm:write_to_map()
			vm:update_map()
			return
		end

		 -- spawn/erase cloud, rain, abm columns
		for zz = pos1.z, pos2.z do
		for yy = 1, 79 do
			local vi = area:index(pos1.x, yy, zz)
			for xx = pos1.x, pos2.x do
				local nodid = data[vi]
				if yy >= 64 then
					if zz <= pos1.z + 3 and nodid == c_air then -- new cloud
						data[vi] = c_cloud
					elseif zz >= pos2.z - 3 and nodid == c_cloud then -- erase previous cloud
						data[vi] = c_air
					end
				elseif xx == pos2.x and zz == pos2.z - 4 and nodid == c_air then -- new abm columns
					data[vi] = c_abmne
				elseif xx == pos1.x and zz == pos2.z - 4 and nodid == c_air then
					data[vi] = c_abmnw
				elseif xx == pos2.x and zz == pos1.z and nodid == c_air then
					data[vi] = c_abmse
				elseif xx == pos1.x and zz == pos1.z and nodid == c_air then
					data[vi] = c_abmsw
				elseif yy == 63 and xx >= pos1.x + 8 and xx <= pos2.x - 8 -- new rain columns
				and zz >= pos1.z + 8 and zz <= pos1.z + 11
				and math.random() < 0.25 then
					local vir = vi
					for fall = 1, 63 do
						if data[vir] == c_air then
							data[vir] = c_rain
						else
							break
						end
						vir = vir - vvii
					end
				elseif xx == pos2.x and zz == pos2.z and nodid == c_abmne then -- erase previous abm columns
					data[vi] = c_air
				elseif xx == pos1.x and zz == pos2.z and nodid == c_abmnw then
					data[vi] = c_air
				elseif xx == pos2.x and zz == pos1.z + 4 and nodid == c_abmse then
					data[vi] = c_air
				elseif xx == pos1.x and zz == pos1.z + 4 and nodid == c_abmsw then
					data[vi] = c_air
				elseif zz >= pos2.z - 11 and nodid == c_rain then -- erase previous rain
					data[vi] = c_air
				end
				vi = vi + 1
			end
		end
		end

		vm:set_data(data)
		vm:write_to_map()
		vm:update_map()
	end,
})

