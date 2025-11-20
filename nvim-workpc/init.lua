-- ─── Opciones básicas ───────────────────────────────────────────────
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.winborder = "rounded"
vim.opt.clipboard = "unnamedplus"
vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
vim.keymap.set("n", "<Esc><Esc>", ":nohl<CR>")

-- Tabs e indentación estándar de 4 espacios
vim.opt.tabstop = 4        -- cada tab equivale a 4 espacios
vim.opt.shiftwidth = 4     -- indentación automática usa 4 espacios
vim.opt.softtabstop = 4    -- al presionar <Tab> inserta 4 espacios
vim.opt.expandtab = true   -- convierte tabs reales a espacios
vim.opt.smartindent = true -- indentación inteligente
vim.opt.autoindent = true  -- mantiene indent del nivel anterior


-- ─── Líder ──────────────────────────────────────────────────────────
vim.g.mapleader = " "

-- ─── Keymaps básicos ────────────────────────────────────────────────
vim.keymap.set('n', '<leader>w', ':update<CR>')
vim.keymap.set('n', '<leader>q', ':quit<CR>')
vim.keymap.set("n", "<leader>di", function()
  vim.diagnostic.open_float()
end, { silent = true })

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
	{ src = "https://github.com/nvim-neotest/nvim-nio" },
	{ src = "https://github.com/rcarriga/nvim-dap-ui" },
	{ src = "https://github.com/nvim-mini/mini.pairs" },
	{ src = "https://github.com/nvim-mini/mini.indentscope" },
})

-- ─── Configuración de plugins ───────────────────────────────────────
require("oil").setup()

-- jdtls & dap
vim.api.nvim_create_autocmd("FileType", {
    pattern = "java",
    callback = function()
        local jdtls = require("jdtls")

        local root_dir = require("jdtls.setup").find_root({ "pom.xml", "build.gradle", ".git" })

        local workspace_dir = vim.fn.expand("~/.local/share/eclipse/java-workspaces/")
            .. vim.fn.fnamemodify(root_dir, ":p:h:t")

        local launcher_path = vim.fn.expand(
			"~/.local/share/nvim/lsp_servers/jdtls/plugins/org.eclipse.equinox.launcher_1.7.100.v20251014-1222.jar"
		)



        local lombok_path = vim.fn.expand("~/.local/share/lombok/lombok.jar")

		local bundles = {}

		vim.list_extend(bundles,
		  vim.split(
			vim.fn.glob("~/.local/share/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar"),
			"\n"
		  )
		)

        jdtls.start_or_attach({
            cmd = {
                "/usr/lib/jvm/java-21-openjdk-amd64/bin/java",
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
                "-configuration", vim.fn.expand("~/.local/share/nvim/lsp_servers/jdtls/config_linux"),
                "-data", workspace_dir,
            },
            root_dir = root_dir,
            filetypes = { "java" },
			settings = {
				java = {}
			},
			init_options = {
				bundles = bundles
			},
        })

		jdtls.setup_dap()
    end,
})

vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, { desc = "Go to Definition" })

local dap = require("dap")
local dapui = require("dapui")

dapui.setup()

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end

dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end

dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

dap.configurations.java = {
  {
    name = "Attach WildFly",
    type = "java",
    request = "attach",
    hostName = "127.0.0.1",
    port = 8787,
  },
  {
    name = "Attach Spring-Boot",
    type = "java",
    request = "attach",
    hostName = "127.0.0.1",
    port = 5005,
  },
}

-- ─── TypeScript / JavaScript LSP (tsserver) ─────────────────────────────
require('lspconfig').tsserver.setup {
   capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
}

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
vim.keymap.set("n", "<leader>du", function()
	require("dapui").toggle()
end, { desc = "Toggle DAP UI" })
vim.keymap.set('n', '<leader>db', ":DapToggleBreakpoint<CR>")

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

-- telescope
vim.keymap.set('n', '<leader>ff', ':Telescope find_files<CR>')
vim.keymap.set('n', '<leader>fg', ':Telescope live_grep<CR>')

-- mini.pairs
require("mini.pairs").setup()

-- indentscope
require("mini.indentscope").setup({
    draw = {
        delay = 0,
    },
    symbol = "│",  -- podés usar "╎", "▏", etc.
})

-- auto-save
local timer = nil

vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
  callback = function()
    if timer then
      vim.fn.timer_stop(timer)
    end

    timer = vim.fn.timer_start(1500, function()
      if vim.bo.modifiable and vim.fn.bufloaded(0) == 1 then
        vim.cmd("silent! write")
      end
    end)
  end,
})

