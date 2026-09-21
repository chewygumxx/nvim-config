#!/bin/false
-- vim: expandtab:shiftwidth=4:filetype=lua:
-- vim: foldmethod=manual:

--
--
-- ~chewygumxx/nvim-config.git
-- ::: :/lua/snippet/header/markdown.lua
--
--

--
-- LuaSnip snippet for markdown header
--

---@module "luasnip"

local ls  = require("luasnip")
local s   = ls.snippet
local t   = ls.text_node
local i   = ls.insert_node
local f   = ls.function_node
local rep = require("luasnip.extras").rep

local git = require("util.git")
---@return string?
local slug = function()
    return git.slug()
end
---@return string
local path = function()
    return git.path()
end

local modeline = require("util.modeline").base({
    et = true,
    sw = 2,
    ft = "markdown",
    commentstring = "# %s",
})
---@return string
local date = function()
    return os.date("%Y-%m-%d") --[[@as string]]
end

---@type LuaSnip.Snippet
local M = s("header/markdown", {
    t({
        "---",
        modeline, -- Static, should not be a function node
        "",
        "#",
        "#",
        "",
    }),
    t({ "# ~" }),
    f(slug, {}),
    t({ ".git", "" }),
    t({ "# ::: " }),
    f(path, {}),
    t({ "", "" }),
    t({
        "#",
        "#",
        "",
        "#",
        "#",
    }),
    i(1, "Description"),
    t({
        "",
        "#",
        "",
        "ctime: ",
    }),
    f(date, {}),
    t({
        "",
        "title: ",
    }),
    i(2, "The Philosophy of Labels"),
    t({
        "",
        "tags:  [ ",
    }),
    i(3, "yeet, ya/boi"),
    t({
        " ]",
        "---",
        "",
        "# ",
    }),
    rep(2),
    t({
        "",
        "",
        "",
    }),
    i(0),
})

return M
