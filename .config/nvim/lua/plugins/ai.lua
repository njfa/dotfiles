-- 共通の前提部分を定義
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
            },
            {
                "MeanderingProgrammer/render-markdown.nvim",
                ft = { "markdown", "vimwiki", "codecompanion" },
                dependencies = { "nvim-treesitter/nvim-treesitter" },
                config = function()
                    require("render-markdown").setup({
                        render_modes = true,
                        code = {
                            left_pad = 0,
                            right_pad = 1,
                            width = "block",
                        },
                        heading = {
                            width = "block",
                            left_pad = 0,
                            right_pad = 1,
                            -- icons = { "󰼏 ", "󰎨 ", "󰼑 ", "󰎲 ", "󰼓 ", "󰎴 " },
                            icons = {},
                            backgrounds = {
                                "my_markdown_h1",
                                "my_markdown_h2",
                                "my_markdown_h3",
                                "my_markdown_h4",
                                "my_markdown_h5",
                                "my_markdown_h6",
                            },
                        }
                    })
                end,
            },

        },
        init = function()
            require("plugins.codecompanion.fidget-spinner"):init()
        end,
        config = function()
            local function configure_adapter_with_model_override(adapter_name)
                local config_path = vim.fn.stdpath("data")
                local file_path = config_path .. "/" .. adapter_name .. "_model.txt"

                local model_override
                local file_exists = vim.fn.filereadable(file_path) == 1
                if file_exists then
                    local content = vim.fn.readfile(file_path)
                    if content and #content > 0 and content[1] ~= "" then
                        model_override = content[1]
                    end
                end

                local base_adapter = require("codecompanion.adapters").extend(adapter_name, {})
                if model_override then
                    return require("codecompanion.adapters").extend(adapter_name, {
                        schema = {
                            model = {
                                default = model_override,
                            },
                        },
                    })
                end
                return base_adapter
            end

            require("codecompanion").setup({
                opts = {
                    log_level = "DEBUG", -- or "TRACE"
                    language = 'Japanese',
                    system_prompt = function(_)
                        return [[
あなたは "CodeCompanion" というAIプログラミングアシスタントです。
現在、Neovimのテキストエディタに統合されており、ユーザーがより効率的に作業できるよう支援します。

## あなたの主なタスク:
- 一般的なプログラミングの質問に回答する
- Neovim バッファ内のコードの動作を説明する
- 選択されたコードのレビューを行う
- 選択されたコードの単体テストを生成する
- 問題のあるコードの修正を提案する
- 新しいワークスペース用のコードを作成する
- ユーザーの質問に関連するコードを検索する
- テストの失敗の原因を特定し、修正を提案する
- Neovim に関する質問に答える
- 各種ツールを実行する

## 指示:
1. ユーザーの指示を正確に守ること
2. 可能な限り簡潔で、要点を押さえた回答を心がけること
3. 不要なコードを含めず、タスクに関連するコードのみ返すこと
4. すべての非コードの応答はGitlab Flavored Markdownのスタイルでフォーマットすること
5. すべての非コードの応答は日本語で行うこと
6. すべての非コードの応答はですます調ではなく、である調とすること
8. 文章中の改行には `\n` を使わず、実際の改行を使用すること

## タスクを受けたとき:
1. ステップごとに考え、詳細な擬似コードまたは計画を説明する（特に指定がない限り）
2. コードを1つのコードブロックで出力する（適切な言語名を付与）
3. ユーザーの次のアクションを提案する
4. 各ターンごとに1つの応答のみを返す

## Gitlab Flavored Markdownスタイルの留意事項:
1. 回答全体をバッククォートで囲まないこと
2. トップレベルのヘッダは`###`とすること
3. 行頭が`#`で始まる行の前後に空行を入れること
4. 文章中のインデントは ` ` を使用すること
5. コードブロックの最初にプログラミング言語を明示すること
6. コードブロック内に行番号を含めないこと
7. 回答に `　` が含まれていないか注意深く見直し、含まれている場合は インデントを下げた上で `-` を使ったリストの表現に置き換えること
]]
                    end,
                },
                adapters = {
                    copilot = configure_adapter_with_model_override('copilot')
                },
                strategies = {
                    chat = {
                        adapter = "copilot",
                        roles = {
                            llm = function(adapter)
                                return "CodeCompanion (" .. adapter.formatted_name .. ")"
                            end,
                            user = 'Me',
                        }
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
                    },
                    chat = {
                        show_settings = true,
                        show_keys = true,
                        show_reference_info = true,
                        show_system_messages = true,
                    },
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
                                content = function(context)
                                    return string.format(
                                        [[### 依頼したいタスク

#buffer:%d-%d の説明をお願いします。
]],
                                        context.start_line,
                                        context.end_line
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
                                content = function(context)
                                    return string.format(
                                        [[### 依頼したいタスク

1. #buffer:%d-%d の修正案の作成をお願いします。
2. 修正内容の説明もお願いします。
]],
                                        context.start_line,
                                        context.end_line
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
                                content = function(context)
                                    return string.format(
                                        [[### 依頼したいタスク

1. #buffer:%d-%d のコメントドキュメントの作成をお願いします。
2. コメント内容の説明もお願いします。
]],
                                        context.start_line,
                                        context.end_line
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
                                content = function(context)
                                    return string.format(
                                        [[### 依頼したいタスク

1. #buffer:%d-%d のUnit Testを作成してください。
2. テスト内容の説明もお願いします。
]],
                                        context.start_line,
                                        context.end_line
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

                                    return string.format(
                                        [[### 依頼したいタスク

1. プログラミング言語%sで作成された #buffer:%d-%d のDiagnosticsの指摘内容を説明してください。
    - Diagnosticsの指定がない場合はより良いソースコードになるような修正案を作成してください。
2. Diagnosticsのメッセージは下記の通りです。
%s
]],
                                        context.filetype,
                                        context.start_line,
                                        context.end_line,
                                        concatenated_diagnostics
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

                                    return string.format(
                                        [[### 依頼したいタスク

1. プログラミング言語%sで作成された #buffer:%d-%d のDiagnosticsの指摘内容を解消してください。
    - Diagnosticsの指定がない場合はより良いソースコードになるような修正案を作成してください。
2. 修正内容の説明もお願いします。
3. Diagnosticsのメッセージは下記の通りです。
%s
]],
                                        context.filetype,
                                        context.start_line,
                                        context.end_line,
                                        concatenated_diagnostics
                                    )
                                end,
                                opts = {
                                    contains_code = true,
                                },
                            },
                        },
                    },
                    ["Generate a Commit Message"] = {
                        strategy = "chat",
                        description = "Generate a commit message (staged)",
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
                                content = function()
                                    return string.format(
                                        [[### 依頼したいタスク

あなたはConventional Commit specificationに従ってコミットメッセージを生成する専門家です。以下のgit diffを元に日本語でコミットメッセージを作成してください。

```diff
%s
```]],
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
                        description = "Generate a commit message (staged/unstaged)",
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
                                content = function()
                                    return string.format(
                                        [[### 依頼したいタスク

あなたはConventional Commit specificationに従ってコミットメッセージを生成する専門家です。以下のgit diffを元に日本語でコミットメッセージを作成してください。

```diff
%s
```]],
                                        vim.fn.system("git diff --no-ext-diff")
                                    )
                                end,
                                opts = {
                                    contains_code = true,
                                },
                            },
                        },
                    },
                    ["Code workflow"] = {
                        strategy = "workflow",
                        description = "Use a workflow to guide an LLM in writing code",
                        opts = {
                            index = 1,
                            is_default = true,
                            short_name = "cw",
                        },
                        prompts = {
                            {
                                -- We can group prompts together to make a workflow
                                -- This is the first prompt in the workflow
                                {
                                    role = "system",
                                    content = function(context)
                                        return string.format(
                                            "You carefully provide accurate, factual, thoughtful, nuanced answers, and are brilliant at reasoning, and ensure your response is in Japanese. If you think there might not be a correct answer, you say so. Always spend a few sentences explaining background context, assumptions, and step-by-step thinking BEFORE you try to answer a question. Don't be verbose in your answers, but do provide details and examples where it might help the explanation. You are an expert software engineer for the %s language.",
                                            context.filetype
                                        )
                                    end,
                                    opts = {
                                        visible = false,
                                    },
                                },
                                {
                                    role = "user",
                                    content = [[]],
                                    opts = {
                                        auto_submit = false,
                                    },
                                },
                            },
                            -- This is the second group of prompts
                            {
                                {
                                    role = "user",
                                    content =
                                    "Great. Now let's consider your code. I'd like you to check it carefully for correctness, style, and efficiency, and give constructive criticism for how to improve it, and ensure your response is in Japanese.",
                                    opts = {
                                        auto_submit = true,
                                    },
                                },
                            },
                            -- This is the final group of prompts
                            {
                                {
                                    role = "user",
                                    content =
                                    "Thanks. Now let's revise the code based on the feedback, without additional explanations.",
                                    opts = {
                                        auto_submit = true,
                                    },
                                },
                            },
                        },
                    },
                },
            })
        end
    }
}
