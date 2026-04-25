function ColorMYVim(color)
    vim.cmd('set background=dark')
    --color = color or "monochrome"
    color = color or "solarized-osaka"
    vim.cmd.colorscheme(color)

    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end


ColorMYVim()
