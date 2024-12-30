local _,o = pcall(require, "outline")


o.setup{}


vim.keymap.set("n", "<leader>o", "<cmd>aboveleft OutlineOpen<CR>")
