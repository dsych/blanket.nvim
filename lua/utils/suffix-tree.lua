local methods = {}

local function mknode()
    return {
        children = {},
        value = nil,
        tombstone = false
    }
end

function methods:set(key, value)
    local cur_node = self.root
    for i = #key, 1, -1 do
        local c = key:sub(i, i)
        local child = cur_node.children[c]
        if child == nil then
            child = mknode()
            cur_node.children[c] = child
        end
        cur_node = child
    end
    cur_node.value = value
    cur_node.tombstone = true
end

function methods:get(key)
    if self.root.children[key:sub(#key, #key)] == nil then
        return nil
    end
    local cur_node = self.root

    for i = #key, 1, -1 do
        local c = key:sub(i, i)
        local child = cur_node.children[c]
        if child == nil then
            break
        end
        cur_node = child
    end

    return cur_node.tombstone and cur_node.value or nil
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
