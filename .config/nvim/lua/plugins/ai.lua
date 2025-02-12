return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        config = function()
            require("copilot").setup({
                suggestion = { enabled = false },
                panel = { enabled = false },
                copilot_node_command = 'node'
            })
        end,
    },
    {
        "olimorris/codecompanion.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "j-hui/fidget.nvim",
            {
                "echasnovski/mini.diff",
                version = false,
                config = function()
                    require("mini.diff").setup()
                end
            }
        },
        init = function()
            require("plugins.codecompanion.fidget-spinner"):init()
        end,
        config = function()
            require("codecompanion").setup({
                opts = {
                    log_level = "DEBUG", -- or "TRACE"
                },
                strategies = {
                    chat = {
                        adapter = "copilot",
                    },
                    cmd = {
                        adapter = "copilot",
                    },
                    inline = {
                        adapter = "copilot",
                    },
                    keymaps = {
                        send = {
                            modes = { n = "<C-s>", i = "<C-s>" },
                        },
                        close = {
                            modes = { n = "<C-c>", i = "<C-c>" },
                        },
                        -- Add further custom keymaps here
                    },
                },
                display = {
                    action_palette = {
                        width = 95,
                        height = 10,
                        prompt = "Prompt ",                     -- Prompt used for interactive LLM calls
                        provider = "default",                   -- default|telescope|mini_pick
                        opts = {
                            show_default_actions = true,        -- Show the default actions in the action palette?
                            show_default_prompt_library = true, -- Show the default prompt library in the action palette?
                        },
                    },
                    diff = {
                        enabled = true,
                        provider = "mini_diff"
                    }
                },
                prompt_library = {
                    ["Explain"] = {
                        strategy = "chat",
                        description = "選択したコードの説明をお願いする",
                        opts = {
                            index = 5,
                            is_default = true,
                            is_slash_cmd = false,
                            modes = { "v" },
                            short_name = "explain",
                            auto_submit = true,
                            user_prompt = false,
                            stop_context_insertion = true,
                        },
                        prompts = {
                            {
                                role = "system",
                                content = [[When asked to explain code, follow these steps:

1. Identify the programming language.
2. Describe the purpose of the code and reference core concepts from the programming language.
3. Explain each function or significant block of code, including parameters and return values.
4. Highlight any specific functions or methods used and their roles.
5. Provide context on how the code fits into a larger application if applicable.]],
                                opts = {
                                    visible = false,
                                },
                            },
                            {
                                role = "user",
                                content = [[■前提
1. 回答はすべて日本語で作成してください。
2. ですます調ではなく、である調で回答してください。

■依頼内容]],
                            },
                            {
                                role = "user",
                                content = function(context)
                                    local code = require("codecompanion.helpers.actions").get_code(context.start_line,
                                        context.end_line)

                                    return string.format(
                                        [[#buffer
1. 説明対象はbufnrが%dのバッファの下記コードです。

```%s
%s
```
]],
                                        context.bufnr,
                                        context.filetype,
                                        code
                                    )
                                end,
                                opts = {
                                    contains_code = true,
                                },
                            },
                        },
                    },
                    ["Fix code"] = {
                        strategy = "chat",
                        description = "選択したコードの修正案の作成をお願いする",
                        opts = {
                            index = 7,
                            is_default = true,
                            is_slash_cmd = false,
                            modes = { "v" },
                            short_name = "fix_plan",
                            auto_submit = true,
                            user_prompt = false,
                            stop_context_insertion = true,
                        },
                        prompts = {
                            {
                                role = "system",
                                content = [[When asked to fix code, follow these steps:

1. **Identify the Issues**: Carefully read the provided code and identify any potential issues or improvements.
2. **Plan the Fix**: Describe the plan for fixing the code in pseudocode, detailing each step.
3. **Implement the Fix**: Write the corrected code in a single code block.
4. **Explain the Fix**: Briefly explain what changes were made and why.

Ensure the fixed code:

- Includes necessary imports.
- Handles potential errors.
- Follows best practices for readability and maintainability.
- Is formatted correctly.

Use Markdown formatting and include the programming language name at the start of the code block.]],
                                opts = {
                                    visible = false,
                                },
                            },
                            {
                                role = "user",
                                content = [[■前提
1. 回答はすべて日本語で作成してください。
2. ですます調ではなく、である調で回答してください。

■依頼内容]],
                            },
                            {
                                role = "user",
                                content = function(context)
                                    local code = require("codecompanion.helpers.actions").get_code(context.start_line,
                                        context.end_line)

                                    return string.format(
                                        [[#buffer
1. 修正対象はbufnrが%dのバッファの下記コードです。
2. 修正内容の説明もお願いします。

```%s
%s
```
]],
                                        context.bufnr,
                                        context.filetype,
                                        code
                                    )
                                end,
                                opts = {
                                    contains_code = true,
                                },
                            },
                        },
                    },
                    ["Docs"] = {
                        strategy = "chat",
                        description = "コードへのコメント作成をお願いする",
                        opts = {
                            is_default = true,
                            is_slash_cmd = false,
                            modes = { "v" },
                            short_name = "docs",
                            auto_submit = true,
                            user_prompt = false,
                            stop_context_insertion = true,
                        },
                        prompts = {
                            {
                                role = "user",
                                content = [[■前提
1. 回答はすべて日本語で作成してください。
2. ですます調ではなく、である調で回答してください。

■依頼内容]],
                            },
                            {
                                role = "user",
                                content = function(context)
                                    local code = require("codecompanion.helpers.actions").get_code(context.start_line,
                                        context.end_line)

                                    return string.format(
                                        [[#buffer
1. ソースコードへのコメントドキュメントの修正案の作成をお願いします。
2. 修正対象はbufnrが%dのバッファの下記コードです。
3. コメント内容の説明もお願いします。

```%s
%s
```
]],
                                        context.bufnr,
                                        context.filetype,
                                        code
                                    )
                                end,
                                opts = {
                                    contains_code = true,
                                },
                            },
                        },
                    },
                    ["Unit Tests"] = {
                        strategy = "chat",
                        description = "選択したコードの単体テストコードの作成をお願いする",
                        opts = {
                            index = 6,
                            is_default = true,
                            is_slash_cmd = false,
                            modes = { "v" },
                            short_name = "tests",
                            auto_submit = true,
                            user_prompt = false,
                            stop_context_insertion = true,
                        },
                        prompts = {
                            {
                                role = "system",
                                content = [[When generating unit tests, follow these steps:

1. Identify the programming language.
2. Identify the purpose of the function or module to be tested.
3. List the edge cases and typical use cases that should be covered in the tests and share the plan with the user.
4. Generate unit tests using an appropriate testing framework for the identified programming language.
5. Ensure the tests cover:
      - Normal cases
      - Edge cases
      - Error handling (if applicable)
6. Provide the generated unit tests in a clear and organized manner without additional explanations or chat.]],
                                opts = {
                                    visible = false,
                                },
                            },
                            {
                                role = "user",
                                content = [[■前提
1. 回答はすべて日本語で作成してください。
2. ですます調ではなく、である調で回答してください。

■依頼内容]],
                            },
                            {
                                role = "user",
                                content = function(context)
                                    local code = require("codecompanion.helpers.actions").get_code(context.start_line,
                                        context.end_line)

                                    return string.format(
                                        [[#buffer
1. テスト対象はbufnrが%dのバッファの下記コードです。
2. テスト内容の説明もお願いします。

```%s
%s
```
]],
                                        context.bufnr,
                                        context.filetype,
                                        code
                                    )
                                end,
                                opts = {
                                    contains_code = true,
                                },
                            },
                        },
                    },
                    ["Explain LSP Diagnostics"] = {
                        strategy = "chat",
                        description = "Explain the LSP diagnostics for the selected code",
                        opts = {
                            index = 9,
                            is_default = true,
                            is_slash_cmd = false,
                            modes = { "v" },
                            short_name = "lsp",
                            auto_submit = true,
                            user_prompt = false,
                            stop_context_insertion = true,
                        },
                        prompts = {
                            {
                                role = "system",
                                content =
                                [[You are an expert coder and helpful assistant who can help debug code diagnostics, such as warning and error messages. When appropriate, give solutions with code snippets as fenced codeblocks with a language identifier to enable syntax highlighting.]],
                                opts = {
                                    visible = false,
                                },
                            },
                            {
                                role = "user",
                                content = [[■前提
1. 回答はすべて日本語で作成してください。
2. ですます調ではなく、である調で回答してください。

■依頼内容]],
                            },
                            {
                                role = "user",
                                content = function(context)
                                    local diagnostics = require("codecompanion.helpers.actions").get_diagnostics(
                                        context.start_line,
                                        context.end_line,
                                        context.bufnr
                                    )

                                    local concatenated_diagnostics = ""
                                    for i, diagnostic in ipairs(diagnostics) do
                                        concatenated_diagnostics = concatenated_diagnostics
                                            .. i
                                            .. ". Issue "
                                            .. i
                                            .. "\n  - Location: Line "
                                            .. diagnostic.line_number
                                            .. "\n  - Buffer: "
                                            .. context.bufnr
                                            .. "\n  - Severity: "
                                            .. diagnostic.severity
                                            .. "\n  - Message: "
                                            .. diagnostic.message
                                            .. "\n"
                                    end

                                    return string.format(
                                        [[プログラミング言語は %s です。Diagnosticのメッセージは下記の通りです。

%s

]],
                                        context.filetype,
                                        concatenated_diagnostics
                                    )
                                end,
                            },
                            {
                                role = "user",
                                content = function(context)
                                    local code = require("codecompanion.helpers.actions").get_code(
                                        context.start_line,
                                        context.end_line,
                                        { show_line_numbers = true }
                                    )
                                    return string.format(
                                        [[
対象のコードは下記の通りです。Diagnosticの指摘内容を説明してください。

```%s
%s
```
]],
                                        context.filetype,
                                        code
                                    )
                                end,
                                opts = {
                                    contains_code = true,
                                },
                            },
                        },
                    },
                    ["Fix LSP Diagnostics"] = {
                        strategy = "chat",
                        description = "Fix the LSP diagnostics for the selected code",
                        opts = {
                            index = 19,
                            is_default = true,
                            is_slash_cmd = false,
                            modes = { "v" },
                            short_name = "fix_diagnostics",
                            auto_submit = true,
                            user_prompt = false,
                            stop_context_insertion = true,
                        },
                        prompts = {
                            {
                                role = "system",
                                content =
                                [[You are an expert coder and helpful assistant who can help debug code diagnostics, such as warning and error messages. When appropriate, give solutions with code snippets as fenced codeblocks with a language identifier to enable syntax highlighting.]],
                                opts = {
                                    visible = false,
                                },
                            },
                            {
                                role = "user",
                                content = [[■前提
1. 回答はすべて日本語で作成してください。
2. ですます調ではなく、である調で回答してください。

■依頼内容]],
                            },
                            {
                                role = "user",
                                content = function(context)
                                    local diagnostics = require("codecompanion.helpers.actions").get_diagnostics(
                                        context.start_line,
                                        context.end_line,
                                        context.bufnr
                                    )

                                    local concatenated_diagnostics = ""
                                    for i, diagnostic in ipairs(diagnostics) do
                                        concatenated_diagnostics = concatenated_diagnostics
                                            .. "    " .. i
                                            .. ". Issue "
                                            .. i
                                            .. "\n        - Location: Line "
                                            .. diagnostic.line_number
                                            .. "\n        - Buffer: "
                                            .. context.bufnr
                                            .. "\n        - Severity: "
                                            .. diagnostic.severity
                                            .. "\n        - Message: "
                                            .. diagnostic.message
                                            .. "\n"
                                    end

                                    if concatenated_diagnostics == "" then
                                        concatenated_diagnostics = "    - 指摘なし"
                                    end

                                    local code = require("codecompanion.helpers.actions").get_code(
                                        context.start_line,
                                        context.end_line,
                                        { show_line_numbers = true }
                                    )

                                    return string.format(
                                        [[#buffer
1. プログラミング言語%sで作成されたソースコードのDiagnosticsの指摘内容を解消してください。
    - Diagnosticsの指定がない場合はより良いソースコードになるような修正案を作成してください。
2. Diagnosticsのメッセージは下記の通りです。
%s
3. 修正対象はbufnrが%dのバッファの下記コードです。

```%s
%s
```

4. 修正内容の説明もお願いします。
]],
                                        context.filetype,
                                        concatenated_diagnostics,
                                        context.bufnr,
                                        context.filetype,
                                        code
                                    )
                                end,
                            },
                        },
                    },
                    ["Generate a Commit Message"] = {
                        strategy = "chat",
                        description = "Generate a commit message",
                        opts = {
                            index = 10,
                            is_default = true,
                            is_slash_cmd = true,
                            short_name = "commit_staged",
                            auto_submit = true,
                        },
                        prompts = {
                            {
                                role = "user",
                                content = [[■前提
1. 回答はすべて日本語で作成してください。
2. ですます調ではなく、である調で回答してください。

■依頼内容]],
                            },
                            {
                                role = "user",
                                content = function()
                                    return string.format(
                                        [[あなたはConventional Commit specificationに従ってコミットメッセージを生成する専門家です。以下のgit diffを元にコミットメッセージを作成してください。

```diff
%s
```
]],
                                        vim.fn.system("git diff --no-ext-diff --staged")
                                    )
                                end,
                                opts = {
                                    contains_code = true,
                                },
                            },
                        },
                    },
                    ["Generate a Commit Message (all)"] = {
                        strategy = "chat",
                        description = "Generate a commit message",
                        opts = {
                            index = 20,
                            is_default = true,
                            is_slash_cmd = true,
                            short_name = "commit_all",
                            auto_submit = true,
                        },
                        prompts = {
                            {
                                role = "user",
                                content = [[■前提
1. 回答はすべて日本語で作成してください。
2. ですます調ではなく、である調で回答してください。

■依頼内容]],
                            },
                            {
                                role = "user",
                                content = function()
                                    return string.format(
                                        [[あなたはConventional Commit specificationに従ってコミットメッセージを生成する専門家です。以下のgit diffを元にコミットメッセージを作成してください。

```diff
%s
```
]],
                                        vim.fn.system("git diff --no-ext-diff")
                                    )
                                end,
                                opts = {
                                    contains_code = true,
                                },
                            },
                        },
                    },
                },
            })
        end
    }
    -- {
    --     "CopilotC-Nvim/CopilotChat.nvim",
    --     dependencies = {
    --         { "zbirenbaum/copilot.lua" },                   -- or zbirenbaum/copilot.lua
    --         { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    --     },
    --     build = "make tiktoken",                            -- Only on MacOS or Linux
    --     config = function()
    --         -- See Configuration section for options
    --         require("CopilotChat").setup({
    --             show_help = "yes",
    --             prompts = {
    --                 Explain = {
    --                     prompt = "/COPILOT_EXPLAIN コードを日本語で説明してください",
    --                     mapping = '<leader>ae',
    --                     description = "コードの説明をお願いする",
    --                 },
    --                 Review = {
    --                     prompt = '/COPILOT_REVIEW コードを日本語でレビューしてください。',
    --                     mapping = '<leader>ar',
    --                     description = "コードのレビューをお願いする",
    --                 },
    --                 Fix = {
    --                     prompt = "/COPILOT_FIX このコードには問題があります。バグを修正したコードを表示してください。説明は日本語でお願いします。",
    --                     mapping = '<leader>aff',
    --                     description = "コードの修正をお願いする",
    --                 },
    --                 Optimize = {
    --                     prompt = "/COPILOT_REFACTOR 選択したコードを最適化し、パフォーマンスと可読性を向上させてください。説明は日本語でお願いします。",
    --                     mapping = '<leader>ao',
    --                     description = "コードの最適化をお願いする",
    --                 },
    --                 Docs = {
    --                     prompt = "/COPILOT_GENERATE 選択したコードに関するドキュメントコメントを日本語で生成してください。",
    --                     mapping = '<leader>ad',
    --                     description = "コードのドキュメント作成をお願いする",
    --                 },
    --                 Tests = {
    --                     prompt = "/COPILOT_TESTS 選択したコードの詳細なユニットテストを書いてください。説明は日本語でお願いします。",
    --                     mapping = '<leader>at',
    --                     description = "テストコード作成をお願いする",
    --                 },
    --                 FixDiagnostic = {
    --                     prompt = 'コードの診断結果に従って問題を修正してください。修正内容の説明は日本語でお願いします。',
    --                     mapping = '<leader>afd',
    --                     description = "Diagnosticsに従ったコードの修正をお願いする",
    --                     selection = require('CopilotChat.select').diagnostics,
    --                 },
    --                 Commit = {
    --                     prompt =
    --                     '実装差分に対するコミットメッセージを日本語で記述してください。',
    --                     mapping = '<leader>agc',
    --                     description = "コミットメッセージの作成をお願いする",
    --                     selection = require('CopilotChat.select').gitdiff,
    --                 },
    --                 CommitStaged = {
    --                     prompt =
    --                     'ステージ済みの変更に対するコミットメッセージを日本語で記述してください。',
    --                     mapping = '<leader>ags',
    --                     description = "ステージ済みのコミットメッセージの作成をお願いする",
    --                     selection = function(source)
    --                         return require('CopilotChat.select').gitdiff(source, true)
    --                     end,
    --                 },
    --             },
    --         })
    --     end,
    --     -- See Commands section for default commands if you want to lazy load on them
    -- },
}
