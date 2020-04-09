local running_send = minetest.mod_channel_join("running_send")
local running_receive = minetest.mod_channel_join("running_receive")

minetest.register_on_modchannel_message(function(channel_name, sender, message)
	if channel_name == "running_send" then
		local player = minetest.get_player_by_name(sender)
		local meta = player:get_meta()
		print(message)
		meta:set_string("player.player_running", message)
	end
end)

minetest.register_globalstep(function(dtime)
	for _,player in ipairs(minetest.get_connected_players()) do
		local meta = player:get_meta()
		
		local run = (meta:get_string("player.player_running") == "true")
		
		--running FOV modifier
		if run then
			--remember to implement hunger
			local fov = player:get_fov()
			if fov == 0 then
				fov = 1
			end
			
			if fov < 1.2 then
				player:set_fov(fov + dtime, true)
			elseif fov > 1.2 then
				player:set_fov(1.2, true)
			end
			
			player:set_physics_override({speed=1.5})
		else
			local meta = player:get_meta()
			local fov = player:get_fov()
			if fov > 1 then
				player:set_fov(fov - dtime, true)
			elseif fov < 1 then
				player:set_fov(1, true)
			end
			
			player:set_physics_override({speed=1})
			--meta:set_float("running_timer", 0)
		end
		
		--sneaking
		if sneak then
			player:set_eye_offset({x=0,y=-1,z=0},{x=0,y=-1,z=0})
		else
			player:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
		end
		
		--eating
		if player:get_player_control().RMB then
			local health = player:get_wielded_item():get_definition().health
			if health then
				local meta = player:get_meta()
				local eating = meta:get_float("eating")
				local eating_timer = meta:get_float("eating_timer")
				
				eating = eating + dtime
				eating_timer = eating_timer + dtime
				
				local ps = minetest.add_particlespawner({
					amount = 30,
					time = 0.00001,
					minpos = {x=-0.2, y=-1.5, z=0.5},
					maxpos = {x=0.2, y=1.7, z=0.5},
					minvel = vector.new(-0.5,0,-0.5),
					maxvel = vector.new(0.5,0,0.5),
					minacc = {x=0, y=-9.81, z=1},
					maxacc = {x=0, y=-9.81, z=1},
					minexptime = 0.5,
					maxexptime = 1.5,
					minsize = 0.5,
					maxsize = 1,
					attached = player,
					collisiondetection = true,
					collision_removal = true,
					vertical = false,
					texture = "eat_particles_1.png"
				})
				
				if eating_timer + dtime > 0.25 then
					minetest.sound_play("eat", {
						to_player = player:get_player_name(),
						gain = 1.0,  -- default
						pitch = math.random(60,100)/100,
					})
					eating_timer = 0
				end
				
				if eating + dtime >= 1 then
					local stack = player:get_wielded_item()
					stack:take_item(1)
					player:set_wielded_item(stack)
					player:set_hp(player:get_hp() + health)
					eating = 0
					minetest.sound_play("eat_finish", {
						to_player = player:get_player_name(),
						gain = 0.2,  -- default
						pitch = math.random(60,85)/100,
					})
				end
				
				meta:set_float("eating_timer", eating_timer)
				meta:set_float("eating", eating)
			else
				local meta = player:get_meta()
				meta:set_float("eating", 0)
				meta:set_float("eating_timer", 0)
				
			end
		else
			local meta = player:get_meta()
			meta:set_float("eating", 0)
			meta:set_float("eating_timer", 0)
		end
		
	end
end)
