--[[
Minimal Neovim dev environment.
Managed by lazy.nvim (see https://lazy.folke.io).

Features merged from AJANI2005/Neovim-Minimal; where that config hand-writes
something a plugin does better, the plugin wins (telescope over fzf,
toggleterm over hand-rolled terminals, conform over vim.lsp.buf.format, the
neocodeium plugin, netrw tweaks, VS Code integration).

Key architectural choices:
- lazy.nvim plugin manager.
- Native `vim.lsp.config()` / `vim.lsp.enable()` (nvim-lspconfig's
`require('lspconfig')` framework is deprecated).
- Native treesitter built into Neovim 0.12 (no plugin).
- Servers are installed by the container (apk/npm), so no Mason needed.
]]
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = false

-- [[ Editor options ]]
vim.o.number = true
vim.o.relativenumber = true
vim.o.showmode = false
vim.o.mouse = "a"
vim.o.termguicolors = true
vim.o.signcolumn = "yes"
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.confirm = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true
vim.o.hlsearch = false
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.wrap = false
vim.o.wildmenu = true
vim.o.wildmode = "longest:full,full"
vim.o.completeopt = "menu,menuone,noselect,popup"
vim.o.pumheight = 12
vim.opt.isfname:append("@-@")

vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- [[ Keymaps ]]
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>e", "<cmd>Ex<CR>", { desc = "File Explorer" })
vim.keymap.set("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>close<CR>", { desc = "Close window" })
vim.keymap.set("n", "<leader>so", "<cmd>source %<CR>", { desc = "Source current file" })
vim.keymap.set("n", "<leader>x", function()
	vim.diagnostic.setqflist()
	vim.lsp.buf.workspace_diagnostics()
	vim.cmd("copen")
end, { desc = "Diagnostics in quickfix" })

vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })

vim.keymap.set("n", "Q", "<nop>") -- disable Ex mode
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join line" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half-page down, centered" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half-page up, centered" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Search next, centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Search previous, centered" })
vim.keymap.set("n", "<leader>sv", "<C-w>v<C-w>l", { desc = "Split vertically" })
vim.keymap.set("n", "<leader>sh", "<C-w>s<C-w>j", { desc = "Split horizontally" })
vim.keymap.set(
	"n",
	"<leader>sw",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Substitute word under cursor" }
)

vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without overwriting register" })
vim.keymap.set(
	"v",
	"<leader>sw",
	[["hy:%s/\V<C-r>h/<C-r>h/gI<Left><Left><Left>]],
	{ desc = "Substitute selected text" }
)

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- [[ Diagnostics config ]]
vim.diagnostic.config({
	virtual_text = { prefix = "●" },
	signs = true,
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = { min = vim.diagnostic.severity.WARN } },
})

-- Replace the default diagnostic gutter signs with cleaner icons.
local signs = {
	Error = " ",
	Warn = " ",
	Hint = "󰠠 ",
	Info = " ",
}
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- [[ Autocommands ]]
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	desc = "Restore cursor to last edited line",
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(args.buf)
		if mark[1] > 0 and mark[1] <= line_count then
			vim.api.nvim_win_set_cursor(0, mark)
			vim.schedule(function()
				vim.cmd("normal! zz")
			end)
		end
	end,
})

-- [[ File explorer (netrw) ]]
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 25
vim.g.netrw_altv = 1
vim.g.netrw_keepdir = 1

local netrw_line
vim.api.nvim_create_autocmd("BufLeave", {
	callback = function(args)
		if vim.bo[args.buf].filetype == "netrw" then
			netrw_line = vim.fn.line(".")
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	callback = function(args)
		vim.schedule(function()
			if vim.bo[args.buf].filetype == "netrw" and netrw_line then
				vim.api.nvim_win_set_cursor(0, { netrw_line, 0 })
				netrw_line = nil
			end
		end)
		local opts = { buffer = args.buf }
		vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
		vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
		vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
		vim.keymap.set("n", "<C-l>", "<C-w>l", opts)
	end,
})

-- Terminal-mode window navigation and close.
vim.api.nvim_create_autocmd("TermOpen", {
	callback = function(args)
		local opts = { buffer = args.buf }
		vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>hi", opts)
		vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>ji", opts)
		vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>ki", opts)
		vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>li", opts)
		vim.keymap.set("t", "<A-Esc>", "<C-\\><C-n><cmd>close<CR>", { buffer = args.buf, desc = "Close terminal" })
	end,
})

-- Open the current file in VS Code at the cursor line/column.
vim.keymap.set("n", "<leader>vc", function()
	local file = vim.fn.expand("%:p")
	local cwd = vim.fn.getcwd()
	if vim.fn.has("wsl") == 1 then
		file = vim.fn.system({ "wslpath", "-w", file }):gsub("%s+$", "")
		cwd = vim.fn.system({ "wslpath", "-w", cwd }):gsub("%s+$", "")
	end
	local line = vim.fn.line(".")
	local col = vim.fn.col(".") - 1
	vim.fn.jobstart({ "code", "--reuse-window", cwd, "--goto", string.format("%s:%d:%d", file, line, col) }, {
		detach = true,
	})
end, { desc = "Open in VS Code" })

-- [[ Bootstrap lazy.nvim ]]
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- [[ Plugins ]]
require("lazy").setup({
	spec = {
		-- Colorscheme
		{
			"folke/tokyonight.nvim",
			lazy = false,
			priority = 1000,
			config = function()
				require("tokyonight").setup({
					styles = { comments = { italic = false } },
				})
				vim.cmd.colorscheme("tokyonight-night")
			end,
		},

		-- UI / core
		{
			"NMAC427/guess-indent.nvim",
			config = function()
				require("guess-indent").setup({})
			end,
		},
		{
			"lewis6991/gitsigns.nvim",
			event = { "BufReadPre", "BufNewFile" },
			config = function()
				require("gitsigns").setup({})
			end,
		},
		{
			"folke/which-key.nvim",
			event = "VeryLazy",
			config = function()
				require("which-key").setup({
					delay = 0,
					icons = { mappings = vim.g.have_nerd_font },
					spec = {
						{ "<leader>f", group = "[F]ind", mode = { "n", "v" } },
						{ "g", group = "Goto" },
					},
				})
			end,
		},
		{
			"nvim-mini/mini.nvim",
			lazy = false,
			config = function()
				require("mini.icons").setup()
				require("mini.pairs").setup()
				require("mini.ai").setup({
					mappings = {
						around_next = "aa",
						inside_next = "ii",
					},
					n_lines = 500,
				})
				require("mini.surround").setup()
				local statusline = require("mini.statusline")
				statusline.setup({ use_icons = vim.g.have_nerd_font })
				statusline.section_location = function()
					return "%2l:%-2v"
				end
			end,
		},

		-- Terminal (replaces Neovim-Minimal's hand-rolled split/float terms).
		{
			"akinsho/toggleterm.nvim",
			keys = {
				{
					"<A-Enter>",
					"<cmd>ToggleTerm direction=horizontal size=10<CR>",
					mode = { "n", "t" },
					desc = "Horizontal terminal",
				},
				{
					"<A-S-Enter>",
					"<cmd>ToggleTerm direction=float<CR>",
					mode = { "n", "t" },
					desc = "Floating terminal",
				},
			},
			config = function()
				require("toggleterm").setup({ size = 10, float = { border = "rounded" } })
				if vim.fn.executable("lazygit") == 1 then
					vim.keymap.set(
						"n",
						"<leader>lg",
						"<cmd>TermExec cmd=lazygit direction=float<CR>",
						{ desc = "Lazygit" }
					)
				end
			end,
		},

		-- AI tab completion (from Neovim-Minimal's plugins.lua).
		{
			"monkoose/neocodeium",
			event = "InsertEnter",
			config = function()
				local neoc = require("neocodeium")
				neoc.setup({
					-- Hide suggestions while the blink.cmp menu is open.
					filter = function()
						return not require("blink.cmp").is_visible()
					end,
				})
				local map = function(lhs, rhs)
					vim.keymap.set("i", lhs, rhs)
				end
				map("<A-f>", function()
					neoc.accept()
				end)
				map("<A-w>", function()
					neoc.accept_word()
				end)
				map("<A-a>", function()
					neoc.accept_line()
				end)
				map("<A-e>", function()
					neoc.cycle_or_complete()
				end)
				map("<A-r>", function()
					neoc.cycle_or_complete(-1)
				end)
				map("<A-c>", function()
					neoc.clear()
				end)
			end,
		},

		-- Fuzzy finder
		{
			"nvim-telescope/telescope.nvim",
			dependencies = {
				"nvim-lua/plenary.nvim",
				"nvim-telescope/telescope-ui-select.nvim",
			},
			cmd = "Telescope",
			config = function()
				-- Send live grep's current matches to the quickfix list and open
				-- it, so results can be browsed and copied.
				local function send_to_qflist(prompt_bufnr)
					local actions = require("telescope.actions")
					local action_state = require("telescope.actions.state")
					actions.send_to_qflist(prompt_bufnr)
					local picker = action_state.get_current_picker(prompt_bufnr)
					if picker then
						picker:close()
					end
					vim.cmd("copen")
				end

				require("telescope").setup({
					pickers = {
						live_grep = {
							mappings = {
								-- <c-f> in a live grep picker re-searches the
								-- current matches (fuzzy refine) instead of the
								-- whole project.
								-- <c-q> sends the current matches to the quickfix
								-- list and opens it.
								i = {
									["<c-f>"] = require("telescope.actions").to_fuzzy_refine,
									["<c-q>"] = send_to_qflist,
								},
								n = {
									["<c-f>"] = require("telescope.actions").to_fuzzy_refine,
									["<c-q>"] = send_to_qflist,
								},
							},
						},
					},
					extensions = {
						["ui-select"] = { require("telescope.themes").get_dropdown() },
					},
				})
				pcall(require("telescope").load_extension, "ui-select")

				local builtin = require("telescope.builtin")
				vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
				vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "[F]ind by [G]rep" })
				vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "[F]ind [H]elp" })
				vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "[F]ind [K]eymaps" })
				vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "[F]ind [D]iagnostics" })
				vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
			end,
		},

		-- LSP
		{
			"neovim/nvim-lspconfig",
			lazy = false,
			config = function()
				vim.api.nvim_create_autocmd("LspAttach", {
					group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
					callback = function(event)
						local map = function(keys, func, desc, mode)
							mode = mode or "n"
							vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
						end

						map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
						map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
						map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
						map("K", vim.lsp.buf.hover, "Hover")

						-- Standard LSP plumbing (see codingbrush.com LSP guide).
						map("gd", vim.lsp.buf.definition, "[G]o to [D]efinition")
						map("gD", vim.lsp.buf.declaration, "[G]o to [D]eclaration")
						map("gi", vim.lsp.buf.implementation, "[G]o to [I]mplementation")
						map("gt", vim.lsp.buf.type_definition, "[G]o to [T]ype Definition")
						map("gr", vim.lsp.buf.references, "[G]oto [R]eferences")
						map("<C-k>", vim.lsp.buf.signature_help, "[K]eyboard [S]ignature [H]elp")
						map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame symbol")
						map("<leader>fm", function()
							vim.lsp.buf.format({ async = true })
						end, "[F]ormat buffer")

						local client = vim.lsp.get_client_by_id(event.data.client_id)
						if client and client:supports_method("textDocument/inlayHint", event.buf) then
							map("<leader>th", function()
								vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
							end, "[T]oggle Inlay [H]ints")
						end
					end,
				})

				local builtin = require("telescope.builtin")
				vim.api.nvim_create_autocmd("LspAttach", {
					group = vim.api.nvim_create_augroup("telescope-lsp-attach", { clear = true }),
					callback = function(event)
						local buf = event.buf
						vim.keymap.set(
							"n",
							"grd",
							builtin.lsp_definitions,
							{ buffer = buf, desc = "[G]oto [D]efinition" }
						)
						vim.keymap.set(
							"n",
							"grr",
							builtin.lsp_references,
							{ buffer = buf, desc = "[G]oto [R]eferences" }
						)
						vim.keymap.set(
							"n",
							"gri",
							builtin.lsp_implementations,
							{ buffer = buf, desc = "[G]oto [I]mplementation" }
						)
						vim.keymap.set(
							"n",
							"grt",
							builtin.lsp_type_definitions,
							{ buffer = buf, desc = "[G]oto [T]ype Definition" }
						)
						vim.keymap.set(
							"n",
							"gO",
							builtin.lsp_document_symbols,
							{ buffer = buf, desc = "Open Document Symbols" }
						)
					end,
				})

				-- Servers are installed by Mason (see the mason-lspconfig spec
				-- below); these per-server settings fill the gaps that
				-- nvim-lspconfig's defaults do not cover.
				vim.lsp.config("lua_ls", {
					-- Attach even in a bare directory (no .git/.luarc root markers).
					single_file_support = true,
					on_init = function(client)
						if client.workspace_folders then
							local path = client.workspace_folders[1].name
							if
								path ~= vim.fn.stdpath("config")
								and (
									vim.uv.fs_stat(path .. "/.luarc.json")
									or vim.uv.fs_stat(path .. "/.luarc.jsonc")
								)
							then
								return
							end
						end

						client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
							runtime = {
								-- Use the same Lua version/path rules as Neovim.
								version = "LuaJIT",
								path = { "lua/?.lua", "lua/?/init.lua" },
							},
							-- Make lua_ls aware of the Neovim runtime so that `vim.`
							-- completes (object members, functions, etc.).
							workspace = {
								checkThirdParty = false,
								library = vim.api.nvim_get_runtime_file("", true),
							},
						})
					end,
					settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
							-- From Neovim-Minimal's lsp/lua_ls.lua.
							codeLens = { enable = true },
							hint = { enable = true, semicolon = "Disable" },
							telemetry = { enable = false },
						},
					},
				})

				vim.lsp.config("gopls", {
					-- From Neovim-Minimal's lsp/gopls.lua: re-enable semantic
					-- tokens, which gopls drops by default.
					settings = { gopls = { semanticTokens = true } },
				})

				-- pyright, ts_ls and bashls are installed by Mason (see the
				-- mason-lspconfig spec below) and auto-enabled. lua_ls,
				-- clangd, gopls and rust_analyzer cannot be installed by
				-- Mason on this platform (Alpine/musl), so they come from the
				-- container's package manager and are enabled here explicitly.
				vim.lsp.enable({
					"lua_ls",
					"pyright",
					"clangd",
					"gopls",
					"rust_analyzer",
					"ts_ls",
					"bashls",
				})
			end,
		},

		-- LSP server installation via Mason (codingbrush.com guide): Mason
		-- downloads the language servers, and mason-lspconfig bridges Mason
		-- and nvim-lspconfig. Only servers Mason can actually install on
		-- this platform are listed here; the rest come from the container's
		-- package manager and are enabled explicitly in nvim-lspconfig.
		{
			"mason-org/mason-lspconfig.nvim",
			dependencies = {
				{
					"mason-org/mason.nvim",
					opts = {
						ui = {
							border = "rounded",
							icons = {
								package_installed = "✓",
								package_pending = "➜",
								package_uninstalled = "✗",
							},
						},
					},
				},
			},
			opts = {
				-- Servers placed here are installed automatically by Mason.
				ensure_installed = {
					"pyright", -- Python
					"ts_ls", -- TypeScript / JavaScript
					"bashls", -- Bash
				},
			},
		},

		-- Formatting
		{
			"stevearc/conform.nvim",
			event = { "BufWritePre" },
			config = function()
				require("conform").setup({
					notify_on_error = false,
					format_on_save = function(bufnr)
						local enabled_filetypes = { lua = true, python = true }
						if enabled_filetypes[vim.bo[bufnr].filetype] then
							return { timeout_ms = 500 }
						else
							return nil
						end
					end,
					default_format_opts = { lsp_format = "fallback" },
					formatters_by_ft = {
						lua = { "stylua" },
						rust = { "rustfmt" },
					},
				})

				local format = function()
					require("conform").format({ async = true })
				end
				-- Minimal's <leader>fb (format buffer) replaces telescope's
				-- <leader>fb (find buffers); it's now handled by the conform
				-- plugin. Buffers are still available via <leader><leader>.
				vim.keymap.set({ "n", "v" }, "<leader>fb", format, { desc = "[F]ormat [B]uffer" })
				vim.keymap.set({ "n", "v" }, "<leader>F", format, { desc = "[F]ormat buffer" })
			end,
		},

		-- Indent guides: vertical lines that show where code blocks start/end.
		{
			"lukas-reineke/indent-blankline.nvim",
			main = "ibl",
			event = "VeryLazy",
			config = function()
				require("ibl").setup({
					indent = { char = "│" },
					scope = { enabled = true },
				})
			end,
		},

		-- Snippets
		{
			"L3MON4D3/LuaSnip",
			version = "2.*",
			dependencies = { "rafamadriz/friendly-snippets" },
			config = function()
				require("luasnip").setup({})
				require("luasnip.loaders.from_vscode").lazy_load()
			end,
		},

		-- Autocomplete. Loaded at startup (not lazy, no events) so it always
		-- triggers. Load via event = {'InsertEnter','CmdlineEnter'} if you
		-- prefer the slight startup-time win.
		{
			"saghen/blink.cmp",
			version = "1.*",
			lazy = false,
			dependencies = {
				{ "L3MON4D3/LuaSnip", version = "2.*" },
			},
			config = function()
				require("blink.cmp").setup({
					keymap = {
						-- 'default': <c-y> accepts, <c-space> opens docs,
						-- <tab> navigates snippets.
						preset = "default",
					},
					appearance = {
						nerd_font_variant = "mono",
					},
					completion = {
						documentation = { auto_show = false, auto_show_delay_ms = 500 },
						menu = { auto_show = true },
					},
					sources = {
						-- 'buffer' provides word completions even when no LSP
						-- is attached.
						default = { "lsp", "path", "snippets", "buffer" },
					},
					snippets = { preset = "luasnip" },
					-- Lua implementation avoids the prebuilt rust binary,
					-- which does not run on Alpine (musl).
					fuzzy = { implementation = "lua" },
					signature = { enabled = true },
				})
			end,
		},
	},
	install = { colorscheme = { "tokyonight-night" } },
})

-- [[ Treesitter ]]
-- Native treesitter (built into Neovim 0.12); enables highlighting for
-- languages whose parsers ship with Nvim.
vim.api.nvim_create_autocmd("FileType", {
	callback = function()
		pcall(vim.treesitter.start)
	end,
})

-- Transparent background (from Neovim-Minimal).
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
