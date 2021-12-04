local M = {}

M.filter = function(tbl, f)
    local t = {}
    for _,v in pairs(tbl) do
        if f(v) then
            table.insert(t, v)
        end
    end
    return t
end

M.map = function(tbl, f)
    local t = {}
    for k,v in pairs(tbl) do
        t[k] = f(v)
    end
    return t
end

M.foreach = function(tbl, f)
    for _,v in pairs(tbl) do
        f(v)
    end
end

-- convert a nested table to a flat table
M.flatten = function(t)
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

M.reduce = function(src, f, target)
    for _, v in ipairs(src) do
        target = f(target, v)
    end
    return target
end

M.concat = function(dest, src)
    for _, v in ipairs(src) do
        table.insert(dest, v)
    end
    return dest
end

M.some = function(src, f)
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

return M
