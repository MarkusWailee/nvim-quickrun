local m = {
	select = nil
}
local run_path = require("nvim-quickrun").get_run_path()

local function does_file_exist(file)
	return vim.uv.fs_stat(run_path) ~= nil
end
local function write_file(file_path, src)
	local dir = vim.fs.dirname(file_path)
	vim.fn.mkdir(dir, "p")
	local file = io.open(file_path, "w")
	if file then
		file:write(src);
		file:close()
		return true
	end
	return false
end

local function get_table()
	if does_file_exist(run_path) then
		return dofile(run_path)
	end
	return nil
end

-- opens telescope ui select

local function run_command(cmd)
	if type(cmd) == "string" then
		vim.cmd(cmd)
		return true
	elseif type(cmd) == "function" then
		cmd()
		return true
	end
	return false
end
local function run_command_name(cmd_name)
	local cmd = get_table()[cmd_name]
	if cmd then
		if run_command(cmd) == false then
			vim.notify(cmd_name.." = ".. vim.inspect(cmd), vim.log.levels.ERROR, { title = "Quickrun: Invalid Command" })
			return
		end
		vim.notify(cmd_name, vim.log.levels.INFO, { title = "Quickrun: Running Command" })
	end
end
local function run_file_create_menu()
	vim.ui.select({ "Create", "Cancel" }, {
		prompt = "Quickrun File"
	}, function(result)
		if result == "Create" then
			if write_file(run_path, "return\n {\n}") == false then
				vim.notify("Failed to create: " .. run_path, vim.log.levels.ERROR, { title = "Quickrun: Error" })
				return
			else
				vim.notify("Created file: " .. run_path, vim.log.levels.INFO, { title = "Quickrun" })
			end
		end
	end)
end


function m.setup()
	vim.api.nvim_create_user_command("Run", function(args)
		-- 0 Arguments
		local t = get_table()
		if t then
			if m.select == nil then
				vim.cmd("RunSelect")
				return
			end
			run_command_name(m.select)
		else
			run_file_create_menu()
		end
	end, { nargs = "*" })


	vim.api.nvim_create_user_command("RunSelect", function(args)
		local t = get_table()
		if t then
			local key_list = {}
			for name, _ in pairs(t) do
				table.insert(key_list,1, name)
			end
			if #key_list == 0 then
				vim.notify('"'..run_path..'"'.." contains an empty {}", vim.log.levels.WARN, { title = "Quickrun: Warning" })
			end
			vim.ui.select(key_list, {
				prompt = "Select command",
			}, function(cmd_name)
				if cmd_name then
					m.select = cmd_name
					run_command_name(m.select)
				end
			end)
		else
			run_file_create_menu()
		end
	end, { nargs = "*" })
end

return m
