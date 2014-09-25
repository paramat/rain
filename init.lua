-- rain 0.1.2 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL, textures CC BY-SA

-- Lower cloud. dissolve over desert
-- TODO
-- 64x64 XZ raincloud at y = 64
-- spawns over northern coast near deep water: check for deep water and scan south for dirt
-- before cloud spawn check for desert sand -> return

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
	post_effect_color = {a=127, r=162, g=166, b=171},
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

minetest.register_node("rain:rainabm", {
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

-- ABM

-- Spawn raincloud above northern coast near deep water

minetest.register_abm({
	nodenames = {"default:water_source"},
	interval = 3,
	chance = 32768,
	action = function(pos, node)
		local x = pos.x
		local y = pos.y
		local z = pos.z
		local c_air = minetest.get_content_id("air")
		local c_water = minetest.get_content_id("default:water_source")
		local c_dirt = minetest.get_content_id("default:dirt")
		local c_rain = minetest.get_content_id("rain:rain")
		local c_rainabm = minetest.get_content_id("rain:rainabm")
		local c_cloud = minetest.get_content_id("rain:cloud")

		local vm = minetest.get_voxel_manip() -- large flat volume for cloud check
		local pos1 = {x=x-128, y=64, z=z-128}
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
		local pos1 = {x=x, y=1, z=z}
		local pos2 = {x=x+31, y=111, z=z+31}
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()
		local vvii = emax.x - emin.x + 1 -- vertical vi interval
		-- local nvii = (emax.y - emin.y + 1) * vvii

		for y = 64, 111 do
		for k = 0, 31 do
			local vi = area:index(x, y, z + k)
			for i = 0, 31 do
				data[vi] = c_cloud
				if y == 64 and k == 0 and i == 15 then -- rain abm column
					local vir = vi - vvii
					for fall = 1, 63 do
						if data[vir] == c_air then
							data[vir] = c_rainabm
						else
							break
						end
						vir = vir - vvii
					end
				elseif y == 64 and math.random() < 0.25 then
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
	nodenames = {"rain:rainabm"},
	interval = 7,
	chance = 128,
	action = function(pos, node)
		local x = pos.x
		local z = pos.z
		local c_air = minetest.get_content_id("air")
		local c_water = minetest.get_content_id("default:water_source")
		local c_desand = minetest.get_content_id("default:desert_sand")
		local c_rain = minetest.get_content_id("rain:rain")
		local c_rainabm = minetest.get_content_id("rain:rainabm")
		local c_cloud = minetest.get_content_id("rain:cloud")

		local vm = minetest.get_voxel_manip()
		local pos1 = {x=x-15, y=1, z=z-1}
		local pos2 = {x=x+16, y=111, z=z+31}
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()
		local vvii = emax.x - emin.x + 1 -- vertical vi interval

		local dissolve = false -- check ground for desert sand
		for vi in area:iterp(pos1, {x=x+16, y=47, z=z+31}) do
			if data[vi] == c_desand then
				dissolve = true
				break
			end
		end

		if dissolve then -- erase cloud and rain
			for vi in area:iterp(pos1, pos2) do
				if data[vi] == c_cloud
				or data[vi] == c_rain
				or data[vi] == c_rainabm then
					data[vi] = c_air
				end
			end
			vm:set_data(data)
			vm:write_to_map()
			vm:update_map()
			return
		end

		for y = 63, 111 do -- spawn and erase cloud and rain columns
		for k = -1, 31 do
			local vi = area:index(x-15, y, z+k)
			for i = -15, 16 do
				if k == -1 then
					if y >= 64 then -- new cloud
						data[vi] = c_cloud
					elseif y == 63 and i == 0 then -- new rain abm column
						local vir = vi
						for fall = 1, 63 do
							if data[vir] == c_air then
								data[vir] = c_rainabm
							else
								break
							end
							vir = vir - vvii
						end
					elseif y == 63 and math.random() < 0.25 then -- new rain
						local vir = vi
						for fall = 1, 63 do
							if data[vir] == c_air then
								data[vir] = c_rain
							else
								break
							end
							vir = vir - vvii
						end
					end
				elseif k == 0 and y == 63 and i == 0 then -- erase previous rain abm column
					local vir = vi
					for fall = 1, 63 do
						if data[vir] == c_rainabm then
							data[vir] = c_air
						else
							break
						end
						vir = vir - vvii
					end
				elseif k == 31 and y >= 63 then -- erase previous cloud and rain
					local nodid = data[vi]
					if nodid == c_cloud then
						data[vi] = c_air
					elseif nodid == c_rain then
						local vir = vi
						for fall = 1, 63 do
							if data[vir] == c_rain then
								data[vir] = c_air
							else
								break
							end
							vir = vir - vvii
						end
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

