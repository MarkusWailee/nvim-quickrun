local m =
{
    opts =
    {
        enabled = true,
        path = ".neo/run.lua",
    }
}

m.get_run_path = function()
    return m.opts.path
end

m.setup = function(opts)
    m.opts = vim.tbl_deep_extend("force", m.opts, opts or {})

    if m.opts.enabled then
        require("nvim-quickrun.run").setup()
    end

end -- End of setup

return m
