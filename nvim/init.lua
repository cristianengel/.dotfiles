-- ─── Opciones básicas ───────────────────────────────────────────────
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.tabstop = 4
vim.opt.swapfile = false
vim.opt.winborder = "rounded"

-- ─── Líder ──────────────────────────────────────────────────────────
vim.g.mapleader = " "

-- ─── Keymaps básicos ────────────────────────────────────────────────
vim.keymap.set('n', '<leader>w', ':update<CR>')
vim.keymap.set('n', '<leader>q', ':quit<CR>')

-- ─── Plugins con vim.pack ───────────────────────────────────────────
vim.pack.add({
	{ src = "https://github.com/vague2k/vague.nvim" },
	{ src = "https://github.com/scottmckendry/cyberdream.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/nvim-mini/mini.pick" },
	{ src = "https://github.com/neovim/nvim-lspconfig", load = true },
	{ src = "https://github.com/hrsh7th/nvim-cmp" },
	{ src = "https://github.com/hrsh7th/cmp-nvim-lsp" },
	{ src = "https://github.com/L3MON4D3/LuaSnip" },
	{ src = "https://github.com/saadparwaiz1/cmp_luasnip" },
	{ src = "https://github.com/mfussenegger/nvim-dap" },
	{ src = "https://github.com/mfussenegger/nvim-jdtls" },
})

-- ─── Configuración de plugins ───────────────────────────────────────
require("mini.pick").setup()
require("oil").setup()

-- ─── Evitar advertencia de deprecación ──────────────────────────────
local old_notify = vim.notify
vim.notify = function(msg, level, opts)
	if type(msg) == "string" and msg:match("deprecated") then
		return
	end
	old_notify(msg, level, opts)
end

-- ─── LSP Configuración ──────────────────────────────────────────────
vim.cmd.packadd("nvim-lspconfig")
local lspconfig = require("lspconfig")

-- Capabilities extendidos para autocompletado
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Java LSP (JDTLS) con soporte para Lombok
local launcher_path = vim.fn.expand(
	"/home/cristianengel/.local/share/jdtls/plugins/org.eclipse.equinox.launcher_1.7.100.v20251014-1222.jar")
local lombok_path = vim.fn.expand("~/.local/share/lombok/lombok.jar")

local jdtls = require("jdtls")

jdtls.start_or_attach({
    capabilities = capabilities,
    cmd = {
        "java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-Xms1g",
        "--add-modules=ALL-SYSTEM",
        "--add-opens", "java.base/java.util=ALL-UNNAMED",
        "--add-opens", "java.base/java.lang=ALL-UNNAMED",
        "-javaagent:" .. lombok_path,
        "-jar", launcher_path,
        "-configuration", vim.fn.expand("~/.local/share/jdtls/config_linux"),
        "-data", vim.fn.expand("~/.local/share/eclipse/")
            .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t"),
    },
    root_dir = require("jdtls.setup").find_root({".git", "mvnw", "gradlew", "pom.xml", "build.gradle"}),
    filetypes = { "java" },
})


vim.notify = old_notify

-- ─── TypeScript / JavaScript LSP (tsserver) ─────────────────────────────
lspconfig.ts_ls.setup({
	capabilities = capabilities,
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = {
		"javascript", "javascriptreact", "javascript.jsx",
		"typescript", "typescriptreact", "typescript.tsx"
	},
	root_dir = require("lspconfig.util").root_pattern(
		"package.json", "tsconfig.json", "jsconfig.json", ".git"
	),
	settings = {
		typescript = {
			inlayHints = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayEnumMemberValueHints = true,
			},
		},
		javascript = {
			inlayHints = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayEnumMemberValueHints = true,
			},
		},
	},
})


-- ─── Configuración de nvim-cmp ──────────────────────────────────────
local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-Space>"] = cmp.mapping.complete(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
	}, {
		{ name = "buffer" },
	}),
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
})

-- ─── Keymaps LSP ───────────────────────────────────────────────────
vim.keymap.set('n', '<leader>lf', function() vim.lsp.buf.format({ async = true }) end)

-- ─── Apariencia ────────────────────────────────────────────────────
vim.cmd("colorscheme cyberdream")
vim.cmd(":hi statusline guibg=NONE")

-- ─── Mini.Pick / Oil atajos ──────────────────────────────────────────────
vim.keymap.set('n', '<leader>f', ":Pick files<CR>")
vim.keymap.set('n', '<leader>h', ":Pick help<CR>")
vim.keymap.set('n', '<leader>e', ":Oil<CR>")

-- ──────────────────────────────
-- Split windows
-- ──────────────────────────────

-- Horizontal split (top/bottom)
vim.keymap.set('n', '<leader>-', ':split<CR>', { noremap = true, silent = true })

-- Vertical split (side by side)
vim.keymap.set('n', '<leader>|', ':vsplit<CR>', { noremap = true, silent = true })

-- ──────────────────────────────
-- Navigate between splits (Ctrl + hjkl)
-- ──────────────────────────────
vim.keymap.set('n', '<C-h>', '<C-w>h', { noremap = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { noremap = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { noremap = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { noremap = true })

-- ──────────────────────────────
-- Resize splits (Ctrl + Arrow keys)
-- ──────────────────────────────
vim.keymap.set('n', '<C-Up>',    ':resize +2<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-Down>',  ':resize -2<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-Left>',  ':vertical resize -2<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-Right>', ':vertical resize +2<CR>', { noremap = true, silent = true })

-- Debug (nvim-dap) config and keymaps
vim.keymap.set('n', '<F9>', ':DapContinue<CR>')
vim.keymap.set('n', '<F8>', ':DapStepOver<CR>')
vim.keymap.set('n', '<F7>', ':DapStepInto<CR>')

-- colorscheme
require("cyberdream").setup({
    variant = "default", -- use "light" for the light variant. Also accepts "auto" to set dark or light colors based on the current value of `vim.o.background`
    transparent = true,
    saturation = 1, -- accepts a value between 0 and 1. 0 will be fully desaturated (greyscale) and 1 will be the full color (default)
    italic_comments = false,
    hide_fillchars = false,
    borderless_pickers = false,
    terminal_colors = false,
    cache = false,
    -- Disable or enable colorscheme extensions
    extensions = {
        notify = true,
        mini = true,
		...
    },
})
