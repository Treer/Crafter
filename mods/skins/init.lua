local path = minetest.get_modpath(minetest.get_current_modname())

-- path for the temporary skins file
local temppath = minetest.get_worldpath() .. "/skins_temp.png"

local pngimage = dofile(path.."/png_lua/png.lua")

--run through all the skins on the skindex and index them all locally
--only try to index further than the point in the current list max

local http = minetest.request_http_api()
local id = "Lua Skins Updater"
-- Binary downloads are required
if not core.features.httpfetch_binary_data then
	print("outdated version of MINETEST detected!")
    return(nil)
end

if not http then
    for i = 1,5 do
        print("!WARNING!")
    end
    print("---------------------------------------------------------------")
    print("HTTP access is required. Please add this to your minetest.conf:")
    print("secure.http_mods = skins")
    print("!!Skins will not work without this!!")
    print("---------------------------------------------------------------")
    return(nil)
end

-- Fancy debug wrapper to download an URL
local function fetch_url(url, callback)
	http.fetch({
        url = url,
        timeout = 3,
    }, function(result)
        --print(dump(result))
        if result.succeeded then
            
			--if result.code ~= 200 then
				--core.log("warning", ("%s: STATUS=%i URL=%s"):format(
				--	_ID_, result.code, url))
			--end
			return callback(result.data)
		end
		core.log("warning", ("%s: Failed to download URL=%s"):format(
			id, url))
	end)
end

--https://gist.github.com/marceloCodget/3862929 rgb to hex

local function rgbToHex(rgb)

	local hexadecimal = ""

	for key, value in pairs(rgb) do
		local hex = ''

		while(value > 0)do
			local index = math.fmod(value, 16) + 1
			value = math.floor(value / 16)
			hex = string.sub('0123456789ABCDEF', index, index) .. hex			
		end

		if(string.len(hex) == 0)then
			hex = '00'

		elseif(string.len(hex) == 1)then
			hex = '0' .. hex
		end

		hexadecimal = hexadecimal .. hex
	end

	return hexadecimal
end

local xmax = 64
local ymax = 32
local function file_to_texture(image)
    local x = 1
    local y = 1
    --local base_texture = "[combine:"..xmax.."x"..ymax
    local base_texture = "[combine:" .. xmax .. "x" .. ymax
    --local base_texture2 = "[combine:"..xmax.."x"..ymax
    for _,line in pairs(image.pixels) do
        for _,data in pairs(line) do
            if x <= 32 or y > 16 then
                local hex = rgbToHex({data.R,data.G,data.B})
                --skip transparent pixels
                if data.A > 0 then 
                    --https://github.com/GreenXenith/skinmaker/blob/master/init.lua#L57 Thanks :D

                    base_texture = base_texture .. (":%s,%s=%s"):format(x - 1, y - 1, "(p.png\\^[colorize\\:#" .. hex .. ")")
                end
            --else
            --    print(dump(data))
            end
            x = x + 1
            if x > xmax then
                x = 1
                y = y + 1
            end
            if y > ymax then
                break
            end
        end
    end
    return(base_texture)
end

-- Function to fetch a range of pages
fetch_function = function(name)
    fetch_url("https://raw.githubusercontent.com/"..name.."/crafter_skindex/master/skin.png", function(data)
        if data then
            local f = io.open(temppath, "wb")
            f:write(data)
            f:close()

            local img = pngimage(temppath, nil, false, false)
            if img then
                local stored_texture = file_to_texture(img)

                --print("===============================================================")
                --print(stored_texture)
                if stored_texture then
                    --set the player's skin
                    local player = minetest.get_player_by_name(name)
                    player:set_properties({textures = {stored_texture, "blank_skin.png"}})
                    local meta = player:get_meta()
                    meta:set_string("skin",stored_texture)

                    recalculate_armor(player) --redundancy
                    
                    --[[
                    player:hud_add(
                        {
                            hud_elem_type = "image",  -- See HUD element types
                            -- Type of element, can be "image", "text", "statbar", or "inventory"
                    
                            position = {x=0.5, y=0.5},
                            -- Left corner position of element
                    
                            name = "<name>",
                    
                            scale = {x = 2, y = 2},
                    
                            text = stored_texture,
                    
                            text2 = "<text>",
                    
                            number = 2,
                    
                            item = 3,
                            -- Selected item in inventory. 0 for no item selected.
                    
                            direction = 0,
                            -- Direction: 0: left-right, 1: right-left, 2: top-bottom, 3: bottom-top
                    
                            alignment = {x=0, y=0},
                    
                            offset = {x=0, y=0},
                    
                            size = { x=100, y=100 },
                            -- Size of element in pixels
                    
                            z_index = 0,
                            -- Z index : lower z-index HUDs are displayed behind higher z-index HUDs
                        }
                    )
                    ]]--
                end
            end

        end
    end)
end

--local img = pngimage(minetest.get_modpath("skins").."/skin_temp/temp.png", nil, false, false)
--print(dump(img))

minetest.register_on_joinplayer(function(player)
    local meta = player:get_meta()
    meta:set_string("skin","player.png")
    minetest.after(0,function()
        fetch_function(player:get_player_name())
    end)
end)
