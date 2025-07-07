------------------------------
-- Neovim options
------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

vim.opt.autochdir = true

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.scrolloff = 8

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.pumheight = 7

vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.breakindentopt = "shift:4"

vim.opt.showmode = false
vim.opt.conceallevel = 2

------------------------------
-- Keymaps
------------------------------
-- better up/down
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })

-- Resize window using <shift> arrow keys
vim.keymap.set("n", "<S-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<S-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<S-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<S-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Split Window
vim.keymap.set("n", "<leader>\"", "<C-W>s", { desc = "Split window below", remap = true })
vim.keymap.set("n", "<leader>%", "<C-W>v", { desc = "Split window right", remap = true })

-- Diagnostic 
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostics at cursor" })

-- Copy diagnostic to clipboard
function CopyDiagnosticToClipboard()
    local bufnr = vim.api.nvim_get_current_buf()
    local pos = vim.api.nvim_win_get_cursor(0)
    local row = pos[1] - 1

    local diagnostics = vim.diagnostic.get(bufnr, {lnum = row})
    if #diagnostics == 0 then
        print("No diagnostics found at the cursor position.")
        return
    end

    local message = diagnostics[1].message
    vim.fn.setreg("+", message, "c")
    print("Diagnostic copied to clipboard: " .. message)
end

vim.api.nvim_create_user_command("CopyDiagnostic", CopyDiagnosticToClipboard, { })
vim.api.nvim_set_keymap("n", "<leader>cd", ":CopyDiagnostic<CR>", { noremap = true, silent = true })

-- Buffers
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

-- Move lines
vim.keymap.set("v", "<S-j>", ":m '>+1<cr>gv=gv", { desc = "Move down", remap = false, silent = true })
vim.keymap.set("v", "<S-k>", ":m '<-2<cr>gv=gv", { desc = "Move up", remap = false, silent = true })

-- Clear search with <esc>
vim.keymap.set({ "i", "n" }, "<esc>", "<cmd>noh<CR><esc>", { desc = "Escape and clear hlsearch" })

------------------------------
-- Auto commands 
------------------------------
-- Highligt yanking
vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})
-- Continue editing
vim.api.nvim_create_autocmd("BufReadPost", {
    group = vim.api.nvim_create_augroup("last_loc", { clear = true }),
    callback = function(event)
        local exclude = { "gitcommit" }
        local buf = event.buf
        if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
            return
        end
        vim.b[buf].lazyvim_last_loc = true
        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        local lcount = vim.api.nvim_buf_line_count(buf)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
-- ColorScheme settings:
vim.api.nvim_create_autocmd("ColorScheme", {
   pattern = "*",
   callback = function()
       -- Sign column (gutter area)
       vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
       -- Window separator lines
       vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#9ece6a" }) -- Light Green
       -- Transparent background for lualine and navic
       vim.api.nvim_set_hl(0, "WinBar", { bg = "NONE" })
       vim.api.nvim_set_hl(0, "WinBarNC", { bg = "NONE" })
       vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
       vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
   end,
})
-- JavaScript/TypeScript file settings
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact", "css", "scss", "html" },
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.expandtab = true
    end,
})

------------------------------
-- Plugins
------------------------------
-- lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field
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

require("lazy").setup({
    -- Nightowl (color scheme)
    {
        "oxfist/night-owl.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("night-owl").setup {
                transparent_background = true,
            }
            vim.cmd.colorscheme("night-owl")
        end,
    },
    -- LSP & Plugins (Kickstart-based configuration)
    {
        "neovim/nvim-lspconfig",

        dependencies = {
            { "mason-org/mason.nvim", config = true, opts = { }, },
            { "mason-org/mason-lspconfig.nvim" },
        },

        config = function()
            vim.diagnostic.config({
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = "",
                        [vim.diagnostic.severity.WARN]  = "",
                        [vim.diagnostic.severity.INFO]  = "",
                        [vim.diagnostic.severity.HINT]  = "󰌶",
                    },
                },
            })

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
                callback = function(event)
                    vim.keymap.set("n", "gd", require("telescope.builtin").lsp_definitions, { buffer = event.buf, desc = "LSP: [G]oto [D]efinition" })
                    vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, { buffer = event.buf, desc = "LSP: [G]oto [R]eferences" })
                    vim.keymap.set("n", "gi", require("telescope.builtin").lsp_implementations, { buffer = event.buf, desc = "LSP: [G]oto [I]mplementation" })
                    vim.keymap.set("n", "<leader>st", require("telescope.builtin").lsp_type_definitions, { buffer = event.buf, desc = "LSP: [S]ymbols (type definition)" })
                    vim.keymap.set("n", "<leader>sd", require("telescope.builtin").lsp_document_symbols, { buffer = event.buf, desc = "LSP: [S]ymbols (document)" })
                    vim.keymap.set("n", "<leader>sw", require("telescope.builtin").lsp_dynamic_workspace_symbols, { buffer = event.buf, desc = "LSP: [S]ymbols (workspace)" })
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = event.buf, desc = "LSP: [R]e[n]ame" })
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = event.buf, desc = "LSP: [C]ode [A]ction" })
                    vim.keymap.set("v", "<leader>ca", vim.lsp.buf.code_action, { buffer = event.buf, desc = "LSP: [C]ode [A]ction" })
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = event.buf, desc = "LSP: Hover Documentation" })
                    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = event.buf, desc = "LSP: [G]oto [D]eclaration" })
                    vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, { buffer = event.buf, desc = "LSP: Format Document" })

                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if client and client.server_capabilities.documentHighlightProvider then
                        local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.document_highlight,
                        })
                        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.clear_references,
                        })
                    end
                end,
            })

            vim.api.nvim_create_autocmd("LspDetach", {
                group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
                callback = function(event)
                    vim.lsp.buf.clear_references()
                    vim.api.nvim_clear_autocmds { group = "kickstart-lsp-highlight", buffer = event.buf }
                end,
            })

            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

            local servers = {
                lua_ls = {
                    root_dir = require("lspconfig.util").root_pattern(".git", "init.lua", "*.lua") or vim.fn.getcwd(),
                    settings = {
                        Lua = {
                            diagnostics = { globals = { "vim" } },
                            runtime = { version = "LuaJIT" },
                            workspace = {
                                library = {
                                    [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                                    [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
                                },
                                checkThirdParty = false,
                            },
                            telemetry = { enable = false },
                            completion = { callsnippet = "Replace" },
                        },
                    },
                },
                pyright = { },
                gopls = { },
                jsonls = { },
                bashls = { },
                ts_ls = {
                    settings = {
                        typescript = {
                            inlayHints = {
                                includeInlayParameterNameHints = 'all',
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
                                includeInlayParameterNameHints = 'all',
                                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                                includeInlayFunctionParameterTypeHints = true,
                                includeInlayVariableTypeHints = true,
                                includeInlayPropertyDeclarationTypeHints = true,
                                includeInlayFunctionLikeReturnTypeHints = true,
                                includeInlayEnumMemberValueHints = true,
                            },
                        },
                    },
                },
                tailwindcss = {
                    settings = {
                        tailwindCSS = {
                            experimental = {
                                classRegex = {
                                    "tw`([^`]*)",
                                    "tw\\.[^`]+`([^`]*)`",
                                    "tw\\(.*?\\).*?`([^`]*)",
                                    "cn\\(([^)]*)\\)",
                                },
                            },
                        },
                    },
                },
                eslint = { },
            }

            require("mason-lspconfig").setup({
                ensure_installed = vim.tbl_keys(servers),
                automatic_installation = true,
                automatic_enable = false,
            })

            for server_name, server_opts in pairs(servers) do
                server_opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_opts.capabilities or {})
                require("lspconfig")[server_name].setup(server_opts)
            end
        end,
    },
    -- Autocompletion
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-path",
        },

        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            cmp.setup {
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end
                },
                mapping = cmp.mapping.preset.insert {
                    ["<C-d>"] = cmp.mapping.scroll_docs(4),
                    ["<C-u>"] = cmp.mapping.scroll_docs(-4),
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s", desc = "Next item / Snippet jump forward" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s", desc = "Prev item / Snippet jump backward" }),
                },
                sources = cmp.config.sources {
                    { name = "nvim_lsp" },
                    { name = "path" },
                    { name = "buffer" },
                },
                formatting = {
                    format = require("nvim-highlight-colors").format
                },
            }
        end,
    },
    -- Telescope with fzf-native
    {
        "nvim-telescope/telescope.nvim", tag = "0.1.6",

        dependencies = {
            { "nvim-lua/plenary.nvim" },
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            { "nvim-telescope/telescope-file-browser.nvim" },
        },

        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")

            telescope.setup {
                defaults = {
                    mappings = {
                        i = {
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                        },
                    },
                },
                pickers = {
                    find_files = {
                        hidden = true,
                        file_ignore_patterns = { "^.git/", "^node_modules/", "^.cache/" },
                    },
                },
                extensions = {
                    file_browser = {
                        depth = 1,
                        auto_depth = true,
                        hidden = true,
                        respect_gitignore = false,
                        grouped = true,
                        previewer = true,
                        hijack_netrw = true,
                    }
                }
            }

            telescope.load_extension("fzf")
            telescope.load_extension("file_browser")

            local builtin = require("telescope.builtin")

            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
            vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Find diagnostics" })
            vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Find keymaps" })
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help" })
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
            vim.keymap.set("n", "<leader>fe", function() telescope.extensions.file_browser.file_browser() end, { desc = "File browser" })
        end,
    },
    -- Comment
    {
        "numToStr/Comment.nvim", opts = { },
    },
    -- Toggleterm
    {
        "akinsho/toggleterm.nvim", version = "*",
        config = function()
            require("toggleterm").setup {
                size = function(term)
                    if term.direction == "horizontal" then
                        return 15
                    elseif term.direction == "vertical" then
                        return vim.o.columns * 0.4
                    else
                        return 20
                    end
                end,
                hide_numbers = true,
                start_in_insert = true,
                terminal_mappings = true,
                persist_size = false,
                persist_mode = true,
                close_on_exit = true,
                shell = vim.o.shell,
            }

            local Terminal = require("toggleterm.terminal").Terminal
            local float_term = Terminal:new({ id = 1, direction = "float", hidden = true, float_opts = { border = "curved" }})
            local horizontal_term = Terminal:new({ id = 2, direction = "horizontal", hidden = true })
            local vertical_term = Terminal:new({ id = 3, direction = "vertical", hidden = true })

            -- Custom key mappings for terminal navigation
            vim.api.nvim_create_autocmd("TermOpen", {
                pattern = "term://*",
                callback = function()
                    local function try_move_from_term(mode_key)
                        local current_win = vim.api.nvim_get_current_win()
                        vim.cmd("wincmd " .. mode_key)
                        local new_win = vim.api.nvim_get_current_win()
                        if current_win == new_win then
                            vim.cmd("startinsert")
                        end
                    end

                    vim.keymap.set("t", "<esc><esc>", [[<C-\><C-n>]], { desc = "Enter normal mode in terminal", noremap = true, silent = true })
                    vim.keymap.set("t", "<C-h>", function() try_move_from_term("h") end, { desc = "Go to left window from terminal", noremap = true, silent = true })
                    vim.keymap.set("t", "<C-j>", function() try_move_from_term("j") end, { desc = "Go to lower window from terminal", noremap = true, silent = true })
                    vim.keymap.set("t", "<C-k>", function() try_move_from_term("k") end, { desc = "Go to upper window from terminal", noremap = true, silent = true })
                    vim.keymap.set("t", "<C-l>", function() try_move_from_term("l") end, { desc = "Go to right window from terminal", noremap = true, silent = true })
                end,
            })

            -- Auto-start insert mode
            vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
                pattern = "term://*toggleterm#*",
                callback = function()
                    if vim.bo.filetype == "toggleterm" then
                        vim.cmd("startinsert")
                    end
                end,
            })

            -- Key mappings to toggle the terminal
            vim.keymap.set("n", "<C-\\>", function() float_term:toggle() end, { desc = "Terminal (Float)", noremap = true, silent = true })
            vim.keymap.set("n", "<leader>th", function() horizontal_term:toggle() end, { desc = "Terminal (Horizontal)", noremap = true, silent = true })
            vim.keymap.set("n", "<leader>tv", function() vertical_term:toggle() end, { desc = "Terminal (Vertical)", noremap = true, silent = true })
            vim.keymap.set("t", "<C-\\>", function() float_term:toggle() end, { desc = "Terminal (Float)", noremap = true, silent = true })
            vim.keymap.set("t", "<leader>th", function() horizontal_term:toggle() end, { desc = "Terminal (Horizontal)", noremap = true, silent = true })
            vim.keymap.set("t", "<leader>tv", function() vertical_term:toggle() end, { desc = "Terminal (Vertical)", noremap = true, silent = true })
        end,
    },
    -- Indent blankline
    {
        "lukas-reineke/indent-blankline.nvim", main = "ibl",
        config = function()
            require("ibl").setup {
                indent = {
                    char = { "▏", "" }
                },
                scope = {
                    show_start = false,
                    show_end = false
                },
                exclude = {
                    filetypes = { "lspinfo", "packer", "checkhalth", "man", "gitcommit", "TelescopePrompt", "TelescopeResults", "''" },
                    buftypes = { "terminal", "nofile", "quickfix", "prompt" }
                },
            }
        end,
    },
    -- Lualine
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            local auto_theme_custom = require("lualine.themes.auto")
            local function get_mode_color()
                local mode_color = {
                    n = "#c792ea",      -- Normal (magenta)
                    i = "#c5e478",      -- Insert (green)
                    v = "#e2b93d",      -- Visual (yellow)
                    V = "#e2b93d",      -- Visual Line
                    ["\x16"] = "#ffcb8b", -- Visual Block (orange2)
                    R = "#f78c6c",      -- Replace (orange)
                    c = "#6ae9f0",      -- Command (cyan)
                }
                return {
                    bg = mode_color[vim.fn.mode()] or "#0e293f",  -- inactive color
                    fg = "#010d18"  -- dark color for text
                }
            end
            for _, mode in pairs({"normal", "insert", "visual", "replace", "command", "inactive"}) do
                if auto_theme_custom[mode] then
                    for _, section in pairs({ "a", "b", "c", "x", "y", "z" }) do
                        if auto_theme_custom[mode][section] then
                            auto_theme_custom[mode][section].bg = "none"
                        end
                    end
                end
            end
            require("lualine").setup {
                options = {
                    icons_enabled = true,
                    theme = auto_theme_custom,
                    component_separators = { left = "", right = nil },
                    section_separators = { left = "", right = nil },
                    always_devide_middle = true,
                    globalstatus = true,
                },
                sections = {
                    lualine_a = {
                        {
                            "mode",
                            color = get_mode_color,
                        }
                    },
                    lualine_b = {
                        {
                            "branch",
                            color = { bg = "#0b253a" },
                        },
                        {
                            "diff",
                            color = { bg = "#0b253a" },
                        },
                    },
                    lualine_c = {
                        {
                            function()
                                local diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
                                local diag_types = { "Error", "Warn", "Info", "Hint" }
                                local results = { }

                                for _, diag_type in ipairs(diag_types) do
                                    local diags = vim.tbl_filter(
                                    function(diag)
                                        return diag.severity == vim.diagnostic.severity[diag_type:upper()]
                                    end, diagnostics)

                                    if #diags > 0 then
                                        local messages = vim.tbl_map(
                                        function(diag)
                                            return diag.message
                                        end, diags)

                                        table.insert(results, "%#Diagnostic" .. diag_type .. "#" .. table.concat(messages, ", "))
                                    end
                                end
                                return table.concat(results, " ")
                            end,

                            cond = function()
                                return #vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 }) > 0
                            end,
                        },
                    },
                    lualine_x = {
                        {
                            require("noice").api.status.command.get,
                            cond = require("noice").api.status.command.has,
                            color = { fg = "#bb9af7", bg = "#0b253a" },
                        },
                        {
                            require("noice").api.status.mode.get,
                            cond = require("noice").api.status.mode.has,
                            color = { fg = "#ff9e64", bg = "#0b253a" },
                        },
                        {
                            "diagnostics",
                            sources = { "nvim_diagnostic" },
                            sections ={ "error", "warn" },
                            always_visible = true,
                            color = { bg = "#0b253a" },
                        },
                    },
                    lualine_y = {
                        {
                            "filetype",
                            padding = { left = 1, right = 0 },
                            color = { bg = "#0b253a" },
                        },
                        {
                            icon = " ",
                            function()
                                local clients = vim.lsp.get_clients({ bufnr = 0 })
                                if next(clients) == nil then return "Inactive" end
                                local client_names = { }
                                for _, client in ipairs(clients) do
                                    table.insert(client_names, client.name)
                                end
                                return table.concat(client_names, ", ")
                            end,
                            color = { bg = "#0b253a" },
                        },
                    },
                    lualine_z = {
                        {
                            "location",
                            color = get_mode_color,
                        },
                        {
                            "progress",
                            padding = { left = 0, right = 1 },
                            color = get_mode_color,
                        },
                    },
                },
                tabline = {
                    lualine_a = {
                        {
                            "buffers",
                            symbols = {
                                modified = " +",
                                alternate_file = "# ",
                                directory = " ",
                            },
                            max_length = vim.o.columns,
                            buffers_color = {
                                active = { fg = "#030d17", bg = "#c792ea" },
                                inactive = { fg = "#555e8f", bg = "#01111d" },
                            },
                        },
                    },
                },
                winbar = {
                    lualine_a = {
                        {
                            "filetype",
                            icon_only = true,
                            separator = { right = "" },
                            padding = { left = 1, right = 0 },
                        },
                        {
                            "filename",
                            file_status = false,
                            padding = { left = 0, right = 1 },
                            separator = { right = "" },
                            color = { fg = "Normal" },
                        },
                    },
                    lualine_c = {
                        {
                            "navic",
                            padding = { left = 1, right = 0 },
                        },
                    },
                    lualine_z = {
                        function ()
                            return " "
                        end,
                    },
                },
            }
        end,
    },
    -- Treesitter & Treesitter-context
    {
        "nvim-treesitter/nvim-treesitter", build = ":TSUpdate",
        dependencies = {
            "nvim-treesitter/nvim-treesitter-context",
        },
        config = function()
            require("nvim-treesitter.configs").setup {
                ensure_installed = {
                    "lua",
                    "markdown",
                    "markdown_inline",
                    "python",
                    "go",
                    "vimdoc",
                    "vim",
                    "javascript",
                    "typescript",
                    "tsx",
                    "css",
                    "json",
                    "html",
                    "regex",
                },
                auto_install = true,
                sync_install = false,
                ignore_install = { },
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                modules = { },
            }
            require("treesitter-context").setup {
                max_lines = 3,
                mode = "cursor",
            }
        end,
    },
    -- Navic
    {
        "SmiteshP/nvim-navic",
        config = function()
            vim.api.nvim_set_hl(0, "NavicText", { bg = "none" })
            vim.api.nvim_set_hl(0, "NavicSeparator", { bg = "none" })
            vim.api.nvim_set_hl(0, "NavicIconsFile",          { fg = "#7aa2f7" }) -- Soft Blue
            vim.api.nvim_set_hl(0, "NavicIconsModule",        { fg = "#5eacd3" }) -- Sky Blue
            vim.api.nvim_set_hl(0, "NavicIconsNamespace",     { fg = "#9d7cd8" }) -- Lavender
            vim.api.nvim_set_hl(0, "NavicIconsPackage",       { fg = "#bb9af7" }) -- Periwinkle
            vim.api.nvim_set_hl(0, "NavicIconsClass",         { fg = "#f7768e" }) -- Bright Pink
            vim.api.nvim_set_hl(0, "NavicIconsMethod",        { fg = "#9ece6a" }) -- Light Green
            vim.api.nvim_set_hl(0, "NavicIconsProperty",      { fg = "#e0af68" }) -- Soft Orange
            vim.api.nvim_set_hl(0, "NavicIconsField",         { fg = "#ff9e64" }) -- Salmon
            vim.api.nvim_set_hl(0, "NavicIconsConstructor",   { fg = "#7dcfff" }) -- Cyan
            vim.api.nvim_set_hl(0, "NavicIconsEnum",          { fg = "#ff007c" }) -- Brighter Pink
            vim.api.nvim_set_hl(0, "NavicIconsInterface",     { fg = "#ad8ee6" }) -- Muted Purple
            vim.api.nvim_set_hl(0, "NavicIconsFunction",      { fg = "#9ece6a" }) -- Light Green
            vim.api.nvim_set_hl(0, "NavicIconsVariable",      { fg = "#ff9e64" }) -- Salmon
            vim.api.nvim_set_hl(0, "NavicIconsConstant",      { fg = "#ff9e64" }) -- Salmon
            vim.api.nvim_set_hl(0, "NavicIconsString",        { fg = "#e0af68" }) -- Soft Orange
            vim.api.nvim_set_hl(0, "NavicIconsNumber",        { fg = "#ff9e64" }) -- Salmon
            vim.api.nvim_set_hl(0, "NavicIconsBoolean",       { fg = "#f7768e" }) -- Bright Pink
            vim.api.nvim_set_hl(0, "NavicIconsArray",         { fg = "#e0af68" }) -- Soft Orange
            vim.api.nvim_set_hl(0, "NavicIconsObject",        { fg = "#7dcfff" }) -- Cyan
            vim.api.nvim_set_hl(0, "NavicIconsKey",           { fg = "#9ece6a" }) -- Light Green
            vim.api.nvim_set_hl(0, "NavicIconsNull",          { fg = "#565f89" }) -- Dark Grey
                vim.api.nvim_set_hl(0, "NavicIconsEnumMember",    { fg = "#bb9af7" }) -- Periwinkle
                vim.api.nvim_set_hl(0, "NavicIconsStruct",        { fg = "#ff007c" }) -- Brighter Pink
                vim.api.nvim_set_hl(0, "NavicIconsEvent",         { fg = "#7aa2f7" }) -- Soft Blue
                vim.api.nvim_set_hl(0, "NavicIconsOperator",      { fg = "#ff9e64" }) -- Salmon
                vim.api.nvim_set_hl(0, "NavicIconsTypeParameter", { fg = "#9d7cd8" }) -- Lavender

                require("nvim-navic").setup {
                    lsp = { auto_attach = true },
                    highlight = true,
                    separator = "  ",
                }
            end,
        },
        -- Noice
        {
            "folke/noice.nvim",
            event = "VeryLazy",
            dependencies = {
                "MunifTanjim/nui.nvim",
            },
            config = function()
                require("noice").setup({
                    cmdline = {
                        view = "cmdline",
                    },
                      messages = {
                          view = "notify",
                          view_error = "notify",
                          view_warn = "notify",
                          view_history = "messages",
                          view_search = "virtualtext",
                      },
                      notify = {
                          enabled = true,
                          view = "notify",
                      },
                })
                vim.keymap.set("n", "<leader>nh", function() require("noice").cmd("history") end, { desc = "Noice history" })
                vim.keymap.set("n", "<leader>nl", function() require("noice").cmd("last") end, { desc = "Noice last" })
            end,
    },
    -- Color Highlighting
    {
        "brenoprata10/nvim-highlight-colors",
        event = "BufReadPre",
        config = function()
            require("nvim-highlight-colors").setup({
                render = "virtual",
                enable_tailwind = true,
                virtual_symbol = "■",
            })
        end,
    },
})
