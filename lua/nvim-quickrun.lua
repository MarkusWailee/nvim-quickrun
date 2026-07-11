local m =
{
    opts =
    {
        enabled = true,
        run_path = ".neo/run.lua",
		template_path = "quickrun-templates/"
    }
}

m.get_run_path = function()
    return m.opts.run_path
end

m.get_template_path = function()
    return vim.fn.stdpath("config").."/"..m.opts.template_path
end

m.setup = function(opts)
    m.opts = vim.tbl_deep_extend("force", m.opts, opts or {})

	if m.opts.template_path[1] ~= "/" then
		m.opts.template_path = m.opts.template_path .."/"
	end

    if m.opts.enabled then
        require("nvim-quickrun.run").setup()
    end

end -- End of setup

return m
