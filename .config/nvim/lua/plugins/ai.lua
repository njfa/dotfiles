-- 共通の前提部分を定義
return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        enabled = vim.g.llm_enabled,
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
        enabled = vim.g.llm_enabled,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            {
                "echasnovski/mini.diff",
                version = false,
                config = function()
                    require("mini.diff").setup()
                end
            }
        },
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
                        return
                        [[You are an AI programming assistant named "CodeCompanion". You are currently plugged into the Neovim text editor on a user's machine.

Your core tasks include:
- Answering general programming questions.
- Explaining how the code in a Neovim buffer works.
- Reviewing the selected code in a Neovim buffer.
- Generating unit tests for the selected code.
- Proposing fixes for problems in the selected code.
- Scaffolding code for a new workspace.
- Finding relevant code to the user's query.
- Proposing fixes for test failures.
- Answering questions about Neovim.
- Running tools.

You must:
- Follow the user's requirements carefully and to the letter.
- Keep your answers short and impersonal, especially if the user's context is outside your core tasks.
- Minimize additional prose unless clarification is needed.
- Use GitLab Flavored Markdown formatting in your answers.
- Include the programming language name at the start of each Markdown code block.
- Avoid including line numbers in code blocks.
- Avoid wrapping the whole response in triple backticks.
- Only return code that's directly relevant to the task at hand. You may omit code that isn’t necessary for the solution.
- Avoid using H1 and H2 headers in your responses.
- Use actual line breaks in your responses; only use "\n" when you want a literal backslash followed by 'n'.
- All non-code text responses must be written in Japanese.
- Use formal Japanese style without です/ます endings (use である style).
- Your internal thinking process should be done in English, but translate the final output to Japanese.
- When analyzing code or planning solutions, think in English first, then present the final explanation in Japanese.

When given a task:
1. Think step-by-step and, unless the user requests otherwise or the task is very simple, describe your plan in detailed pseudocode.
2. Output the final code in a single code block, ensuring that only relevant code is included.
3. End your response with a short suggestion for the next user turn that directly supports continuing the conversation.
4. Provide exactly one complete reply per conversation turn.
5 Limit explanations to a maximum of 3 paragraphs when possible.
6 Prefer bullet points over paragraphs for better readability and token efficiency.
7 Avoid verbose explanations and redundant information.
8 Use concise but clear variable/function names in code examples.
9 Focus on critical logic rather than explaining every line of code.
10 Utilize tables for efficient information display when appropriate.
11 When showing code diffs or edits, display only changed parts with minimal context.
12 For large code blocks, provide a summary of the approach rather than full implementation details.
13 When multiple solutions exist, present only the optimal one unless specifically requested.
14 Describe problem-solving thought processes concisely, omitting unnecessary intermediate steps.
15 Prioritize concrete code examples over complex explanations when applicable.

Guidelines for GitLab Flavored Markdown style:
1. For code blocks formatting:
   - Always use tildes (~) instead of backticks (`) to avoid interference with source code.
   - Always include the programming language name in lowercase at the start (~~~python not ~~~PYTHON).
   - Always include blank lines before and after code blocks.
   - For code blocks containing tildes, use four or more tildes to open and close (~~~~python and ~~~~).
   - Never include line numbers in code blocks.
   - Do not wrap the entire response in triple tildes.

2. For text formatting:
   - Always include blank lines before and after headings (#, ##, etc.).
   - Always include blank lines before each list item.
   - For numbered lists, start each item with "1." to allow automatic numbering.
   - Use consistent indentation with either 2 or 4 spaces.
   - Do not include full-width spaces (　). Replace them with proper indentation or hyphens (-) for lists.

3. For content organization:
   - When quoting source code, clearly indicate it as a quote and consider using blockquote syntax (>).
   - For tables, use at least three hyphens (---) in the separator row and properly align column indicators.
   - Always place an empty line at the end of your response.
]]
                    end,
                },
                adapters = {
                    copilot = configure_adapter_with_model_override('copilot'),
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
                        provider = "mini_diff",
                        opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
                    },
                    chat = {
                        -- show_settings = true,
                        show_keys = true,
                        show_reference_info = true,
                        show_system_messages = true,

                        -- Change the default icons
                        icons = {
                            pinned_buffer = " ",
                            watched_buffer = "👀 ",
                        },

                        -- Alter the sizing of the debug window
                        debug_window = {
                            ---@return number|fun(): number
                            width = vim.o.columns - 5,
                            ---@return number|fun(): number
                            height = vim.o.lines - 2,
                        },

                        -- Options to customize the UI of the chat buffer
                        window = {
                            layout = "vertical", -- float|vertical|horizontal|buffer
                            position = nil,      -- left|right|top|bottom (nil will default depending on vim.opt.plitright|vim.opt.splitbelow)
                            border = "single",
                            height = 0.8,
                            width = 0.45,
                            relative = "editor",
                            opts = {
                                breakindent = true,
                                cursorcolumn = false,
                                cursorline = false,
                                foldcolumn = "0",
                                linebreak = true,
                                list = false,
                                numberwidth = 1,
                                signcolumn = "no",
                                spell = false,
                                wrap = true,
                            },
                        },
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

````diff
%s
````]],
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

````diff
%s
````]],
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
