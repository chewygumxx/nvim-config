#!/usr/bin/env lua
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/scripts/genhelp.lua
--
--

--
-- Renders `doc/nvim-config.txt`, the `:help` this configuration answers to,
-- from the configuration itself.
--
-- Usage: `nvim --headless -u scripts/minimal_init.lua
--         -l scripts/genhelp.lua`
--
-- `stdpath("config")` is always first on 'runtimepath', so a `doc/` inside
-- this repository is reachable from `:help` with no plugin and no install
-- step. The one piece of plumbing that needs is `doc/tags`: lazy.nvim runs
-- `helptags` for the plugins it manages and never for the configuration
-- directory, so the tags file is generated here and tracked.
--
-- Nothing here is parsed out of the source. `lua/keymap/init.lua` and
-- `lua/usercmd/init.lua` are imperative, setting their mappings and
-- commands inside `setup()` with the left-hand side and the description as
-- defaulted function parameters, so there is no table to read and reading
-- the `---@param` prose instead would make a second source of truth out of
-- a comment. Each `setup()` is therefore called under a stub of the API it
-- writes through, which is the mechanism `tests/test_keymap.lua`,
-- `tests/test_option.lua` and `tests/test_autocmd.lua` already use to
-- assert the whole set a module registers. Those record only enough to
-- compare against a documented list and discard the descriptions, so this
-- is the same pattern rather than a shared function.
--
-- Plugin mappings are the opposite case and are read statically, the way
-- `tests/test_spec.lua` reads them: a spec's `keys` is plain data. They are
-- filtered against `lua/plugin.lua`'s `elide` and `condemn` lists and
-- against a spec's own `cond`/`enabled`, because a help file advertising a
-- mapping that no longer loads is worse than one that omits it.
--
-- Fail-closed for the reason `scripts/gendoc.lua` is, and against the same
-- two failure modes peculiar to committing generated output: a run that
-- captured nothing would otherwise commit an empty help file over a good
-- one, and a generator that only ever writes would leave a stale `doc/`
-- that `git diff` reports as unchanged. The tree is built in a staging
-- directory, proved to contain what it must, and only then installed.
--

local vimdoc = require("util.vimdoc")

--- Prints msg and exits non-zero.
---
--- `print` rather than `io.stderr`, as in `scripts/gendoc.lua`: selene's
--- `lua51` standard library does not model `io.stderr`'s fields.
---@param msg string
---@return nil
local function fatal(msg)
    print(msg)
    os.exit(1)
end

-- Asserted rather than searched for, as in `scripts/gendoc.lua`: every
-- path below is relative to the invocation directory, and the wrong cwd
-- would present as a generator that found nothing to document
local anchor = ".luarc.json"
if vim.fn.filereadable(anchor) == 0 then
    fatal(
        string.format(
            "run from the repository root: no %s under %s",
            anchor,
            vim.fn.getcwd()
        )
    )
end

--- Renders a value as a single line, for the right column of an entry.
---@param value any
---@return string text
local function scalar(value)
    -- Quoted whenever the bare form would not survive the render: an empty
    -- value would show as nothing at all, and `fillchars=fold: ` would
    -- lose the trailing space that is the whole point of it, since the
    -- renderer trims every line
    if type(value) == "string" then
        if value == "" or value:match("^%s") or value:match("%s$") then
            return vim.inspect(value)
        end
        -- A path under the configuration directory, eg. 'spellfile', is
        -- written as the call that produced it: the absolute form differs
        -- per machine, so CI's regeneration would never match a local one
        local config = vim.fn.stdpath("config")
        if value:sub(1, #config + 1) == config .. "/" then
            return 'stdpath("config")' .. value:sub(#config + 1)
        end
        return value
    end
    local text = vim.inspect(value):gsub("%s+", " ")
    return text
end

--
-- Capture
--

---@class cgxx.genhelp.Captured
---@field keymaps  cgxx.vimdoc.Entry[]
---@field commands cgxx.vimdoc.Entry[]
---@field options  cgxx.vimdoc.Entry[]
---@field autocmds cgxx.vimdoc.Entry[]

--- Calls every top-level `setup()` under a stub of the API it writes
--- through, and returns what each asked for.
---
--- The four stubs are installed together and before the first `require`,
--- because `lua/autocmd.lua` creates its shared augroup at module load
--- rather than inside `setup()`; a stub installed afterwards would miss it
--- and `require`'s cache would not run the file again.
---
--- Each is written with the real arity, for the reason `.claude/rules/tests.md`
--- gives: a narrower stub retypes the field for the whole workspace and
--- makes every genuine call site report `redundant-parameter`.
---@return cgxx.genhelp.Captured captured
local function capture()
    ---@type cgxx.vimdoc.Entry[]
    local keymaps = {}
    ---@type cgxx.vimdoc.Entry[]
    local commands = {}
    ---@type cgxx.vimdoc.Entry[]
    local options = {}
    ---@type cgxx.vimdoc.Entry[]
    local autocmds = {}
    ---@type table<string, true>
    local tags = {}

    local real_keymap  = vim.keymap.set
    local real_usercmd = vim.api.nvim_create_user_command
    local real_option  = vim.api.nvim_set_option_value
    local real_autocmd = vim.api.nvim_create_autocmd

    ---@param mode string | string[]
    ---@param lhs  string
    ---@param _rhs string | function
    ---@param opts vim.keymap.set.Opts?
    ---@return nil
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.keymap.set = function(mode, lhs, _rhs, opts)
        ---@type string[]
        local modes = type(mode) == "table" and mode or { mode }
        table.insert(keymaps, {
            lhs  = table.concat(modes, ",") .. "  " .. lhs,
            desc = opts and opts.desc or nil,
        })
    end

    ---@param name string
    ---@param _cmd string | function
    ---@param opts vim.api.keyset.user_command?
    ---@return nil
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.api.nvim_create_user_command = function(name, _cmd, opts)
        -- `XXWip` -> `nvim-config-wip`, the form a reader would guess.
        -- A collision is fatal rather than skipped: it would mean two
        -- commands and one tag, and `helptags` rejects the duplicate
        local stem = name:gsub("^XX", ""):lower()
        local tag  = "nvim-config-" .. stem
        if tags[tag] then
            fatal("two user commands claim the tag " .. tag)
        end
        tags[tag] = true

        local lhs = ":" .. name
        if opts and opts.bang then
            lhs = lhs .. "[!]"
        end
        if opts and opts.nargs and opts.nargs ~= 0 then
            lhs = lhs .. " {args}"
        end

        table.insert(commands, {
            lhs  = lhs,
            desc = opts and opts.desc or nil,
            tag  = tag,
        })
    end

    ---@param name  string
    ---@param value any
    ---@param _opts vim.api.keyset.option?
    ---@return nil
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.api.nvim_set_option_value = function(name, value, _opts)
        -- Hoisted rather than inlined into the call: `luafmt --verify`
        -- reports the two-argument form here as non-idempotent, laying it
        -- out differently on each pass
        local lhs = "'" .. name .. "'"
        table.insert(options, { lhs = lhs, desc = scalar(value) })
    end

    ---@param event string | string[]
    ---@param opts  vim.api.keyset.create_autocmd?
    ---@return integer id
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.api.nvim_create_autocmd = function(event, opts)
        ---@type string[]
        local events = type(event) == "table" and event or { event }
        table.insert(autocmds, {
            lhs  = table.concat(events, ","),
            desc = opts and opts.desc or nil,
        })
        return 0
    end

    require("option").setup()
    require("keymap").setup()
    require("filetype").setup()
    require("autocmd").setup()
    require("usercmd").setup()

    -- `keymap.gx` defers into `vim.schedule`, so its call lands after
    -- `setup()` has returned and has to be waited for with the stub still
    -- installed, exactly as `tests/test_keymap.lua` waits for it
    local arrived = vim.wait(2000, function()
        for _, entry in ipairs(keymaps) do
            if entry.lhs:sub(-2) == "gx" then
                return true
            end
        end
        return false
    end, 5
    )

    vim.keymap.set                   = real_keymap
    vim.api.nvim_create_user_command = real_usercmd
    vim.api.nvim_set_option_value    = real_option
    vim.api.nvim_create_autocmd      = real_autocmd

    if not arrived then
        fatal("keymap.gx never asked for its mapping; capture is incomplete")
    end

    return {
        keymaps  = keymaps,
        commands = commands,
        options  = options,
        autocmds = autocmds,
    }
end

--
-- Plugin mappings
--

--- Reads every `lua/spec/*.lua`'s `keys` table, skipping any plugin
--- `lua/plugin.lua` switched off and any spec that switched itself off.
---
--- `loadfile` rather than `require`, as in `tests/test_spec.lua`: these
--- filenames carry dots, so `require("spec.mini.test")` would look for
--- `lua/spec/mini/test.lua` and never find them.
---@return cgxx.vimdoc.Entry[] entries
local function plugin_keys()
    local plugin = require("plugin")
    ---@type table<string, true>
    local off = {}
    for _, group in ipairs({ plugin.elide, plugin.condemn }) do
        for _, slug in ipairs(group) do
            off[slug] = true
        end
    end

    ---@type cgxx.vimdoc.Entry[]
    local entries = {}
    ---@type string[]
    local paths = vim.fn.globpath("lua/spec", "*.lua", true, true)

    for _, path in ipairs(paths) do
        local chunk = assert(loadfile(path), path .. " does not parse")
        ---@type table<string | integer, any>
        local spec = chunk()
        -- Annotated rather than inferred, with the runtime check below
        -- standing in for the guarantee: `tests/test_spec.lua` already
        -- asserts every spec names its plugin here
        ---@type string
        local slug = spec[1]
        -- Likewise: lazy.nvim allows `keys` to be a function, which this
        -- generator has no way to evaluate and so treats as absent
        ---@type any[]
        local keys = type(spec.keys) == "table" and spec.keys or {}

        -- A spec may carry its own condition on top of being listed, where
        -- the condition is specific to the plugin rather than a policy
        -- about it; `lua/spec/mkdnflow.lua` is the standing example
        local disabled = type(slug) ~= "string" or off[slug]
            or spec.cond == false or spec.enabled == false

        if not disabled then
            local name = vim.fs.basename(slug)
            for _, key in ipairs(keys) do
                ---@type string?
                local lhs
                ---@type string?
                local desc
                if type(key) == "string" then
                    lhs = key
                elseif type(key) == "table" then
                    lhs  = type(key[1]) == "string" and key[1] or nil
                    desc = type(key.desc) == "string" and key.desc or nil
                end
                -- A key with no right-hand side is a lazy-load trigger
                -- rather than a mapping, and has nothing to document
                if lhs and desc then
                    table.insert(entries, {
                        lhs  = lhs,
                        desc = desc .. "  (" .. name .. ")",
                    })
                end
            end
        end
    end

    return entries
end

--
-- Assemble
--

--- Sorts entries by their left column, so the rendered order is stable
--- across runs rather than following whatever order `setup()` happened to
--- register in. The `Help` gate diffs this output, so a reordering would
--- read as a change.
---@param entries cgxx.vimdoc.Entry[]
---@return cgxx.vimdoc.Entry[] entries Same table, sorted in place
local function sorted(entries)
    table.sort(entries, function(a, b)
        if a.lhs == b.lhs then
            return (a.desc or "") < (b.desc or "")
        end
        return a.lhs < b.lhs
    end)
    return entries
end

local captured = capture()
local plugins  = plugin_keys()

---@type table<string, cgxx.vimdoc.Entry[]>
local harvest = {
    keymaps  = captured.keymaps,
    commands = captured.commands,
    options  = captured.options,
    autocmds = captured.autocmds,
    plugins  = plugins,
}

for name, entries in pairs(harvest) do
    if #entries == 0 then
        fatal("captured no " .. name .. "; treating that as a failed run")
    end
end

---@type cgxx.vimdoc.Section[]
local sections = {
    {
        title   = "KEYMAPS",
        tag     = "nvim-config-keymaps",
        intro   = "Mappings this configuration sets itself, each listed "
            .. "under the modes it applies to.",
        entries = sorted(captured.keymaps),
    },
    {
        title   = "PLUGIN MAPPINGS",
        tag     = "nvim-config-plugin-mappings",
        intro   = "Mappings declared by a plugin spec's `keys`, with the "
            .. "plugin that owns each. Plugins switched off in "
            .. "lua/plugin.lua are omitted.",
        entries = sorted(plugins),
    },
    {
        title   = "COMMANDS",
        tag     = "nvim-config-commands",
        intro   = "User commands, all of them XX-prefixed. A [!] marks a "
            .. "command that takes a bang and {args} one that takes "
            .. "arguments.",
        entries = sorted(captured.commands),
    },
    {
        title   = "OPTIONS",
        tag     = "nvim-config-options",
        intro   = "Every option this configuration sets, with the value it "
            .. "sets.",
        entries = sorted(captured.options),
    },
    {
        title   = "AUTOCOMMANDS",
        tag     = "nvim-config-autocommands",
        intro   = "Autocommands this configuration registers, by event.",
        entries = sorted(captured.autocmds),
    },
}

local lines = vimdoc.render({
    file      = "nvim-config.txt",
    tagline   = "Configuration reference",
    slug      = "chewygumxx/nvim-config",
    path      = ":/doc/nvim-config.txt",
    spdx      = "GPL-3.0-only",
    generator = "scripts/genhelp.lua",
    sections  = sections,
})

--
-- Install
--

local staging = vim.fn.tempname()
local stage   = staging .. "/doc"
if vim.fn.mkdir(stage, "p") == 0 then
    fatal("could not create the staging directory " .. stage)
end

local target = stage .. "/nvim-config.txt"
if vim.fn.writefile(lines, target) ~= 0 then
    fatal("could not write " .. target)
end

-- `helptags` is what proves the output is a help file rather than text
-- shaped like one, and it is the only step that can fail over a malformed
-- tag; running it against the staging copy keeps a bad run out of `doc/`
local ok, err = pcall(vim.cmd.helptags, vim.fn.fnameescape(stage))
if not ok then
    fatal("helptags rejected the generated file: " .. tostring(err))
end

local tagfile = stage .. "/tags"
if vim.fn.filereadable(tagfile) == 0 then
    fatal("helptags wrote no tags file under " .. stage)
end

-- A bare file satisfies the checks above, so one tag that has to exist is
-- named outright: a run that captured nothing cannot produce it
local witness = "nvim-config-commands"
local found   = false
for _, line in ipairs(vim.fn.readfile(tagfile)) do
    if line:sub(1, #witness + 1) == witness .. "\t" then
        found = true
    end
end
if not found then
    fatal("no " .. witness .. " tag in " .. tagfile)
end

if vim.fn.isdirectory("doc") == 1 and vim.fn.delete("doc", "rf") ~= 0 then
    fatal("could not remove the existing doc/ tree")
end
if vim.fn.mkdir("doc", "p") == 0 then
    fatal("could not create doc/")
end

for _, name in ipairs({ "nvim-config.txt", "tags" }) do
    if vim.fn.writefile(vim.fn.readfile(stage .. "/" .. name), "doc/" .. name)
        ~= 0 then
        fatal("could not write doc/" .. name)
    end
end

vim.fn.delete(staging, "rf")

io.write(
    string.format(
        "doc/: %d line(s), %d keymap(s), %d command(s)\n",
        #lines,
        #captured.keymaps + #plugins,
        #captured.commands
    )
)
