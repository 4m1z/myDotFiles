local omarchy_ok, omarchy = pcall(require, 'omarchy')

local function base_scheme()
    -- On Omarchy, follow the system-wide theme; elsewhere keep the old default.
    if omarchy_ok then
        local preferred = omarchy.preferred_scheme()
        if preferred ~= nil and preferred ~= "" then
            return preferred
        end
    end
    return "monochrome"
end

function ColorMYVim(color)
    color = color or base_scheme()

    -- The intended scheme may not be installed (e.g. system theme is gruvbox
    -- but only aether/solarized/monochrome are). Walk the fallbacks instead
    -- of erroring out.
    local applied = color
    if not pcall(vim.cmd.colorscheme, color) then
        applied = nil
        if omarchy_ok then
            local candidates = { color }
            for _, fallback in ipairs(omarchy.fallbacks()) do
                table.insert(candidates, fallback)
            end
            applied = omarchy.try_schemes(candidates)
        else
            pcall(vim.cmd.colorscheme, "monochrome")
            applied = "monochrome"
        end
    end
    vim.g.active_colorscheme = applied or color

    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { bg = "none" })
    vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { bg = "none" })
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })

    -- Paint the Omarchy palette (terminal colors, fg, selection) on top.
    if omarchy_ok then
        omarchy.apply_palette()
        vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    end
end


ColorMYVim()

-- Keep the palette on top if something changes the scheme later.
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        if omarchy_ok then
            omarchy.apply_palette()
            vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
        end
    end,
})

-- Re-read Omarchy state (after `omarchy theme set`) without restarting.
vim.api.nvim_create_user_command("OmarchyTheme", function()
    if omarchy_ok then
        omarchy.reload()
    end
    ColorMYVim()
    local name = vim.g.omarchy_theme_name or vim.g.active_colorscheme
    print("Theme synced: " .. tostring(name))
end, {})
