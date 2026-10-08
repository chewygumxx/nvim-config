#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/util/frontmatter.lua
--
--

--
-- Keeps a Markdown document's header true on every save: the frontmatter's
-- `title:` follows the first heading, `mtime:` the date of the save, the
-- HTML comment box the file's repository and path, and a `description:`
-- too long or too awkward for one line of YAML is folded.
--
-- The header is the one `util.header.frontmatter` renders, and this module
-- re-renders its parts through the same functions rather than restating
-- the format. A document is only touched when it already carries that
-- header, ie. opens on `---` with a `ctime:` key, so frontmatter some other
-- tool owns is left alone.
--

local M = {}

local util_header = require("util.header")
local util_text   = require("util.text")
local md_format   = require("util.markdown_format")

--- How far down a document the closing `---` is looked for. Frontmatter
--- that runs longer than this is not a header this module wrote.
---@type integer
local frontmatter_limit = 200

--- The 1-indexed line of the `---` that closes lines' frontmatter, if
--- lines open on one and carry a `ctime:` key inside it.
---@param lines string[]
---@return integer? close
M.close = function(lines)
    if lines[1] ~= "---" then
        return nil
    end
    ---@type boolean
    local dated = false
    for lnum = 2, math.min(#lines, frontmatter_limit) do
        if lines[lnum] == "---" then
            return dated and lnum or nil
        end
        if lines[lnum]:match("^ctime:") then
            dated = true
        end
    end
    return nil
end

--- The text of the first ATX level-one heading outside every protected
--- block, ie. not in a fence, frontmatter or HTML comment.
---@param lines  string[]
---@param ranges cgxx.markdown_format.Range[] From `util.markdown_format.protected`
---@return string? title
M.heading = function(lines, ranges)
    for lnum, line in ipairs(lines) do
        local text = line:match("^#%s+(.-)%s*$")
        if text then
            ---@type boolean
            local protected = false
            for _, range in ipairs(ranges) do
                if lnum >= range.first and lnum <= range.last then
                    protected = true
                    break
                end
            end
            if not protected then
                -- A closing run of `#` is decoration, not part of the text
                ---@type string
                local stripped = text:gsub("%s+#+$", "")
                return stripped ~= "" and stripped or nil
            end
        end
    end
    return nil
end

--- A single-line YAML scalar's value, unquoted, or nil for anything
--- spanning more than one line or not a scalar at all.
---@param value string Everything after `key: `
---@return string? text
M.unquote = function(value)
    if value == "" or value:match("^[>|]") or value:match("^[%[{]") then
        return nil
    end
    local double = value:match('^"(.*)"$')
    if double then
        ---@type string
        local text = double:gsub('\\"', '"'):gsub("\\\\", "\\")
        return text
    end
    local single = value:match("^'(.*)'$")
    if single then
        ---@type string
        local text = single:gsub("''", "'")
        return text
    end
    return value
end

--- The header lines a save should leave, given the lines it has now.
---
--- Returns the replacement for lines 1 through `last`, where `last` is the
--- end of the repository box if one directly follows the frontmatter, and
--- the frontmatter's own close otherwise.
---@param lines    string[]
---@param close    integer                      From `M.close`
---@param ranges   cgxx.markdown_format.Range[]
---@param location util.HeaderLocation?         Box to write, if known
---@param today    string                       YYYY-MM-DD
---@return string[] header
---@return integer last
M.sync = function(lines, close, ranges, location, today)
    ---@type string[]
    local header = {}
    ---@type integer?
    local ctime
    ---@type boolean
    local has_mtime = false
    local title     = M.heading(lines, ranges)

    local lnum = 1
    while lnum <= close do
        local line = lines[lnum]
        if line:match("^ctime:") then
            ctime = #header + 1
        end

        if line:match("^mtime:") then
            has_mtime           = true
            header[#header + 1] = "mtime: " .. today
        elseif line:match("^title:") and title then
            header[#header + 1] = "title: " .. util_text.yaml_scalar(title)
        elseif line:match("^description: ") then
            local text = M.unquote(line:match("^description: (.*)$"))
            if text then
                vim.list_extend(header, util_header.description(text))
            else
                header[#header + 1] = line
            end
        else
            header[#header + 1] = line
        end
        lnum = lnum + 1
    end

    if not has_mtime and ctime then
        table.insert(header, ctime + 1, "mtime: " .. today)
    end

    -- The box, when one sits directly beneath the frontmatter
    local box_open = close + 1
    while lines[box_open] == "" do
        box_open = box_open + 1
    end
    if lines[box_open] ~= "<!--" or location == nil then
        return header, close
    end
    local box_close = box_open
    while lines[box_close] and not lines[box_close]:match("%-%->%s*$") do
        box_close = box_close + 1
    end
    if lines[box_close] == nil then
        return header, close
    end

    for index = close + 1, box_open - 1 do
        header[#header + 1] = lines[index]
    end
    vim.list_extend(
        header,
        util_header.box(location.slug, location.fork_slug, location.path)
    )
    return header, box_close
end

--- Re-renders buf's header in place, if it has one, as one undo step with
--- whatever change is being saved.
---@param buf integer
---@return nil
M.apply = function(buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local close = M.close(lines)
    if close == nil then
        return
    end

    local name = vim.api.nvim_buf_get_name(buf)
    ---@type util.HeaderLocation?
    local location
    if name ~= "" then
        location = util_header.located(buf, name)
    end

    local header, last = M.sync(
        lines,
        close,
        md_format.protected(buf),
        location,
        tostring(os.date("%Y-%m-%d"))
    )
    if vim.deep_equal(header, vim.list_slice(lines, 1, last)) then
        return
    end

    vim.api.nvim_buf_call(buf, function()
        pcall(vim.cmd.undojoin)
    end)
    vim.api.nvim_buf_set_lines(buf, 0, last, false, header)
end

--- Registers the `BufWritePre` autocmd that runs `M.apply` on a modified
--- Markdown buffer, compound filetypes included.
---@return nil
M.autocmd = function()
    vim.api.nvim_create_autocmd("BufWritePre", {
        desc     = "Sync a Markdown header's title, mtime and box on save",
        group    = vim.api.nvim_create_augroup("cgxx.frontmatter", {
            clear = true,
        }),
        callback = function(event)
            local filetype = vim.bo[event.buf].filetype
            if vim.split(filetype, ".", { plain = true })[1] ~= "markdown"
                or not vim.bo[event.buf].modified then
                return
            end
            M.apply(event.buf)
        end,
    })
end

return M
