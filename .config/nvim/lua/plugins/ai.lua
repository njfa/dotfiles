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
                adapters = {
                    copilot = function()
                        local adapter_name = "copilot"
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

                        local base_adapter = require("codecompanion.adapters").extend("copilot", {})
                        if model_override then
                            return require("codecompanion.adapters").extend("copilot", {
                                schema = {
                                    model = {
                                        default = model_override,
                                    },
                                },
                            })
                        end
                        return base_adapter
                    end,
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
1. 回答文はGitlab Flavored Markdownのスタイルで作成してください。
    - 行頭が`#`で始まる行の前後に空行を入れてください。
    - `**`の強調は使用しないでください。
2. 回答中の説明は、すべて日本語で作成してください。
3. 回答文は、ですます調ではなく、である調で回答してください。

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
1. 回答文はGitlab Flavored Markdownのスタイルで作成してください。
    - 行頭が`#`で始まる行の前後に空行を入れてください。
    - `**`の強調は使用しないでください。
2. 回答中の説明は、すべて日本語で作成してください。
3. 回答文は、ですます調ではなく、である調で回答してください。

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
1. 回答文はGitlab Flavored Markdownのスタイルで作成してください。
    - 行頭が`#`で始まる行の前後に空行を入れてください。
    - `**`の強調は使用しないでください。
2. 回答中の説明は、すべて日本語で作成してください。
3. 回答文は、ですます調ではなく、である調で回答してください。

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
1. 回答文はGitlab Flavored Markdownのスタイルで作成してください。
    - 行頭が`#`で始まる行の前後に空行を入れてください。
    - `**`の強調は使用しないでください。
2. 回答中の説明は、すべて日本語で作成してください。
3. 回答文は、ですます調ではなく、である調で回答してください。

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
1. 回答文はGitlab Flavored Markdownのスタイルで作成してください。
    - 行頭が`#`で始まる行の前後に空行を入れてください。
    - `**`の強調は使用しないでください。
2. 回答中の説明は、すべて日本語で作成してください。
3. 回答文は、ですます調ではなく、である調で回答してください。

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
2. Diagnosticsのメッセージは下記の通りです。
%s
3. 修正対象はbufnrが%dのバッファの下記コードです。

```%s
%s
```
]],
                                        context.filetype,
                                        concatenated_diagnostics,
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
1. 回答文はGitlab Flavored Markdownのスタイルで作成してください。
    - 行頭が`#`で始まる行の前後に空行を入れてください。
    - `**`の強調は使用しないでください。
2. 回答中の説明は、すべて日本語で作成してください。
3. 回答文は、ですます調ではなく、である調で回答してください。

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
                                content = [[■前提
1. 回答文はGitlab Flavored Markdownのスタイルで作成してください。
    - 行頭が`#`で始まる行の前後に空行を入れてください。
    - `**`の強調は使用しないでください。
2. 回答中の説明は、すべて日本語で作成してください。
3. コミットメッセージも日本語で作成してください。
4. 回答文は、ですます調ではなく、である調で回答してください。

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
                                content = [[■前提
1. 回答文はGitlab Flavored Markdownのスタイルで作成してください。
    - 行頭が`#`で始まる行の前後に空行を入れてください。
    - `**`の強調は使用しないでください。
2. 回答中の説明は、すべて日本語で作成してください。
3. コミットメッセージも日本語で作成してください。
4. 回答文は、ですます調ではなく、である調で回答してください。

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
