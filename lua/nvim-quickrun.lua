local m =
{
    opts =
    {
        enabled = true,
        file = ".neo/run.lua",
		template_path = "quickrun-templates/" -- relative to nvim config
    }
}

m.get_run_path = function()
    return m.opts.file
end

m.get_template_path = function()
    return vim.fn.stdpath("config").."/"..m.opts.template_path
end

function m.get_path()
	return vim.fs.dirname(m.opts.file) .."/"
end

m.setup = function(opts)
    m.opts = vim.tbl_deep_extend("force", m.opts, opts or {})

    if m.opts.enabled then
        require("nvim-quickrun.run").setup()
    end

end -- End of setup

return m
