local map = vim.keymap.set

return {
	"neovim/nvim-lspconfig",
	event = "VeryLazy",
	dependencies = { "barreiroleo/ltex_extra.nvim" },
	config = function()
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		local function custom_on_attach(client, bufnr)
			local function opts(desc)
				return { buffer = bufnr, desc = "LSP " .. desc }
			end

			map("n", "gd", vim.lsp.buf.definition, opts("Go to type definition"))
			map("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
			map("n", "<leader>D", vim.lsp.buf.type_definition, opts("Go to type definition"))
			map("n", "<leader>ra", vim.lsp.buf.rename, opts("Rename symbol"))
			map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions", noremap = true })

			if client.name == "ltex_plus" then
				require("ltex_extra").setup({
					load_langs = { "en-US", "de-DE" },
					init_check = true,
					path = vim.fn.stdpath("config") .. "/spell",
				})
			end
		end

		local servers = {
			"html",
			"cssls",
			"ts_ls",
			"clangd",
			"ltex_plus",
			"marksman",
			"tailwindcss",
			"jdtls",
			"pylsp",
			"lua_ls",
			"harper_ls",
			-- "GitHub Copilot",
		}

		-- Local dictionary
		local words = {}
		local spell_add = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
		if vim.fn.filereadable(spell_add) == 1 then
			words = vim.fn.readfile(spell_add)
		end

		-- Make sure python venv is used
		-- local venv = os.getenv("VIRTUAL_ENV")
		-- local python_path = venv and venv .. "/bin/python" or "python3"

		-- Custom Server Settings
		local server_settings = {
			jdtls = {},
			tailwindcss = {
				tailwindCSS = {
					experimental = {
						classRegex = { -- react-native typescript support
							"tw`([^`]*)",
							"tw\\(([^)]*)",
							"tw\\.\\w+\\(`([^`]*)",
							"tw\\.\\w+\\(\\{([^}]*)",
						},
					},
				},
			},
			harper_ls = {
				["harper-ls"] = {
					userDictPath = vim.fn.stdpath("config") .. "/spell/en.utf-8.add",
					workspaceDictPath = "",
					fileDictPath = "",
					linters = {
						SpellCheck = true,
						SpelledNumbers = false,
						AnA = true,
						SentenceCapitalization = true,
						UnclosedQuotes = true,
						WrongQuotes = false,
						LongSentences = true,
						RepeatedWords = true,
						Spaces = true,
						Matcher = true,
						CorrectNumberSuffix = true,
					},
					codeActions = {
						ForceStable = false,
					},
					markdown = {
						IgnoreLinkTitle = false,
					},
					diagnosticSeverity = "hint",
					isolateEnglish = false,
					dialect = "American",
					maxFileLength = 120000,
					ignoredLintsPath = "",
					excludePatterns = {},
				},
			},
			lua_ls = {
				Lua = {
					runtime = { version = "LuaJIT" },
					diagnostics = { globals = { "vim" } }, -- recognize `vim` global
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
						checkThirdParty = false,
					},
					telemetry = { enable = false },
				},
			},
			ltex_plus = {
				ltex = {
					checkFrequency = "save",
					language = "en-US", -- default; change with '% LTeX: language=de-DE', or YAML frontmatter
					logLevel = "warn",
					dictionary = {
						["en-US"] = words,
						["de-DE"] = words,
					},
					additionalRules = {
						enablePickyRules = true, -- sent. length, passive voice, ... (disable if too many)
						motherTongue = "de-DE",
						languageModel = "~/.models/ngrams/", -- ngram models path; download from: https://languagetool.org/download/ngram-data/
					},
					latex = {
						environments = {
							tabular = "ignore",
							tabularx = "ignore",
							algorithm = "ignore",
							["algorithm*"] = "ignore",
						},
						commands = {
							["\\texorpdfstring{}{}"] = "dummy",
							["\\right."] = "ignore",
						},
					},
					enabled = {
						"bibtex",
						"gitcommit",
						"org",
						"tex",
						"restructuredtext",
						"rsweave",
						"latex",
						"quarto",
						"rmd",
						"context",
						"mail",
						"plaintext",
						"markdown",
					},
				},
			},
			html = {},
			marksman = {},
			cssls = {},
			clangd = {},
			ts_ls = {},
			pylsp = {
				pylsp = {
					plugins = {
						pycodestyle = { enabled = false },
						jedi_completion = { fuzzy = true },
						mccabe = { enabled = false },
						pylsp_mypy = {
							enabled = true,
							-- dmypy = true,
							live_mode = false, -- Enable live mode for Mypy
							report_progress = true, -- Report progress for Mypy
							-- overrides = { "--python-executable", python_path, "--ignore-missing-imports" }, -- Use the virtual environment's Python executable
							-- dmypy_command = { "~/.local/share/nvim/mason/packages/python-lsp-server/venv/bin/dmypy" }
						},
						isort = { enabled = false },
						spyder = { enabled = false },
						autopep8 = { enabled = false },
						memestra = { enabled = false },
						flake8 = { enabled = false },
						pyflakes = { enabled = false },
						yapf = { enabled = false },
						rope = { enabled = false },
						rope_autoimport = { enabled = false },
						preload = { enabled = false },
						pydocstyle = { enabled = false },
						pylint = { enabled = false },
						ruff = {
							enabled = true,
							formatEnabled = true,
							unsafeFixes = true,
							ignore = { "TD002", "TD003", "PD901" }, -- Example ignores, adjust as needed
							format = { "I" },
							extendSelect = { "I" },
							severities = {
								["FIX002"] = "W",
								["ARG002"] = "I",
							},
						},
					},
				},
			},
		}

		local drop_filetypes = {
			tailwindcss = { markdown = true },
			ltex_plus = { markdown = true, gitcommit = true },
		}

		--[[ Reading `vim.lsp.config[name]` resolves nvim-lspconfig's lsp/<name>.lua and
		     validates it, which throws when the server binary is not on PATH. ]]
		local function resolved_config(name)
			local ok, cfg = pcall(function()
				return vim.lsp.config[name]
			end)
			return ok and cfg or nil
		end

		-- Configure each server
		for _, lsp in ipairs(servers) do
			local config = {
				on_attach = custom_on_attach,
				capabilities = capabilities,
				settings = server_settings[lsp],
			}
			local drop = drop_filetypes[lsp]
			if drop then
				local resolved = resolved_config(lsp)
				local defaults = resolved and resolved.filetypes or {}
				config.filetypes = vim.tbl_filter(function(ft)
					return not drop[ft]
				end, defaults)
			end
			vim.lsp.config(lsp, config)
		end

		vim.lsp.config("harper_ls", {
			cmd = { "harper-ls", "--stdio" },
			filetypes = { "markdown", "text", "tex", "typst", "gitcommit", "mail", "plaintext", "html" },
		})

		--[[ Never attach to a buffer without a file name: the client gets a bogus
		     `file://` URI and marksman logs an error on every keystroke.
				 Wraps each server's default root_dir. ]]
		for _, lsp in ipairs(servers) do
			local resolved = resolved_config(lsp)
			local default_root, markers = resolved and resolved.root_dir, resolved and resolved.root_markers
			vim.lsp.config(lsp, {
				root_dir = function(bufnr, on_dir)
					if vim.api.nvim_buf_get_name(bufnr) == "" then
						return
					end
					if type(default_root) == "function" then
						return default_root(bufnr, on_dir)
					end
					-- a root_dir function takes precedence over root_markers, so apply them here
					on_dir(default_root or (markers and vim.fs.root(bufnr, markers)) or nil)
				end,
			})
		end

		--[[ harper_ls stays configured but is not started automatically: it produces a lot
		     of false positives in anything that is not prose. ]]
		local opt_in = { harper_ls = true }
		vim.lsp.log.set_level("error")
		vim.lsp.enable(vim.tbl_filter(function(name)
			return not opt_in[name]
		end, servers))

		vim.api.nvim_create_user_command("HarperToggle", function()
			local clients = vim.lsp.get_clients({ name = "harper_ls" })
			if #clients == 0 then
				vim.lsp.enable("harper_ls")
				vim.notify("harper_ls enabled")
				return
			end
			--[[ `vim.lsp.enable(name, false)` only drops the config from
			     lsp._enabled_configs, i.e. it stops *future* attachment -- already running
			     clients keep going, so they have to be stopped explicitly. ]]
			vim.lsp.enable("harper_ls", false)
			for _, client in ipairs(clients) do
				client:stop() -- vim.lsp.stop_client() is deprecated in 0.12
			end
			vim.notify("harper_ls disabled")
		end, { desc = "Toggle the harper_ls grammar server" })

		-- Diagnostics in new line
		vim.diagnostic.config({
			-- virtual_text = true,
			virtual_lines = { current_line = true },
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "",
					[vim.diagnostic.severity.WARN] = "",
					[vim.diagnostic.severity.HINT] = "",
					[vim.diagnostic.severity.INFO] = "",
				},
			},
		})
	end,
}
