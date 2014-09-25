-- rain 0.1.3 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL, textures CC BY-SA

-- 64x64 XZ raincloud at y = 64
-- spawns over grass in more mgv6-humid areas, also away from deserts by biome noise
-- fix cloud eating floatlands
-- TODO
-- move 16 nodes at a time less frequently

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

-- Spawn raincloud

minetest.register_abm({
	nodenames = {"default:dirt_with_grass"},
	interval = 61,
	chance = 4096,
	action = function(pos, node)
		local x = pos.x
		local y = pos.y
		local z = pos.z

		local desnoise = minetest.get_perlin(9130, 3, 0.5, 250) -- check biome and humidity
		local humnoise = minetest.get_perlin(72384, 4, 0.66, 500)
		if not (desnoise:get2d({x=x+150,y=z+50}) < -0.4
		and humnoise:get2d({x=x+250,y=z+250}) > 0.4) then
			return
		end

		local c_air = minetest.get_content_id("air")
		local c_rain = minetest.get_content_id("rain:rain")
		local c_rainabm = minetest.get_content_id("rain:rainabm")
		local c_cloud = minetest.get_content_id("rain:cloud")

		local vm = minetest.get_voxel_manip() -- large flat volume for cloud check
		local pos1 = {x=x-160, y=64, z=z-144}
		local pos2 = {x=x+159, y=64, z=z+175}
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()

		for vi in area:iterp(emin, emax) do -- check volume is clear of cloud
			if data[vi] == c_cloud then
				return
			end
		end

		local vm = minetest.get_voxel_manip() -- spawn cloud and rain columns
		local pos1 = {x=x-32, y=1, z=z-16}
		local pos2 = {x=x+31, y=95, z=z+47}
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()
		local vvii = emax.x - emin.x + 1 -- vertical vi interval
		-- local nvii = (emax.y - emin.y + 1) * vvii

		for y = 64, 95 do
		for k = -16, 47 do
			local vi = area:index(x-32, y, z + k)
			for i = -32, 31 do
				if data[vi] == c_air then
					data[vi] = c_cloud
				end
				if y == 64 and k == 0 and i == 0 then -- rain abm column
					local vir = vi - vvii
					for fall = 1, 63 do
						if data[vir] == c_air then
							data[vir] = c_rainabm
						else
							break
						end
						vir = vir - vvii
					end
				elseif y == 64 and i >= -16 and i <= 15 -- rain columns
				and k >= 0 and k <= 31 and math.random() < 0.25 then
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
	chance = 64,
	action = function(pos, node)
		local x = pos.x
		local z = pos.z
		local c_air = minetest.get_content_id("air")
		local c_desand = minetest.get_content_id("default:desert_sand")
		local c_rain = minetest.get_content_id("rain:rain")
		local c_rainabm = minetest.get_content_id("rain:rainabm")
		local c_cloud = minetest.get_content_id("rain:cloud")

		local vm = minetest.get_voxel_manip()
		local pos1 = {x=x-32, y=1, z=z-16}
		local pos2 = {x=x+31, y=95, z=z+47}
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()
		local vvii = emax.x - emin.x + 1 -- vertical vi interval

		local dissolve = false -- check ground for desert sand
		for vi in area:iterp(pos1, {x=x+31, y=47, z=z+47}) do
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

		for y = 63, 95 do -- spawn and erase cloud and rain columns
		for k = -16, 47 do
			local vi = area:index(x-32, y, z+k)
			for i = -32, 31 do
				if k == -16 then
					if y >= 64 and data[vi] == c_air then -- new cloud
						data[vi] = c_cloud
					end
				elseif k == -1 and y == 63 then
					if i == 0 then -- new rain abm column
						local vir = vi
						for fall = 1, 63 do
							if data[vir] == c_air then
								data[vir] = c_rainabm
							else
								break
							end
							vir = vir - vvii
						end
					elseif i >= -16 and i <= 15
					and math.random() < 0.25 then -- new rain
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
				elseif k == 0 and y == 63 and i == 0 then -- erase previous rainabm column
					local vir = vi
					for fall = 1, 63 do
						if data[vir] == c_rainabm then
							data[vir] = c_air
						else
							break
						end
						vir = vir - vvii
					end
				elseif k == 31 and y == 63 
				and i >= -16 and i <= 15 then -- erase previous rain
					local nodid = data[vi]
					if nodid == c_rain then
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
				elseif k == 47 and y >= 64 then -- erase previous cloud
					local nodid = data[vi]
					if nodid == c_cloud then
						data[vi] = c_air
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

