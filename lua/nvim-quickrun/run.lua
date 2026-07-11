local file_helpers = {}
---@param src string
---@param dst string
function file_helpers.copy_dir(src, dst)
	local cmd
	if vim.fn.has("win32") == 1 then
		cmd = { "xcopy", src, dst, "/E", "/I", "/Y" }
		--cmd = { "robocopy", src, dst, "/E", "/XC", "/XN", "/XO" }
	else
		cmd = { "cp", "-r", src, dst }
		-- cmd = { "cp", "-rn", src, dst }
	end
	local result = vim.system(cmd):wait()
	if result.code ~= 0 then
		vim.notify("Failed to copy directory: " .. (result.stderr or "unknown error"), vim.log.levels.ERROR, {title="Quickrun: ERROR"})
		return false
	else
		vim.notify("Copied from directory: " .. src, vim.log.levels.INFO, { title = "Quickrun" })
		return true
	end
end

---@param filepath string
---@param src string
function file_helpers.write_file(filepath, src)
	src = src or ""
	local dir = vim.fs.dirname(filepath)
	vim.fn.mkdir(dir, "p")
	local file = io.open(filepath, "w")
	if file then
		file:write(src);
		file:close()
		vim.notify(filepath, vim.log.levels.INFO, { title = "CMake: Created File" })
	else
		error("Failed to write file: " .. filepath, 0)
	end
end

---@param dir string
function file_helpers.read_dir(dir)
	if vim.fn.isdirectory(dir) == 0 then
		error("Directory does not exist: " .. dir, 0)
	end

	return vim.fn.readdir(dir)
end

---@param filepath string
function file_helpers.does_file_exist(filepath)
	return vim.uv.fs_stat(filepath) ~= nil
end

---@param filepath string
function file_helpers.dofile(filepath)
	filepath = filepath or ""
	if not file_helpers.does_file_exist(filepath) then
		return nil
	end
	local ok, result = pcall(function()
		return dofile(filepath)
	end)
	if not ok then
		error(result, 0)
	end
	return result
end

-- ==================== Quickrun Helpers ====================
local run_path = require("nvim-quickrun").get_run_path()
local template_path = require("nvim-quickrun").get_template_path()
local function get_table()
	if file_helpers.does_file_exist(run_path) == false then
		vim.cmd("RunCreate")
		return nil
	end

	local ok, t = pcall(function()
		return dofile(run_path)
	end)

	if not ok and t then
		vim.notify(t, vim.log.levels.ERROR, {title="Quickrun: ERROR"})
		return nil
	end

	if type(t) ~= "table" then
		vim.notify(run_path.." must contain a lua table", vim.log.levels.ERROR, {title="Quickrun: ERROR"})
		return nil
	end

	local r = false
	for name, item in pairs(t) do
		if type(item) ~= "function" and type(item) ~= "string" then
			vim.notify(name.." = ".. vim.inspect(item), vim.log.levels.ERROR, {title="Quickrun: ERROR"})
			r = true
		end
	end
	if r then
		return nil
	end


	return t
end

local function run_command(cmd, cmd_name)
		if type(cmd) == "string" then
			local ok, er = pcall(function() vim.cmd(cmd) end)
			if not ok and er then
				vim.notify("Invalid vim command: ".."\""..cmd .."\"", vim.log.levels.ERROR, {title="Quickrun: ERROR"})
			end
		elseif type(cmd) == "function" then
			cmd()
		else
			return
		end
		vim.notify(cmd_name, vim.log.levels.INFO, {title="Quickrun"})

end



-- ==================== Quickrun ====================
local quickrun = {
	selected_cmd = nil
}




function quickrun.setup()
	vim.api.nvim_create_user_command("Run", function(args)
		local t = get_table()
		if t == nil then
			return
		end

		local cmd_name = args.fargs[1]
		if type(cmd_name) == "string" then
			quickrun.selected_cmd = cmd_name
		end

		local cmd = t[quickrun.selected_cmd]
		if cmd == nil then
			vim.cmd("RunSelect")
			return
		end
		run_command(cmd, quickrun.selected_cmd)
	end, { nargs = "*" })

	vim.api.nvim_create_user_command("RunCreate", function(args)
		local function template_menu()

			local ok, dir_list = pcall(function() return file_helpers.read_dir(template_path) end)
			if not ok then
				vim.notify(tostring(dir_list), vim.log.levels.ERROR, {title="Quickrun: ERROR"})
				return
			end
			vim.ui.select(dir_list, {prompt="Choose Template"}, function(choice)
				if choice then
					file_helpers.copy_dir(template_path..choice.."/.", ".")
				end
			end)
		end

		local select = {
			"Cancel",
			"Template",
			"New"
		}
		vim.ui.select(select, {prompt = "Create Quickrun File"}, function(choice)
			if choice == select[1] then

			elseif choice == select[2] then
				template_menu()

			elseif choice == select[3] then
				file_helpers.write_file(run_path, "return\n{\n}")
			end
		end)


	end, { nargs = "*" })


	vim.api.nvim_create_user_command("RunSelect", function(args)
		local t = get_table()
		if t == nil then
			return
		end

		if next(t) == nil then
			vim.notify(run_path.. " empty table {}", vim.log.levels.WARN, {title="Quickrun: WARNING"})
		end

		local keys = {}
		for key, item in pairs(t) do
			table.insert(keys, key)
		end
		vim.ui.select(keys, {}, function(cmd_name)
			if cmd_name then
				quickrun.selected_cmd = cmd_name
				local cmd = t[cmd_name]
				run_command(cmd, cmd_name)
			end
		end)

	end, { nargs = "*" })
end

return quickrun
