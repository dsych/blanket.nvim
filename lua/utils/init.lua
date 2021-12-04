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

M.expand_file_path = function(file_path)
    return vim.fn.expandcmd(file_path)
end

M.unset_all_signs = function(sign_group)
    vim.fn.sign_unplace(sign_group)
end

M.unset_signs_in_buf = function(sign_group, buf_id)
    vim.fn.sign_unplace(sign_group, { buffer = buf_id })
end

M.update_signs = function(stats, sign_group, buf_id, sign_priority)
  M.unset_signs_in_buf(sign_group, buf_id)

  M.foreach(stats.lines.details, function(lnum)
    local sign = 'CocCoverageUncovered';
    if lnum.hit > 0 and stats.branches and stats.branches.converted then
      -- could either be missing if no branches at current line or all branches could be taken
      sign = stats.branches.converted[lnum.line] and 'CocCoverageCovered' or 'CocCoverageMissingBranch';
    end

    vim.fn.sign_place(0, sign_group, sign, buf_id, { lnum = lnum.line, priority = sign_priority });
    end);
end

return M
