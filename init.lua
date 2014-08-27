-- rain 0.1.1 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL, textures CC BY-SA

-- bugfixes
-- faster rain
-- standard drawtype cloud for shading
-- new post effect colour
-- TODO
-- 64x64 XZ raincloud
-- dissolves over desert

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

-- Spawn raincloud above grass

minetest.register_abm({
	nodenames = {"default:dirt_with_grass"},
	interval = 13,
	chance = 2048,
	action = function(pos, node)
		local x = pos.x
		local y = pos.y
		local z = pos.z
		local c_air = minetest.get_content_id("air")
		local c_rain = minetest.get_content_id("rain:rain")
		local c_rainabm = minetest.get_content_id("rain:rainabm")
		local c_cloud = minetest.get_content_id("rain:cloud")

		local vm = minetest.get_voxel_manip() -- volume for cloud check
		local pos1 = {x=x-128, y=104, z=z-128}
		local pos2 = {x=x+159, y=104, z=z+159}
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()

		for vi in area:iterp(emin, emax) do -- check volume is clear of cloud
			if data[vi] == c_cloud then
				return
			end
		end

		local vm = minetest.get_voxel_manip()
		local pos1 = {x=x, y=y-48, z=z}
		local pos2 = {x=x+31, y=y+135, z=z+31}
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()
		local vvii = emax.x - emin.x + 1 -- vertical vi interval
		-- local nvii = (emax.y - emin.y + 1) * vvii

		for y = 104, 135 do -- spawn cloud and rain columns
		for k = 0, 31 do
			local vi = area:index(x, y, z + k)
			for i = 0, 31 do
				data[vi] = c_cloud
				if y == 104 and k == 0 and i == 15 then -- rain abm column
					local vir = vi - vvii
					for fall = 1, 144 do
						if data[vir] == c_air then
							data[vir] = c_rainabm
						else
							break
						end
						vir = vir - vvii
					end
				elseif y == 104 and math.random() < 0.25 then
					local vir = vi - vvii
					for fall = 1, 144 do
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

-- Drift raincloud southward

minetest.register_abm({
	nodenames = {"rain:rainabm"},
	interval = 7,
	chance = 128,
	action = function(pos, node)
		local x = pos.x
		local z = pos.z
		local c_air = minetest.get_content_id("air")
		local c_rain = minetest.get_content_id("rain:rain")
		local c_rainabm = minetest.get_content_id("rain:rainabm")
		local c_cloud = minetest.get_content_id("rain:cloud")

		local vm = minetest.get_voxel_manip()
		local pos1 = {x=x-15, y=1, z=z-1}
		local pos2 = {x=x+16, y=135, z=z+31}
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()
		local vvii = emax.x - emin.x + 1 -- vertical vi interval

		for y = 103, 135 do -- spawn and erase cloud and rain columns
		for k = -1, 31, 1 do
			local vi = area:index(x-15, y, z+k)
			for i = -15, 16, 1 do
				if k == -1 then
					if y >= 104 then -- new cloud
						data[vi] = c_cloud
					elseif y == 103 and i == 0 then -- new rain abm column
						local vir = vi
						for fall = 1, 144 do
							if data[vir] == c_air then
								data[vir] = c_rainabm
							else
								break
							end
							vir = vir - vvii
						end
					elseif y == 103 and math.random() < 0.25 then -- new rain
						local vir = vi
						for fall = 1, 144 do
							if data[vir] == c_air then
								data[vir] = c_rain
							else
								break
							end
							vir = vir - vvii
						end
					end
				elseif k == 0 and y == 103 and i == 0 then -- erase previous rain abm column
					local vir = vi
					for fall = 1, 144 do
						if data[vir] == c_rainabm then
							data[vir] = c_air
						else
							break
						end
						vir = vir - vvii
					end
				elseif k == 31 and y >= 103 then -- erase previous cloud and rain
					local nodid = data[vi]
					if nodid == c_cloud then
						data[vi] = c_air
					elseif nodid == c_rain then
						local vir = vi
						for fall = 1, 144 do
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

