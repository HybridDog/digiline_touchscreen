local load_time_start = os.clock()

-- 512x512 px

--http://snipplr.com/view/13086/number-to-hex/
--- Returns HEX representation of num
function num2hex(num)
    local hexstr = '0123456789abcdef'
    local s = ''
    while num > 0 do
        local mod = math.fmod(num, 16)
        s = string.sub(hexstr, mod+1, mod+1) .. s
        num = math.floor(num / 16)
    end
    if s == '' then s = '0' end
    return s
end

local black = {r=0, g=0, b=0}

local function getcolour(colstr)
	if not colstr then
		return black
	end
end

-- converts a rgb table to a hex colour string
local function rgbstring(rgb)
	local t = ""
	for _,f in ipairs({"r", "g", "b"}) do
		f = rgb[f]
		f = math.floor(f+0.5)
		f = math.max(0, math.min(255, f))
		f = num2hex(f)
		if #f == 1 then
			f = "0"..f
		end
		t = t..f
	end
	return t --"#"..t
end

-- makes a table with the colours as indices from a coord table
local function index_colours(data)
	local coltab = {}
	for y = 1,512 do
		local line = data[y]
		if line then
			for x = 1,512 do
				local col = line[x]
				if col then
					col = rgbstring(col)
					coltab[col] = coltab[col] or {}
					table.insert(coltab[col], {x,y})
				end
			end
		end
	end
	return coltab
end

-- returns the texture with its modifiers for the screen
local function make_texture(data)
	-- set the base image
	local tex,n = {"digiline_touchscreen_bg.png"},2

	-- add the px and "colorize" them
	for col,ps in pairs(index_colours(data)) do
		-- add a chunk of px
		tex[n] = "^([combine:WxH"
		n = n+1
		for _,coord in pairs(ps) do
			local x,y = unpack(coord)
			tex[n] = ":"..x..","..y.."=digiline_touchscreen_px.png"
			n = n+1
		end

		-- colorize them
		tex[n] = "^[colorize:#"..col..")"
		n = n+1
	end

	-- return a string
	return table.concat(tex, "")
end

-- the node the object should be attached to
minetest.register_node("digiline_touchscreen:touchscreen", {
	description = "digiline controlled touchscreen",
	drawtype = "nodebox",
	tiles = "digiline_touchscreen.png",
	paramtype = "light",
	--paramtype2 = "facedir",
	is_ground_content = false,
	groups = {cracky=3, oddly_breakable_by_hand=2},
	sounds = default.node_sound_stone_defaults(),
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -7/16, 0.5},
		},
	},
	on_construct = function(pos)
	end,
	on_destruct = function(pos)
	end,
})

-- the screen
minetest.register_entity("digiline_touchscreen:entity", {
	collisionbox = {0,0,0, 0,0,0},
	physical=false,
	visual = "upright_sprite",
	textures = {"digiline_touchscreen_bg.png"},
	on_activate = function(self, staticdata)
		local pos = vector.round(self.object:getpos())
		local meta = minetest.get_meta(pos)
		local data = meta:get_string("data")
		data = data_to_tab(data)
		local pic = make_texture(data)
		self.object:set_properties({textures={pic}})
	end,
})


local time = math.floor(tonumber(os.clock()-load_time_start)*100+0.5)/100
local msg = "[digiline_touchscreen] loaded after ca. "..time
if time > 0.05 then
	print(msg)
else
	minetest.log("info", msg)
end
