local methods = {}

local function mknode()
    return {
        children = {},
        value = nil
    }
end

function methods:set(key, value)
    local cur_node = self.root
    for x = #key, 1, -1 do
        local child = cur_node.children[x]
        if child == nil then
            child = mknode()
            cur_node.children[x] = child
        end
        cur_node = child
    end
    cur_node.value = value
end

function methods:get(key)
    local cur_node = self.root

    for x = #key, 1, -1 do
        local child = cur_node.children[x]
        if child == nil then
            break
        end
        cur_node = child
    end

    -- print(vim.insepect(cur_node))

    return cur_node.value
    -- for x = #key - 1, 1, -1 do
    --     cur_node = cur_node.childred[key[x + 1]]
    --     if cur_node == nil then
    --         print("not found")
    --         return nil
    --     end

    --     local child = cur_node.children[x]
    --     if child == nil then
    --         print("found premature match")
    --         return child.value
    --     end
    --     cur_node = child
    -- end


    -- return cur_node.childer[key[1]].value
end

local function new()
    return setmetatable({
        root = mknode()
    },
    {
        __index = methods
    })
end

return setmetatable({}, {
  __call = new
})
