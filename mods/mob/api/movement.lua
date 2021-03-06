--
mobs.create_movement_functions = function(def,mob_register)
	--makes the mob swim
	mob_register.swim = function(self,dtime)
		local pos = self.object:get_pos()
		pos.y = pos.y + 0.3
		local node = minetest.get_node(pos).name
		self.swimming = false
		if node == "main:water" or node =="main:waterflow" then
			local vel = self.object:get_velocity()
			local goal = 3
			local acceleration = vector.new(0,goal-vel.y,0)
			--jump out of the water
			if (vel.x == 0 and self.direction.x ~= 0) or (vel.z == 0 and self.direction.z ~= 0) then
				self.object:set_velocity(vector.new(vel.x,5,vel.z))
			--else swim
			else
				self.object:add_velocity(acceleration)
			end
			self.swimming = true
		end
	end

	local get_group = minetest.get_item_group
	local get_node = minetest.get_node
	mob_register.hurt_inside = function(self,dtime)
		if self.hp > 0 and self.hurt_inside_timer <= 0 then
			local pos = self.object:get_pos()
			local hurty = get_group(get_node(pos).name, "hurt_inside")
			if hurty > 0 then
				self.object:punch(self.object, 2, 
					{
					full_punch_interval=1.5,
					damage_groups = {damage=hurty},
				})
			end
			self.hurt_inside_timer = 0.25
		else
			self.hurt_inside_timer = self.hurt_inside_timer - dtime
		end
	end

	--This makes the mob walk at a certain speed and jump
	if def.movement_type == "walk" then
		mob_register.move = function(self,dtime,moveresult)
			self.manage_jump_timer(self,dtime)
			self.timer = self.timer - dtime

			--jump
			self.jump(self,moveresult)
			
			--swim
			self.swim(self,dtime)
			
			--print(self.timer)
			--direction state change
			if self.timer <= 0 and not self.following == true then
				--print("changing direction")
				self.timer = math.random(2,7)
				self.direction = vector.new(math.random()*math.random(-1,1),0,math.random()*math.random(-1,1))
				--local yaw = self.object:get_yaw() + dtime
				self.speed = math.random(0,self.max_speed)
				--self.object:set_yaw(yaw)
			end

			self.hurt_inside(self,dtime)

			local currentvel = self.object:get_velocity()
			local goal = vector.multiply(self.direction,self.speed)
			local acceleration = vector.new(goal.x-currentvel.x,0,goal.z-currentvel.z)
			acceleration = vector.multiply(acceleration, 0.05)
			self.object:add_velocity(acceleration)
		end
		mob_register.jump = function(self,moveresult)
			if moveresult and moveresult.touching_ground and self.direction then
				local pos = self.object:get_pos()
				pos.y = pos.y+0.1

				if self.path_data and table.getn(self.path_data) > 0 then
					--smart jump
					local y = math.floor(pos.y+0.5)
					local vel = self.object:get_velocity()
					if y < self.path_data[1].y then
						self.object:set_velocity(vector.new(vel.x,5,vel.z))
					elseif self.path_data[2] and y < self.path_data[2].y then
						self.object:set_velocity(vector.new(vel.x,5,vel.z))
					elseif self.path_data[3] and y < self.path_data[3].y then
						self.object:set_velocity(vector.new(vel.x,5,vel.z))
					elseif ((vel.x == 0 and self.direction.x ~= 0) or (vel.z == 0 and self.direction.z ~= 0)) then
						self.object:set_velocity(vector.new(vel.x,5,vel.z))
					end
				else
					--assume collisionbox is even x and z
					local modifier = self.object:get_properties().collisionbox[4]*3
					

					local pos2 = vector.add(vector.multiply(self.direction,modifier),pos)

					local ray = minetest.raycast(pos, pos2, false, false)
					
					local pointed_thing

					if ray then
						pointed_thing = ray:next()
					end
						
					if pointed_thing then
						if minetest.get_nodedef(minetest.get_node(pointed_thing.under).name, "walkable") then
							--print("jump")
							local vel = self.object:get_velocity()
							--self.jump_timer = 1+math.random()
							self.object:set_velocity(vector.new(vel.x,5,vel.z))
						else
							--print("velocity check")
							local vel = self.object:get_velocity()
							if (vel.x == 0 and self.direction.x ~= 0) or (vel.z == 0 and self.direction.z ~= 0) then
								self.object:set_velocity(vector.new(vel.x,5,vel.z))
							end
						end
					else
						--print("velcheck 2")
						local vel = self.object:get_velocity()
						if (vel.x == 0 and self.direction.x ~= 0) or (vel.z == 0 and self.direction.z ~= 0) then
							self.object:set_velocity(vector.new(vel.x,5,vel.z))
						end
					end
				end
			end
		end
	elseif def.movement_type == "jump" then
		mob_register.move = function(self,dtime,moveresult)
			self.manage_jump_timer(self,dtime)
			self.timer = self.timer - dtime
			
			--jump
			self.jump(self,moveresult)
			
			--swim
			self.swim(self,dtime)
			
			--print(self.timer)
			--direction state change
			if self.timer <= 0 and not self.following == true then
				--print("changing direction")
				self.timer = math.random(2,7)
				self.direction = vector.new(math.random()*math.random(-1,1),0,math.random()*math.random(-1,1))
				--local yaw = self.object:get_yaw() + dtime
				self.speed = math.random(0,self.max_speed)
				--self.object:set_yaw(yaw)
			end

			self.hurt_inside(self,dtime)	
			
			local currentvel = self.object:get_velocity()
			if currentvel.y ~= 0 then
				local goal = vector.multiply(self.direction,self.speed)
				local acceleration = vector.new(goal.x-currentvel.x,0,goal.z-currentvel.z)
				acceleration = vector.multiply(acceleration, 0.05)
				self.object:add_velocity(acceleration)
			end
		end
		
		mob_register.jump = function(self,moveresult)
			if moveresult and moveresult.touching_ground and self.direction then
				if self.jump_timer <= 0 then
					if self.make_jump_noise then
						minetest.sound_play("slime_splat", {object=self.object, gain = 1.0, max_hear_distance = 10,pitch = math.random(80,100)/100})
					end
					local vel = self.object:get_velocity()
					self.object:set_velocity(vector.new(vel.x,5,vel.z))
					if self.following == true then
						self.jump_timer = 0.5
					else
						self.jump_timer = 1+math.random()
					end
				else
					self.object:set_velocity(vector.new(0,0,0))
				end
			end
		end
	end
	
	if def.pathfinds then
		mob_register.pathfinding = function(self,dtime)
			if self.following and self.following_pos then
				self.pathfinding_timer = self.pathfinding_timer + dtime
				if self.pathfinding_timer > 1 or not self.path_data then
					self.pathfinding_timer = 0

					local path = minetest.find_path(self.object:get_pos(),self.following_pos,self.view_distance*2,1,1,"A*")
					
					if path and not self.path_data or (self.path_data and table.getn(self.path_data) < 1) then
						self.path_data = path
					end
					--[[
					if self.path_data then
						for index,pos_data in pairs(self.path_data) do
							--print(dump(pos_data))
							minetest.add_particle({
								pos = pos_data,
								velocity = {x=0, y=0, z=0},
								acceleration = {x=0, y=0, z=0},
								expirationtime = 1,
								size = 1,
								texture = "dirt.png",
							})
						end
					end
					]]--
				end
			elseif not self.following then
				self.path_data = nil
			end


			--this is the real time one
			local selfpos = self.object:get_pos()
			local pos1 = vector.new(selfpos.x,0,selfpos.z)

			if (self.path_data and table.getn(self.path_data) > 0 and vector.distance(self.object:get_pos(),self.path_data[1]) > 2) or self.swimming == true then
				self.path_data = nil
			end

			if self.path_data and table.getn(self.path_data) > 0 and vector.distance(pos1,vector.new(self.path_data[1].x,0,self.path_data[1].z)) < 1 then
				--shift whole list down
				for i = 2,table.getn(self.path_data) do
					self.path_data[i-1] = self.path_data[i]
				end
				self.path_data[table.getn(self.path_data)] = nil
			end
		end
	end
	
	return(mob_register)
end

