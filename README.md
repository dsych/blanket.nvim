# BLANKET.NVIM 🛌🏻
> Designed to induce that warm and fuzzy feeling of knowing that your code is covered

# Overview
This plugin provides a code coverage gutter in Neovim based on the Jacoco reports for Java projects.

### Features
* Displaying `uncoverted`, `covered` and `partially covered` (not all code branches are executed) lines
* Watch report for changes and refresh the coverage gutter
* Autocomands to fire when specific file type is opened

![example with all 3 types of signs](./images/coverage_example.png)

# Configurations
Only `report_path` is required, everything else is optional.
```vim

lua << EOF
    require'blanket'.setup{
        -- can use env variables and anything that could be interpreted by expand(), see :h expandcmd()
        -- REQUIRED
        report_path = vim.fn.getcwd().."/target/site/jacoco/jacoco.xml",
        -- refresh gutter every time we enter java file
        -- defauls to empty - no autocmd is created
        filetypes = "*.java",
        -- for debugging purposes to see whether current file is present inside the report
        -- defaults to false
        silent = true,
        -- can set the signs as well
        signs = {
            priority = 10,
            incomplete_branch = "█",
            uncovered = "█",
            covered = "█",
            sign_group = "Blanket"
        },
    }
EOF

```

# Available functions
* `:lua require'blanket'.start()` - start the plugin, useful when `filetype` property is not set
* `:lua require'blanket'.stop()` - stop displaying coverage and cleanup autocmds, watcher etc.
* `:lua require'blanket'.refresh()` - manually trigger a refresh of signs, useful when `filetype` property is not set
* `:lua require'blanket'.set_report_path()` - change `report_path` to a new value and refresh the gutter based on the new report

# Credits
* [xml2lua](https://github.com/manoelcampos/xml2lua) - xml parsing library used to read Jacoco report (found under `lua/internal/*`)
* [jacoco-parse](https://github.com/vokal/jacoco-parse) - inspiration for algo to interpret Jacoco report content



