function ColorMYVim(color)
    vim.cmd('set background=dark')
    -- color = color or "tokyonight-night"
     --color = color or "rose-pine"
     --color = color or "solarized-osaka-night"
     --color = color or "atlas"
     color = color or "monochrome"
    vim.cmd.colorscheme(color)



    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end


ColorMYVim()
