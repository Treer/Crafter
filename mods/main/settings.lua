local settings = minetest.settings

--local old = settings:get("dedicated_server_step")

settings:set("dedicated_server_step", 0.00001)
settings:set("liquid_update", 0.25)
settings:set("abm_interval", 0.01)
settings:set("enable_minimap", "true")
settings:set("show_entity_selectionbox", "false")

local creative_mode = minetest.settings:get_bool("creative_mode")

--make stack max 1000 for everything
minetest.register_on_mods_loaded(function()
	for name,def in pairs(minetest.registered_nodes) do
		if creative_mode == true then
			local groups = def.groups
			groups["dig_immediate"] = 3
		end
		minetest.override_item(name, {
			stack_max = 1000,
		})
	end
	for name,_ in pairs(minetest.registered_craftitems) do
		minetest.override_item(name, {
			stack_max = 1000,
		})
	end
end)

--minetest.register_globalstep(function(dtime)
--	print(settings:get("dedicated_server_step"))
--end)
