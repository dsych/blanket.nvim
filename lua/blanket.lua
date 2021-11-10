local M = {}

local xml2lua = require'internal.xml2lua'
local tree_handler = require'internal.xmlhandler.tree'
local xml_parser = xml2lua.parser(tree_handler)

local default_config = {
    prefixPath = "",
    reportPath = nil,
    signs = {
        priority = 10,
        incompleteBranch = "█",
        uncovered = "█",
        covered = "█"
    },
}

function filter(tbl, f)
    local t = {}
    for _,v in pairs(tbl) do
        if f(v) then
            table.insert(t, v)
        end
    end
    return t
end

function map(tbl, f)
    local t = {}
    for k,v in pairs(tbl) do
        t[k] = f(v)
    end
    return t
end

function foreach(tbl, f)
    for _,v in pairs(tbl) do
        f(v)
    end
end

local user_config = {}

local function getCounter(source, type)
    source.counter = source.counter or {};

    local f = filter(source.counter, function (counter)
        return counter._attr.type == type;
    end)

    return f[1] or {
            _attr = {
                covered = 0,
                missed = 0
            }
    };
end

local unpackage = function (report)
    local packages = report.package

    local output = {}

    foreach(packages, function (pack)
        foreach(pack.sourcefile, function (s)
            local fullPath = pack._attr.name .. '/' .. s._attr.name

            local methods = getCounter(s, "METHOD")
            local lines = getCounter(s, "LINE")
            local branches = getCounter(s, "BRANCH")
            local classes = getCounter(s, "CLASS")

            local classCov = {
                title = s._attr.name,
                file = fullPath,
                functions = {
                    found = tonumber(methods._attr.covered) + tonumber(methods._attr.missed),
                    hit = tonumber(methods._attr.covered),
                },
                lines = {
                    found = tonumber(lines._attr.covered) + tonumber(lines._attr.missed),
                    hit = tonumber(lines._attr.covered),
                    details = {
                        cov = not s.line and {} or map(s.line, function (l) return tonumber(l._attr.nr) end),
                        uncov = not s.line and {} or map(s.line, function (l) return tonumber(l._attr.ci) end),
                    }
                },
                classes = {
                    found = tonumber(classes._attr.covered) + tonumber(classes._attr.missed),
                    hit = tonumber(classes._attr.covered),
                },
                branches = {
                    found = tonumber(branches._attr.covered) + tonumber(branches._attr.missed),
                    hit = tonumber(branches._attr.covered)
                }
            }
            output[classCov.file] = classCov
        end)

    end)

    return output
end

M.refresh = function()
    local xml_content = xml2lua.loadFile(user_config.reportPath)
    xml_parser:parse(xml_content)
    local converted = unpackage(tree_handler.root.report[1])
end


M.setup = function(config)
    if config.reportPath == nil then
        print("reportPath has to be set")
        return
    end

    user_config.reportPath = config.reportPath
    user_config.prefixPath = config.prefixPath or default_config.prefixPath
    if config.signs then
        user_config.signs.priority = config.signs.priority or default_config.signs.priority
        user_config.signs.incompleteBranch = config.signs.incompleteBranch or default_config.signs.incompleteBranch
        user_config.signs.uncovered = config.signs.uncovered or default_config.signs.uncovered
        user_config.signs.covered = config.signs.covered or default_config.signs.covered
    else
        user_config.signs = default_config.sings
    end

    M.refresh()
end


return M
