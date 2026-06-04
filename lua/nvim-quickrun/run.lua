--[[
```sh
:Run name
    "Selects and runs the already created command"
:RunAdd
```
]]
local m = {
    select = nil
}
local file = require("nvim-quickrun.file_helpers")
local run_path = require("nvim-quickrun").get_run_path()
local key = require("nvim-quickrun").opts.key

-- returns true if command exists, false otherwise


function m.get_table()
    return file.read(run_path)
end

function m.is_empty()
    return next(setmetatable(m.get_table(), nil)) == nil
end

function m.run_command(name)
    local cmd =m.get_table()[name]
    if cmd then
        vim.cmd(cmd)
        return true
    end
    return false
end

-- opens telescope ui select
function m.menu_list(prompt, callback)
    if m.is_empty() then
        callback(nil)
        return false
    end

    local t = m.get_table()
    t.select = nil; -- Just so select does not pop up as an option
    local key_list = {}
    for name, _ in pairs(t) do
        table.insert(key_list, name)
    end

    table.sort(key_list)
    vim.ui.select(key_list, {
        prompt = prompt,
        format_item = function(item)
            return item
        end,
    }, function(cmd_name)
        if cmd_name then
            callback(cmd_name)
        end
    end)
end

function m.menu_enter(prompt, callback)
    vim.ui.input({ prompt = prompt }, function(out)
        if out then
            callback(out)
        end
    end)
end

function m.create_command(name, command)
    local t = m.get_table()
    t[name] = command
    t:write()
end

function m.setup()
    vim.api.nvim_create_user_command("Run", function(args)
        -- 0 Arguments
        if #args.fargs == 0 then
            local t = m.get_table();
            -- Check if file path exist
            if vim.uv.fs_stat(run_path) == nil then
                -- Create a default runner if no file exist
                -- === Ask to create a .neo file ===
                vim.ui.select({"Create", "Cancel"}, {
                    prompt = prompt,
                }, function(choice)
                    if choice == "Create" then
                        local cmd = "lua vim.notify('Running example command')"
                        local name = "example_command"
                        m.select = name
                        t[name] = cmd
                        t:write()
                        vim.notify(run_path .." Created")
                    end
                end)
                -- ================================

            -- check if select exist
            elseif t[m.select] ~= nil then
                vim.cmd(t[m.select])
                vim.notify("Quickrun: " .. m.select)
            else
                vim.cmd("RunSelect")
            end
        end
    end, { nargs = "*" })


    vim.api.nvim_create_user_command("RunSelect", function(args)

        -- Get currently selected command
        local current_select = "None"
        local t = m.get_table();
        if t[m.select] ~= nil then
            current_select = m.select
        end

        local not_empty = m.menu_list("Current: " .. current_select, function(name)
            if name then
                m.select = name
                vim.cmd(t[name]);
                vim.notify("Quickrun: " .. name)
            end
        end)
        if not_empty == false then
            vim.cmd("Run")
        end
    end, { nargs = "*" })

end

return m

