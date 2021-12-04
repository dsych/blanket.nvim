local M = {}

local xml_converter = require'converters.xml'
local utils = require'utils'

local default_config = {
    prefix_path = "",
    report_path = nil,
    filetypes = nil,
    silent = true,
    signs = {
        priority = 10,
        incomplete_branch = "█",
        uncovered = "█",
        covered = "█",
        sign_group = "Blanket"
    },
}

local parseFile = function()
    M.__cached_report = xml_converter.parse(M.__user_config.report_path)
    M.refresh()
end

M.__cached_report = nil
M.__user_config = {}

M.refresh = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    local stats = M.__cached_report:get(buf_name)
    if stats then
        utils.update_signs(stats,
            M.__user_config.signs.sign_group,
            vim.api.nvim_get_current_buf(),
            M.__user_config.signs.priority
        )
    else
        if not M.__user_config.silent then
            print("unable to locate stats for "..buf_name)
        end
    end
end

M.setup = function(config)
    if config.report_path == nil then
        print("report_path has to be set")
        return
    end

    M.__user_config = vim.tbl_deep_extend("force", default_config, config)
    print(vim.inspect(M.__user_config))

    vim.cmd(string.format([[
        sign define CocCoverageUncovered text=%s texthl=Error
        sign define CocCoverageCovered text=%s texthl=Statement
        sign define CocCoverageMissingBranch text=%s texthl=WarningMsg
    ]], M.__user_config.signs.uncovered, M.__user_config.signs.covered, M.__user_config.signs.incomplete_branch))

    if M.__user_config.filetypes and type(M.__user_config.filetypes) == "string" then
        vim.cmd(string.format([[
            augroup blanket_buf_enter
                autocmd!
                autocmd BufEnter %s :lua require'blanket'.refresh()
            augroup END
        ]], M.__user_config.filetypes))
    end

    parseFile()
end

return M
