-- rain 0.1.1 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default bucket
-- License: code WTFPL, textures CC BY-SA

-- Parameters



-- Nodes

minetest.register_node("rain:cloud", {
	description = "Rain Cloud",
	drawtype = "glasslike",
	tiles = {"rain_cloud.png"},
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	post_effect_color = {a=23, r=241, g=248, b=255},
})

minetest.register_node("rain:rain", {
	description = "Rain",
	drawtype = "plantlike",
	tiles = {
		{
			name="rain_rain.png",
			animation={type="vertical_frames",
			aspect_w=16, aspect_h=16, length=0.25}
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
		local c_cloud = minetest.get_content_id("rain:cloud")

		local vm = minetest.get_voxel_manip() -- volume for cloud check
		local pos1 = {x=x-64, y=104, z=z-64}
		local pos2 = {x=x+95, y=104, z=z+95}
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
		local pos2 = {x=x+31, y=y+134, z=z+31}
		local emin, emax = vm:read_from_map(pos1, pos2)
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()
		local vvii = emax.x - emin.x + 1  -- vertical vi interval
		-- local nvii = (emax.y - emin.y + 1) * vvii

		for y = 104, 135 do -- spawn cloud and rain columns
		for k = 0, 31 do
			local vi = area:index(x, y, z + k)
			for i = 0, 31 do
				data[vi] = c_cloud
				if y == 104 and math.random() < 0.25
				and k >= 4 and k <= 27 and i >= 4 and i <= 27 then
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
