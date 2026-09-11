vim.g.mapleader = " "

local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true

opt.termguicolors = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.showmode = false
opt.scrolloff = 8

opt.wrap = false
opt.mouse = "a"
opt.clipboard = "unnamedplus"

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = false

opt.splitright = true
opt.splitbelow = true

opt.swapfile = false
opt.undofile = true

opt.updatetime = 250
opt.timeoutlen = 500

local map = vim.keymap.set

map("n", "<leader>w", "<cmd>w<cr>")
map("n", "<leader>q", "<cmd>q<cr>")
map("n", "<leader>x", "<cmd>x<cr>")
map("n", "<leader>e", "<cmd>Ex<cr>")

map("n", "<Esc>", "<cmd>nohlsearch<cr>")

map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

map("v", "<", "<gv")
map("v", ">", ">gv")

map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

map("n", "<leader>s", ":%s/")

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank()
    end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function()
        local view = vim.fn.winsaveview()
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.winrestview(view)
    end,
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end

opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            local telescope = require("telescope.builtin")

            map("n", "<leader>ff", telescope.find_files)
            map("n", "<leader>fg", telescope.live_grep)
            map("n", "<leader>fb", telescope.buffers)
            map("n", "<leader>fh", telescope.help_tags)
        end,
    },

    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        opts = {
            indent = {
                char = "│",
            },
            scope = {
                enabled = true,
            },
        },
    },
})

