-- colored_blocks / mcl_cblocks: Colored Blocks for Minetest/Mineclonia
-- ==============================
-- COLOR LIST
-- ==============================
local colors = {
	-- {name="white", desc="White", hex="#abababc0", dye="white"},
	{name="orange", desc="Orange", hex="#F9801D", dye="orange"},
	{name="magenta", desc="Magenta", hex="#C74EBD", dye="magenta"},
	{name="light_blue", desc="Light Blue", hex="#3AB3DA", dye="light_blue"},
	{name="yellow", desc="Yellow", hex="#FED83D", dye="yellow"},
	{name="lime", desc="Lime", hex="#80C71F", dye="lime"},
	{name="pink", desc="Pink", hex="#F38BAA", dye="pink"},
	{name="gray", desc="Gray", hex="#474F52", dye="gray"},
	{name="silver", desc="Silver", hex="#9D9D97", dye="silver"},
	{name="cyan", desc="Cyan", hex="#169C9C", dye="cyan"},
	{name="purple", desc="Purple", hex="#8932B8", dye="purple"},
	{name="blue", desc="Blue", hex="#3C44AA", dye="blue"},
	{name="brown", desc="Brown", hex="#835432", dye="brown"},
	{name="green", desc="Green", hex="#5E7C16", dye="green"},
	{name="red", desc="Red", hex="#B02E26", dye="red"},
	{name="black", desc="Black", hex="#1D1D21", dye="black"},
}

-- ==============================
-- MOD AND ENVIRONMENT CHECK
-- ==============================
local has_mcl_core = minetest.get_modpath("mcl_core")
local has_stairs = minetest.get_modpath("stairs")
local has_mcl_stairs = minetest.get_modpath("mcl_stairs")
local has_moreblocks = minetest.get_modpath("moreblocks")
local has_mcl_moreblocks = minetest.get_modpath("mcl_moreblocks")

-- Define dynamic prefix to avoid migration issues
local mod_prefix = has_mcl_core and "mcl_cblocks" or "colored_blocks"
local dye_prefix = has_mcl_core and "mcl_dyes" or "dyes"

-- ==============================
-- BASE NODE LIST
-- ==============================
local base_nodes = {}
if has_mcl_core then
	-- Original Mineclonia nodes for compatibility
	base_nodes = {
		"mcl_core:stonebrick",
		"mcl_trees:wood_oak",
		"mcl_core:cobble",
		"mcl_core:stone",
		"mcl_trees:bark_stripped_oak",
		"mcl_trees:bark_stripped_dark_oak",
		"mcl_trees:bark_stripped_jungle",
		"mcl_trees:bark_stripped_spruce",
		"mcl_trees:bark_stripped_acacia",
		"mcl_trees:bark_stripped_birch",
		"mcl_core:brick_block",
	}
else
	-- Default Minetest Game nodes
	base_nodes = {
		"default:stonebrick",
		"default:wood",
		"default:cobble",
		"default:stone",
		"default:brick",
	}
end

-- ==============================
-- MAIN FUNCTION
-- ==============================
local function register_colored_block(base_node)
	local base_def = minetest.registered_nodes[base_node]
	if not base_def then
		minetest.log("warning", "[" .. mod_prefix .. "] Base node not found: " .. base_node)
		return
	end

	local id = base_node:match(":(.+)")
	local base_desc = base_def.description or id

	for _, color in ipairs(colors) do
		local node_id = id .. "_" .. color.name
		local node_name = mod_prefix .. ":" .. node_id
		local def = table.copy(base_def)

		def.groups = table.copy(base_def.groups or {})
		def.groups.colored_block = 1
		def.description = color.desc .. " " .. base_desc

		-- Texture solution using 'color'
		local new_tiles = {}
		local base_tiles = base_def.tiles or base_def.tile_images
		
		if type(base_tiles) == "table" then
			for _, tile in ipairs(base_tiles) do
				local tile_name = (type(tile) == "table") and tile.name or tile
				table.insert(new_tiles, {
					name = tile_name,
					color = color.hex,
				})
			end
		else
			table.insert(new_tiles, {
				name = base_tiles,
				color = color.hex,
			})
		end
		
		def.tiles = new_tiles
		def.tile_images = nil

		minetest.register_node(":" .. node_name, def)

		-- =================================================================
		-- STAIRS / SLABS INTEGRATION
		-- =================================================================
		if has_mcl_stairs and mcl_stairs.register_stair_and_slab then
			-- Mineclonia API (keeps original naming style)
			mcl_stairs.register_stair_and_slab(
				node_id,
				node_name,
				def.groups,
				def.tiles,
				color.desc .. " " .. base_desc .. " Stair",
				color.desc .. " " .. base_desc .. " Slab",
				def.sounds
			)
		elseif has_stairs and stairs.register_stair_and_slab then
			-- Minetest Game API
			stairs.register_stair_and_slab(
				node_id,
				node_name,
				def.groups,
				def.tiles,
				color.desc .. " " .. base_desc .. " Stair",
				color.desc .. " " .. base_desc .. " Slab",
				def.sounds
			)
		end

		-- =================================================================
		-- MOREBLOCKS INTEGRATION
		-- =================================================================
		if has_mcl_moreblocks and mcl_moreblocks.add_block then
			-- Mineclonia extra shapes system
			mcl_moreblocks.add_block(node_name)
		elseif has_moreblocks and moreblocks.stairsplus and moreblocks.stairsplus.register_all then
			-- Minetest Game stairsplus system
			moreblocks.stairsplus.register_all(
				mod_prefix,
				node_id,
				node_name,
				{
					description = def.description,
					drop = node_name,
					groups = def.groups,
					sounds = def.sounds,
					tiles = def.tiles
				}
			)
		end

		-- Shapeless crafting recipe
		minetest.register_craft({
			type = "shapeless",
			output = node_name .. " 1",
			recipe = {
				dye_prefix .. ":" .. color.dye, base_node,
			}
		})
	end
end

-- ==============================
-- LOOP TO REGISTER EVERYTHING
-- ==============================
for _, node in ipairs(base_nodes) do
	register_colored_block(node)
end

minetest.log("action", "[" .. mod_prefix .. "] Colored blocks loaded with prefix " .. mod_prefix)
