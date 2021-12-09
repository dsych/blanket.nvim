-- get plugin directory, equivalent to '../' relative to current script
local plugin_path = vim.fn.expand('<sfile>:p:h:h')
-- load plugin
vim.cmd(string.format('set runtimepath+=%s', plugin_path))
-- pass configs
require'blanket'.setup{
    report_path = plugin_path.."/examples/jacoco/target/site/jacoco/jacoco.xml",
    filetypes = "java"
}
