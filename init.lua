local exports = {}
exports.name = "memory_card_inserter"
exports.version = "0.0.2"
exports.description = "Automatically insert Neo Geo memory card"
exports.license = "MIT"
exports.author = { name = "Megan Leet (Zowayix)" }

local memory_card_inserter = exports

function memory_card_inserter.startplugin()
	local function get_config_path()
		return emu.subst_env(manager.machine.options.entries.homepath:value():match('([^;]+)')) .. '/memory_card_inserter.ini'
	end

	local function get_memory_card_dir()
		local config_path = get_config_path()
		local file = io.open(config_path, 'r')
		if file then
			file:close()
			for line in io.lines(config_path) do
				key, value = string.match(line, '([%w_]+)%s*=%s*(.+)');
				if key == 'memory_card_path' then
					return value
				end
			end
			return nil
		else
			return nil
		end
	end

	local function insert_card(machine, path)
		emu.print_verbose('memory-card-inserter: card path = ' .. path)

		for name, image in pairs(machine.images) do
			if name == ':memcard' or name == 'memcard' then
				if image.exists then
					--We don't want to mess around with this if someone's already inserted a memory card
					emu.print_verbose('memory-card-inserter: Memory card is already inserted')
					return
				end
				if not lfs.attributes(path) then
					--Only create the file if it does not already exists, otherwise it would overwrite what is already there
					emu.print_verbose('memory-card-inserter: Creating new memory card file')
					image:create(path)
				end
				image:load(path)
			end
		end

	end

	local function get_software_familyname(machine, slot_name)
		image = machine.images[slot_name]
		if image == nil then
			return nil
		end
		if not image.exists then
			return nil
		end
		if image.software_list_name == '' then
			return nil
		end

		if image.software_parent == '' then
			return image.filename
		else
			return image.software_parent
		end
	end


	local function auto_insert()
		local machine = manager.machine
		local driver = machine.system
		if driver.source_file:sub(-#'neogeo.cpp') ~= 'neogeo.cpp' then
			return
		end

		local memcard_name = nil
		if driver.name == 'neogeo' or driver.name == 'aes' then
			local softname = get_software_familyname(machine, ':cslot')
			if softname == nil then
				softname = get_software_familyname(machine, ':cslot1')
			end
			if softname == nil then
				return
			end
			memcard_name = softname
		else
			if driver.parent == 'neogeo' or driver.parent == '0' then
				memcard_name = driver.name
			else
				memcard_name = driver.parent
			end
		end

		local base_path = get_memory_card_dir()
		if base_path == nil then
			return
		end
		local path = base_path .. '/' .. memcard_name .. '.neo'

		insert_card(machine, path)
	end

	emu.register_start(auto_insert)
end

return exports