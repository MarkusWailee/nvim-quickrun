local helper = {}

function helper.read_dir(dir)
	if vim.fn.isdirectory(dir) == 0 then
		return nil
	end
	return vim.fn.readdir(dir)
end

function helper.copy_dir(src, dst)
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
		error("Failed to copy directory: " .. (result.stderr or "unknown error"))
	end
	vim.notify("Copied from directory: "..src, vim.log.levels.INFO, {title = "Quickrun"})
end

function helper.does_file_exist(file_name)
	return vim.uv.fs_stat(file_name) ~= nil
end

function helper.write_file(file_path, src)
	src = src or ""
	local dir = vim.fs.dirname(file_path)
	vim.fn.mkdir(dir, "p")
	local file = io.open(file_path, "w")
	if file then
		file:write(src);
		file:close()
		vim.notify("Created file: "..file_path, vim.log.levels.INFO, {title="Quickrun"})
		return true
	end
	return false
end

local m = {
	selected_cmd = nil
}

local run_path = require("nvim-quickrun").get_run_path()
local template_path = require("nvim-quickrun").get_template_path()



local function get_table()
	if helper.does_file_exist(run_path) then
		return dofile(run_path)
	end
	return nil
end

-- opens telescope ui select

local function run_command_name(cmd_name)
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

	local cmd = get_table()[cmd_name]
	if cmd then
		if run_command(cmd) == false then
			vim.notify(cmd_name .. " = " .. vim.inspect(cmd), vim.log.levels.ERROR,
				{ title = "Quickrun: Invalid Command" })
			return
		end
		vim.notify(cmd_name, vim.log.levels.INFO, { title = "Quickrun: Running Command" })
	else
		vim.cmd("RunSelect")
	end
end

local function run_file_create_menu()
	local function selection_tempate()
		local dir = helper.read_dir(template_path)
		if dir == nil then
			vim.notify("Could not find: ".. template_path, vim.log.levels.ERROR, {title="Quickrun: ERROR"})
			return
		end
		vim.ui.select(dir, {prompt="Choose Template"}, function(choice)
			local s, e = pcall(function()
				helper.copy_dir(template_path..choice.."/.", ".")
			end)
			if e then
				vim.notify(e, vim.log.levels.ERROR, {"Quickrun: ERROR"})
			end
		end)
	end

	local selection =
	{
		"Cancel",
		"Template",
		"New",
	}
	local opts =
	{
		prompt = "Quickrun Create",
	}
	vim.ui.select(selection, opts, function(choice)
		if choice == selection[1] then
		elseif choice == selection[2] then
			selection_tempate()
		elseif choice == selection[3] then
			helper.write_file(run_path, "return\n{\n}")
		end
	end)
end

function m.setup()
	vim.api.nvim_create_user_command("RunCreate", function(args)
		run_file_create_menu()
	end, { nargs = "*" })
	vim.api.nvim_create_user_command("Run", function(args)
		local t = get_table()
		if t then
			if #args.fargs == 0 then
				if m.selected_cmd == nil then
					vim.cmd("RunSelect")
					return
				end
				run_command_name(m.selected_cmd)
			else
				m.selected_cmd = args.fargs[1]
				run_command_name(m.selected_cmd)
			end
		else
			run_file_create_menu()
		end
	end, { nargs = "*" })


	vim.api.nvim_create_user_command("RunSelect", function(args)
		local t = get_table()
		if t then
			local key_list = {}
			for name, _ in pairs(t) do
				table.insert(key_list, 1, name)
			end
			if #key_list == 0 then
				vim.notify('"' .. run_path .. '"' .. " contains an empty {}", vim.log.levels.WARN,
					{ title = "Quickrun: Warning" })
			end
			vim.ui.select(key_list, {
				prompt = "Select command",
			}, function(cmd_name)
				if cmd_name then
					m.selected_cmd = cmd_name
					run_command_name(m.selected_cmd)
				end
			end)
		else
		end
	end, { nargs = "*" })
end

return m
