local utils = require'utils'

local xml2lua = require'internal.xml2lua'
local tree_handler = require'internal.xmlhandler.tree'
-- dont flatten single element vectors of tags
tree_handler.options.noreduce = true
local xml_parser = xml2lua.parser(tree_handler)
local suffix_tree = require'utils.suffix-tree'

local getCounter = function(source, type)
    source.counter = source.counter or {};

    local f = utils.filter(source.counter, function (counter)
        return counter._attr.type == type;
    end)

    return f[1] or {
            _attr = {
                covered = 0,
                missed = 0
            }
    };
end

local unpackage = function(report)
    local packages = report.package

    local output = suffix_tree()

    utils.foreach(packages, function (pack)
        utils.foreach(pack.sourcefile, function (s)
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
                    details = utils.reduce(pack.class, function(result, currentClass)
                        return not currentClass.method and result or utils.concat(result, utils.map(currentClass.method, function(method) -- result.concat
                            local hit = utils.some(method.counter, function (counter)
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
                    details = not s.line and {} or utils.map(s.line, function (l)
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
                        utils.flatten(utils.map(
                            utils.filter(s.line, function(l)
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
                                        taken =  i < tonumber( l._attr.cb )
                                    })
                                end

                                return br
                            end))
                }
            }

            classCov.branches.converted = {}
            utils.foreach(classCov.branches.details, function(b)
                if classCov.branches.converted[b.line] == nil then
                    classCov.branches.converted[b.line] = true;
                end

                classCov.branches.converted[b.line] = classCov.branches.converted[b.line] and b.taken;
            end)

            -- print(vim.inspect(classCov))
            output:set(classCov.file, classCov)
        end)

    end)

    return output
end

local parse = function(file_path)
  local xml_content = xml2lua.loadFile(file_path)
  xml_parser:parse(xml_content)
  return unpackage(tree_handler.root.report[1])
end

return {
    parse = parse,
}
