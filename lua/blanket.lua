local M = {}

local xml_converter = require'converters.xml'
local utils = require'utils'

local default_config = {
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

local buf_enter_ag = "buf_enter_auto_group"
local is_loaded = false
local file_watcher = vim.loop.new_fs_event()

ParseFile = function()
    file_watcher:stop()
    M.__cached_report = xml_converter.parse(M.__user_config.report_path)

    file_watcher:start(M.__user_config.report_path, {}, vim.schedule_wrap(utils.debounce(
        ParseFile, 1000)
    ))
end

local register_buf_enter_ag = function()
    if M.__user_config.filetypes and type(M.__user_config.filetypes) == "string" then
        vim.cmd(string.format([[
            augroup %s
                autocmd!
                autocmd FileType %s :lua require'blanket'.refresh()
            augroup END
        ]], buf_enter_ag, M.__user_config.filetypes))
    end
end

M.__cached_report = nil
M.__user_config = {}

M.refresh = function()
    if not is_loaded then
        print("please call setup")
        return
    end

    if M.__cached_report == nil then
        ParseFile()
    end

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

M.start = function()
    M.refresh()
    register_buf_enter_ag()
end

M.stop = function()
    utils.unset_all_signs(M.__user_config.signs.sign_group)
    file_watcher:stop()
    vim.cmd(string.format([[
        augroup %s
            autocmd!
        augroup END
    ]], buf_enter_ag))
end

M.set_report_path = function()
    if not is_loaded then
        print("please call setup")
        return
    end

    vim.ui.input({ prompt = "New report_path: ", completion = "file", default = M.__user_config.report_path },
        function(user_input)
            if user_input then
                M.__user_config.report_path = utils.expand_file_path(user_input)
                ParseFile()
            end

        end
    )
end

M.setup = function(config)
    if is_loaded then
        return
    end

    if config.report_path == nil then
        print("report_path has to be set")
        return
    end

    is_loaded = true

    M.__user_config = vim.tbl_deep_extend("force", default_config, config)
    M.__user_config.report_path = utils.expand_file_path(M.__user_config.report_path)

    if not M.__user_config.silent then
        print(vim.inspect(M.__user_config))
    end

    vim.cmd(string.format([[
        sign define CocCoverageUncovered text=%s texthl=Error
        sign define CocCoverageCovered text=%s texthl=Statement
        sign define CocCoverageMissingBranch text=%s texthl=WarningMsg
    ]], M.__user_config.signs.uncovered, M.__user_config.signs.covered, M.__user_config.signs.incomplete_branch))

    register_buf_enter_ag()
end

return M
