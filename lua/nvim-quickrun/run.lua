--[[
```sh
:Run name
    "Selects and runs the already created command"
:RunAdd
```
]]
local m = {}
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
    t.select = nil;
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
            if vim.uv.fs_stat(run_path) == nil then

                -- === Ask to create a .neo file ===
                vim.ui.select({"Create", "Cancel"}, {
                    prompt = prompt,
                }, function(choice)
                    if choice == "Create" then
                        local cmd = "lua vim.notify('Running example command')"
                        local name = "example_command"
                        t.select = name
                        t[name] = cmd
                        t:write()
                        vim.notify(run_path .." Created")
                    end
                end)
                -- ================================

            elseif t.select then
                m.run_command(t.select)
            else
                vim.cmd("RunSelect")
            end
        end
    end, { nargs = "*" })


    vim.api.nvim_create_user_command("RunSelect", function(args)

        local not_empty = m.menu_list("Choose Command", function(name)
            local t = m.get_table();
            if name then
                t.select = name
                vim.cmd(t[name]);
                t:write();
            end
        end)
        if not_empty == false then
            vim.cmd("Run")
        end
    end, { nargs = "*" })

end

return m

