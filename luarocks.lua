-- LuaRocks configuration and dependency management
package = "lua-scripts-monorepo"
version = "1.0-1"
source = {
   url = "git://github.com/sawyer/lua-scripts"
}
description = {
   summary = "Comprehensive Lua scripting monorepo",
   detailed = [[
      A collection of Lua scripts, CLI tools, TUI applications, and utilities
      built with the modern Lua tech stack including LuaJIT, argparse, LTUI,
      LuaFileSystem, json.lua, LuaSocket, and lume.
   ]],
   homepage = "https://github.com/sawyer/lua-scripts",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1",
   "luafilesystem",
   "luasocket",
   "argparse",
   "lua-cliargs"
}
build = {
   type = "builtin",
   modules = {
      ["libs.shared.utils"] = "libs/shared/utils.lua",
      ["libs.shared.config"] = "libs/shared/config.lua",
      ["libs.shared.logger"] = "libs/shared/logger.lua",
   }
}