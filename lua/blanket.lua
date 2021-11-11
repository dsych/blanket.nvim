local M = {}

local xml2lua = require'internal.xml2lua'
local tree_handler = require'internal.xmlhandler.tree'
local xml_parser = xml2lua.parser(tree_handler)
local suffix_tree = require'utils.suffix-tree'

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
local sign_group = "Blanket"

cached_report = nil

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

-- convert a nested table to a flat table
function flatten(t)
    if type(t) ~= 'table' then
        return t
    end

    local res = {}

    for _, v in ipairs(t) do
        if type(v) == 'table' then
            for _, s in ipairs(v) do
                table.insert(res, s)
            end
        else
            table.insert(res, v)
        end
    end
    return res
end

reduce = function(src, f, target)
    for _, v in ipairs(src) do
        target = f(target, v)
    end
    return target
end

concat = function(dest, src)
    for _, v in ipairs(src) do
        table.insert(dest, v)
    end
    return dest
end

some = function(src, f)
    if not src then
        return false
    end

    for _, v in ipairs(src) do
        if f(v) then
            return true
        end
    end
    return false
end

user_config = {}

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

    local output = suffix_tree()

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
                    details = reduce(pack.class, function(result, currentClass)
                        return not currentClass.method and result or concat(result, map(currentClass.method, function(method) -- result.concat
                            local hit = some(method.counter, function (counter)
                                return counter._attr.type == "METHOD" and counter._attr.covered == "1"
                            end)
                            return {
                                name = method._attr and method._attr.name or method.name,
                                line = tonumber(method._attr and method._attr.line or method.line),
                                hit =  hit and 1 or 0
                            }
                        end));
                    end, {})
                },
                lines = {
                    found = tonumber(lines._attr.covered) + tonumber(lines._attr.missed),
                    hit = tonumber(lines._attr.covered),
                    details = not s.line and {} or map(s.line, function (l)
                        return {
                            line = tonumber( l._attr.nr ),
                            hit = tonumber( l._attr.ci )
                        };
                    end)
                },
                classes = {
                    found = tonumber(classes._attr.covered) + tonumber(classes._attr.missed),
                    hit = tonumber(classes._attr.covered),
                },
                branches = {
                    found = tonumber(branches._attr.covered) + tonumber(branches._attr.missed),
                    hit = tonumber(branches._attr.covered),
                    details = not s.line and {} or
                        flatten(map(
                            filter(s.line, function(l)
                                return tonumber( l._attr.mb ) > 0 or tonumber( l._attr.cb ) > 0
                            end),
                            function(l)
                                local br = {}
                                local count = tonumber( l._attr.mb ) + tonumber( l._attr.cb )

                                for i = 1, count do
                                    table.insert(br, {
                                        line = tonumber( l._attr.nr ),
                                        block = 0,
                                        branch = tonumber( i ),
                                        taken =  i < tonumber( l._attr.cb ) and 1 or 0
                                    })
                                end

                                return br
                            end))
                }
            }

            -- print(vim.inspect(classCov))
            output:set(classCov.file, classCov)
        end)

    end)

    return output
end

local parseFile = function()
    local xml_content = xml2lua.loadFile(user_config.reportPath)
    xml_parser:parse(xml_content)
    -- print(vim.inspect(tree_handler.root))
    cached_report = unpackage(tree_handler.root.report[1])
    M.refresh()
end

local unset_all_signs = function(bufnr)
    vim.fn.sign_unplace(sign_group, {buffer = bufnr})
end

local update_signs = function(stats)
    local curr_buf = vim.api.nvim_get_current_buf()
  unset_all_signs(curr_buf)

  foreach(stats.lines.details, function(lnum)
    local sign = 'CocCoverageUncovered';
    if lnum.hit > 0 and stats.branches and stats.branches.converted then
      -- could either be missing if no branches at current line or all branches could be taken
      sign = not stats.branches.converted[lnum.line] and 'CocCoverageCovered' or 'CocCoverageMissingBranch';
    end

    vim.fn.sign_place(0, sign_group, sign, curr_buf, { lnum = lnum.line, priority = user_config.signs.priority });
    end);
end

M.refresh = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    local stats = cached_report:get(buf_name)
    if stats then
        update_signs(stats)
    else
        print("unable to locate stats for "..buf_name)
    end
    -- print(vim.inspect(stats))
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
        user_config['signs'] = default_config.signs
    end

    vim.cmd(string.format([[
        sign define CocCoverageUncovered text=%s texthl=Error
        sign define CocCoverageCovered text=%s texthl=Statement
        sign define CocCoverageMissingBranch text=%s texthl=WarningMsg
    ]], user_config.signs.uncovered, user_config.signs.covered, user_config.signs.incompleteBranch))
    -- vim.cmd([[
    --     augroup blanket_buf_enter
    --         autocmd!
    --         autocmd BufEnter * :lua require'blanket'.refresh()
    --     augroup END
    -- ]])

    parseFile()
end


return M
