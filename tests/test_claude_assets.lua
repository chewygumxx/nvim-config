#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/tests/test_claude_assets.lua
--
--

--
-- The `.claude/` assets, checked against the tree they describe.
--
-- `.claude/CLAUDE.md` and the skills beside it are prose, so nothing can
-- check that what they say is true. What can be checked is that the files
-- they name still exist, which is the drift that actually happens: a
-- module is renamed and six paragraphs keep naming the old path.
--
-- The extraction rule below is narrower than the obvious one, and
-- deliberately. Every backticked token ending in a file extension gives
-- 130 candidates here of which 53 do not resolve, and none of those 53 is
-- drift: they are bare basenames used in running prose (`statusline.lua`,
-- `test_keymap.lua`) where the surrounding sentence already established
-- the directory. Requiring a separator and a real top-level root cuts that
-- to 66 assertions with four false positives, which are registered below.
-- A checker built on the obvious rule would have cried wolf 53 times and
-- been switched off within a week.
--
-- `.husky/pre-commit` does not run the suite for a `.claude/`-only commit,
-- and that is the right call rather than an oversight. The drift this
-- catches is a rename under `lua/`, which already triggers the suite, so
-- the expensive case is covered while the repository's granular commit
-- convention pays nothing. CI runs the suite on every push regardless,
-- which is what catches a bad path introduced by a `.claude/`-only commit.
--

local eq = require("mini.test") --[[@as mini.test]]
    .expect
    .equality

--- Tokens that look like repository paths, are rooted like repository
--- paths, and deliberately name nothing.
---
--- A reason rather than a bare list, for the reason
--- `tests/test_coverage.lua`'s `exempt` table gives: "this one does not
--- have to exist" is a decision, and the next reader deserves to know
--- which decision it was.
---@type table<string, string>
local not_a_path = {
    ["lua/plugin_manager.lua"] = "named as a thing that was removed, in "
        .. "the passage explaining that there is no indirection layer",
    ["lua/spec/lazy.nvim.lua"] = "the spec that would pin lazy.nvim's own "
        .. "branch, considered and deliberately not written",
}

--- Every Markdown asset under `.claude/`.
---@return string[] paths
local assets = function()
    ---@type string[]
    local found = vim.fn.globpath(".claude", "**/*.md", true, true)
    table.sort(found)
    return found
end

--- Whether a repository-relative path names something that is there.
---
--- Directories count, since the prose names `queries/` and `lua/spec/` as
--- readily as it names a file, and `doc/tags` is a file with no extension.
---@param path string
---@return boolean exists
local present = function(path)
    return vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
end

--- The backticked tokens in a file that name repository paths, resolved.
---
--- Rooted means the first segment is a directory that exists at the
--- repository root, which is what separates `lua/util/git.lua` from the
--- bare `git.lua` that prose uses once the directory is established, and
--- from `$VIMRUNTIME/ftplugin/markdown.vim` or `~/.local/share/cargo/bin`.
--- Globs and angle-bracket placeholders are dropped, since neither names
--- one file.
---
--- An asset also writes paths relative to `.claude/` itself, ie.
--- `hooks/lib/tools.sh` rather than `.claude/hooks/lib/tools.sh`, so that
--- root is tried second and the token is returned resolved. Without it
--- every such reference is invisible here, which was found by moving the
--- file out of the way and watching this pass regardless.
---@param path string Repository-relative path of the asset to read
---@return string[] paths Sorted, deduplicated, repository-relative
local referenced = function(path)
    local text = table.concat(vim.fn.readfile(path), "\n")

    ---@type table<string, boolean>
    local seen = {}
    for token in text:gmatch("`([^`\n]+)`") do
        local root = token:match("^([^/]+)/")
        if root ~= nil and not token:find("[*<>%s]") then
            if vim.fn.isdirectory(root) == 1 then
                seen[token] = true
            elseif vim.fn.isdirectory(".claude/" .. root) == 1 then
                seen[".claude/" .. token] = true
            end
        end
    end

    ---@type string[]
    local paths = {}
    for token in pairs(seen) do
        table.insert(paths, token)
    end
    table.sort(paths)
    return paths
end

--- The frontmatter block of a Markdown file, as lines.
---@param path string
---@return string[] lines Empty when the file opens with no `---` fence
local frontmatter = function(path)
    local lines = vim.fn.readfile(path)
    if lines[1] ~= "---" then
        return {}
    end

    ---@type string[]
    local block = {}
    for index = 2, #lines do
        if lines[index] == "---" then
            return block
        end
        table.insert(block, lines[index])
    end
    return {}
end

--- The name an asset's frontmatter has to declare, if any.
---
--- A skill is named by its directory and an agent by its filename stem,
--- because that is what each loader keys on, so a mismatch is a file that
--- quietly answers to something other than what it is filed under. A
--- command declares no name at all: its filename is the slash command.
---@param path string Repository-relative path of the asset
---@return string? name `nil` when the asset declares none
local declares = function(path)
    return path:match("^%.claude/skills/([^/]+)/SKILL%.md$")
        or path:match("^%.claude/agents/([^/]+)%.md$")
end

--- One hook entry inside `.claude/settings.json`.
---
--- Declared as a class rather than written inline, because a multi-line
--- `---@type` table shape is re-indented differently on each `luafmt`
--- pass and reported as "formatting is not idempotent".
---@class cgxx.test.ClaudeHook
---@field command string

--- One matcher group, holding the hooks that fire for it.
---@class cgxx.test.ClaudeHookMatcher
---@field hooks cgxx.test.ClaudeHook[]

describe("claude assets", function()
    ---@type string[]
    local files = assets()

    ---@type string[]
    local skills = vim.fn.globpath(".claude/skills", "*/SKILL.md", true, true)
    table.sort(skills)

    ---@type string[]
    local commands = vim.fn.globpath(".claude/commands", "*.md", true, true)
    table.sort(commands)

    ---@type string[]
    local agents = vim.fn.globpath(".claude/agents", "*.md", true, true)
    table.sort(agents)

    -- Rules are kept out of `described` below on purpose: `paths` is the
    -- only field Claude Code reads from one, so a rule declares neither a
    -- name nor a description and the cases for those would be asserting a
    -- convention nothing loads.
    ---@type string[]
    local rules = vim.fn.globpath(".claude/rules", "*.md", true, true)
    table.sort(rules)

    -- Every asset carrying frontmatter. All three kinds are checked, not
    -- the skills alone: a command or an agent whose description drifted
    -- back to a bare `description:` would break only once somebody later
    -- wrote a colon-space into it, which is the quietest possible failure.
    ---@type string[]
    local described = {}
    for _, group in ipairs({ skills, commands, agents }) do
        for _, path in ipairs(group) do
            table.insert(described, path)
        end
    end
    table.sort(described)

    it("finds the asset files", function()
        -- The generated cases below cannot fail over an empty list, and
        -- each kind is counted separately so a glob that stopped matching
        -- one of them cannot hide behind the other two
        eq({
            #files > 8,
            #skills > 0,
            #commands > 0,
            #agents > 0,
            #rules > 0,
        }, { true, true, true, true, true })
    end)

    -- A command and a skill share one name namespace, Claude Code listing
    -- the first by its filename stem and the second by its directory, so
    -- a collision leaves exactly one of the pair reachable and reports
    -- nothing about the other. That is not hypothetical: the command now
    -- filed as `gate-battery.md` was written as `gates.md` and shadowed
    -- by `.claude/skills/gates/` from that day, unreachable for as long
    -- as `.claude/CLAUDE.md` described it as the way to run the battery.
    -- The three groups above are each checked independently, which is
    -- exactly why every case passed over it. Agents are left out on
    -- purpose, being chosen by `subagent_type` rather than by slash.
    it("gives every command a name no skill claims", function()
        local skill_pat = "^%.claude/skills/([^/]+)/SKILL%.md$"
        local cmd_pat   = "^%.claude/commands/(.+)%.md$"

        ---@type table<string, boolean>
        local claimed = {}
        for _, path in ipairs(skills) do
            claimed[assert(path:match(skill_pat), path)] = true
        end

        ---@type string[]
        local shadowed = {}
        for _, path in ipairs(commands) do
            local name = assert(path:match(cmd_pat), path)
            if claimed[name] then
                table.insert(shadowed, name)
            end
        end

        eq(shadowed, {})
    end)

    for _, path in ipairs(files) do
        it(path .. " names only paths that exist", function()
            ---@type string[]
            local missing = {}
            for _, token in ipairs(referenced(path)) do
                if not present(token) and not not_a_path[token] then
                    table.insert(missing, token)
                end
            end
            eq({ path, missing }, { path, {} })
        end)
    end

    it("checks a meaningful number of paths", function()
        -- Guards the extraction rule itself. A pattern change that
        -- silently matched nothing would leave every case above passing
        -- over an empty list, which is the failure this suite's runner is
        -- written to refuse elsewhere for the same reason.
        ---@type table<string, boolean>
        local union = {}
        for _, path in ipairs(files) do
            for _, token in ipairs(referenced(path)) do
                union[token] = true
            end
        end

        ---@type number
        local total = 0
        for _ in pairs(union) do
            total = total + 1
        end
        eq(total > 40, true)
    end)

    it("registers no exclusion that is now a real path", function()
        -- An entry outliving its reason is the way this registry rots: the
        -- file gets created, the exclusion keeps suppressing a check that
        -- would now pass, and nothing says so.
        ---@type string[]
        local resurrected = {}
        for token in pairs(not_a_path) do
            if present(token) then
                table.insert(resurrected, token)
            end
        end
        table.sort(resurrected)
        eq(resurrected, {})
    end)

    it("registers no exclusion nothing mentions", function()
        -- The other direction: prose is deleted, the entry stays, and the
        -- registry slowly fills with names that mean nothing.
        ---@type table<string, boolean>
        local union = {}
        for _, path in ipairs(files) do
            for _, token in ipairs(referenced(path)) do
                union[token] = true
            end
        end

        ---@type string[]
        local orphaned = {}
        for token, reason in pairs(not_a_path) do
            if not union[token] or #reason == 0 then
                table.insert(orphaned, token)
            end
        end
        table.sort(orphaned)
        eq(orphaned, {})
    end)

    for _, path in ipairs(described) do
        local name = declares(path)

        if name then
            it(path .. " declares the name it is filed under", function()
                ---@type string?
                local declared
                for _, line in ipairs(frontmatter(path)) do
                    declared = declared or line:match("^name:%s*(%S+)%s*$")
                end
                eq({ path, declared }, { path, name })
            end)
        end

        it(path .. " folds its description with >-", function()
            -- A bare `description:` is what the reflow hook turns into a
            -- plain multiline scalar, which is valid YAML that cannot
            -- contain ": ". `>-` folds to the same single line and
            -- tolerates a colon anywhere. Established by probe.
            ---@type boolean
            local folded = false
            for _, line in ipairs(frontmatter(path)) do
                folded = folded or line:match("^description:%s*>%-%s*$") ~= nil
            end
            eq({ path, folded }, { path, true })
        end)
    end

    for _, path in ipairs(rules) do
        it(path .. " scopes itself with paths:", function()
            -- `paths` is the only field Claude Code reads from a rule and
            -- every other is ignored without an error, so the singular
            -- `path:` does not fail: it yields a rule with no `paths` at
            -- all, and a rule with no `paths` loads at launch with the
            -- same priority as `.claude/CLAUDE.md`. The typo therefore
            -- reads as the feature working while doing the opposite of
            -- what it says. Both directions are asserted because a rule
            -- that lost its `paths` in an edit is indistinguishable from
            -- outside: the only symptom either way is a rule arriving in
            -- a session that should never have seen it.
            ---@type boolean
            local scoped = false
            ---@type boolean
            local singular = false
            for _, line in ipairs(frontmatter(path)) do
                scoped   = scoped or line:match("^paths:") ~= nil
                singular = singular or line:match("^path:") ~= nil
            end
            eq({ path, scoped, singular }, { path, true, false })
        end)
    end

    it("wires every hook to a file that can run", function()
        ---@type string
        local raw = table.concat(vim.fn.readfile(".claude/settings.json"), "\n")
        ---@type table<string, any>
        local settings = vim.json.decode(raw)
        ---@type table<string, cgxx.test.ClaudeHookMatcher[]>
        local hooks = settings.hooks

        ---@type string[]
        local wired = {}
        for _, matchers in pairs(hooks) do
            for _, matcher in ipairs(matchers) do
                for _, hook in ipairs(matcher.hooks) do
                    table.insert(wired, hook.command)
                end
            end
        end

        ---@type string[]
        local broken = {}
        for _, command in ipairs(wired) do
            local path = command:gsub("%${CLAUDE_PROJECT_DIR}", vim.fn.getcwd())
            if vim.fn.executable(path) ~= 1 then
                table.insert(broken, command)
            end
        end
        table.sort(broken)

        -- Asserted together so an empty hook table cannot pass as "nothing
        -- broken", which is how this check would quietly stop meaning
        -- anything if the settings shape ever changed
        eq({ #wired > 0, broken }, { true, {} })
    end)

    it("points at every skill, and at no skill that is gone", function()
        -- Whitespace-normalised because the reflow hook wraps freely, so
        -- "`generated-output` skill" is routinely split across two lines
        ---@type string
        local prose = table
            .concat(vim.fn.readfile(".claude/CLAUDE.md"), " ")
            :gsub("%s+", " ")

        ---@type string[]
        local unpointed = {}
        for _, path in ipairs(skills) do
            local name = assert(
                path:match("^%.claude/skills/([^/]+)/SKILL%.md$"),
                "unexpected skill path: " .. path
            )
            if not prose:find("`" .. name .. "` skill", 1, true) then
                table.insert(unpointed, name)
            end
        end
        table.sort(unpointed)

        ---@type string[]
        local dangling = {}
        for name in prose:gmatch("`([a-z-]+)` skill") do
            local skill = ".claude/skills/" .. name .. "/SKILL.md"
            if vim.fn.filereadable(skill) == 0 then
                table.insert(dangling, name)
            end
        end
        table.sort(dangling)

        eq({ unpointed, dangling }, { {}, {} })
    end)
end)
