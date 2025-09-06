vim.g.mapleader = " "

vim.keymap.set("i", "jk", "<Esc>l", { noremap = true })

local hlgrp = vim.api.nvim_create_augroup("SmartHLSearch", { clear = true })
vim.api.nvim_create_autocmd("InsertEnter", {
  group = hlgrp,
  callback = function() vim.opt.hlsearch = false end,
})
vim.api.nvim_create_autocmd("CmdlineEnter", {
  group = hlgrp,
  pattern = { "/", "?" },
  callback = function() vim.opt.hlsearch = true end,
})

-- Space + e → open Ex (netrw)
vim.keymap.set("n", "<Space>e", ":Ex<CR>", { noremap = true, silent = true })

-- Completion popup behavior
vim.o.completeopt = "menu,menuone,noselect"

local ok, packer = pcall(require, "packer")
if not ok then
  vim.notify("packer not found (install it first)", vim.log.levels.WARN)
  return
end

packer.startup(function(use)
  use "wbthomason/packer.nvim"

  -- Installer & LSP
  use "williamboman/mason.nvim"
  use "williamboman/mason-lspconfig.nvim"
  use "neovim/nvim-lspconfig"

  -- Autocomplete stack
  use "hrsh7th/nvim-cmp"
  use "hrsh7th/cmp-nvim-lsp"
  use "hrsh7th/cmp-buffer"
  use "hrsh7th/cmp-path"
  use "saadparwaiz1/cmp_luasnip"

  -- Snippets
  use "L3MON4D3/LuaSnip"
  use "rafamadriz/friendly-snippets"

  -- Discord Rich Presence
  use "andweeb/presence.nvim"
end)

require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = {
    -- Web
    "html", "cssls", "ts_ls", "emmet_ls",
    -- Python
    "pyright",
    -- Java
    "jdtls",
    -- C / C++
    "clangd",
    -- C#
    "omnisharp",
    -- Lua (for NVim config)
    "lua_ls",
  },
  automatic_installation = true,
})

local cmp = require("cmp")
local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()

local capabilities = require("cmp_nvim_lsp").default_capabilities()

cmp.setup({
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = {
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"]      = cmp.mapping.confirm({ select = true }),
    ["<Tab>"]     = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"]   = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<C-e>"]     = cmp.mapping.abort(),
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "path" },
    { name = "buffer" },
  },
})

local on_attach = function(_, bufnr)
  local map = function(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, buffer = bufnr })
  end
  map("n", "gd", vim.lsp.buf.definition)
  map("n", "gD", vim.lsp.buf.declaration)
  map("n", "gr", vim.lsp.buf.references)
  map("n", "gi", vim.lsp.buf.implementation)
  map("n", "K",  vim.lsp.buf.hover)
  map("n", "<leader>rn", vim.lsp.buf.rename)
  map("n", "<leader>ca", vim.lsp.buf.code_action)
  map("n", "[d", vim.diagnostic.goto_prev)
  map("n", "]d", vim.diagnostic.goto_next)
  map("n", "gl", vim.diagnostic.open_float)  -- avoid <leader>e conflict with :Ex
  map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end)
end

-- LSP servers
local lsp = require("lspconfig")

-- Lua (NVim runtime)
lsp.lua_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    }
  }
})

-- Web
lsp.html.setup({ capabilities = capabilities, on_attach = on_attach })
lsp.cssls.setup({ capabilities = capabilities, on_attach = on_attach })
lsp.ts_ls.setup({ capabilities = capabilities, on_attach = on_attach })
lsp.emmet_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  filetypes = { "html", "css", "javascriptreact", "typescriptreact", "javascript", "typescript" },
})

-- Python
lsp.pyright.setup({ capabilities = capabilities, on_attach = on_attach })

-- Java (basic; for advanced, add 'nvim-jdtls' later)
lsp.jdtls.setup({ capabilities = capabilities, on_attach = on_attach })

-- C / C++
lsp.clangd.setup({ capabilities = capabilities, on_attach = on_attach })

-- C#
lsp.omnisharp.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- Diagnostics visuals
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Discord Rich Presence
require("presence").setup({
  neovim_image_text = "Neovim + Coffee ☕",
})

