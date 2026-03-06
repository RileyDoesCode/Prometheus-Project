-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- pipeline.lua
-- Provides configuration presets for Prometheus

return {

    --------------------------------------------------
    -- Minify
    --------------------------------------------------
    ["Minify"] = {
        LuaVersion = "Lua51",
        VarNamePrefix = "",
        NameGenerator = "MangledShuffled",
        PrettyPrint = false,
        Seed = 0,

        Steps = {
        }
    },

    --------------------------------------------------
    -- Weak
    --------------------------------------------------
    ["Weak"] = {
        LuaVersion = "Lua51",
        VarNamePrefix = "",
        NameGenerator = "MangledShuffled",
        PrettyPrint = false,
        Seed = 0,

        Steps = {
            {
                Name = "Vmify",
                Settings = {}
            },
            {
                Name = "ConstantArray",
                Settings = {
                    Treshold = 1,
                    StringsOnly = true
                }
            },
            {
                Name = "WrapInFunction",
                Settings = {}
            }
        }
    },

    --------------------------------------------------
    -- Vmify Only
    --------------------------------------------------
    ["Vmify"] = {
        LuaVersion = "Lua51",
        VarNamePrefix = "",
        NameGenerator = "MangledShuffled",
        PrettyPrint = false,
        Seed = 0,

        Steps = {
            {
                Name = "Vmify",
                Settings = {}
            }
        }
    },

    --------------------------------------------------
    -- Medium
    --------------------------------------------------
    ["Medium"] = {
        LuaVersion = "Lua51",
        VarNamePrefix = "",
        NameGenerator = "MangledShuffled",
        PrettyPrint = false,
        Seed = 0,

        Steps = {
            {
                Name = "EncryptStrings",
                Settings = {}
            },
            {
                Name = "AntiTamper",
                Settings = {
                    UseDebug = false
                }
            },
            {
                Name = "Vmify",
                Settings = {}
            },
            {
                Name = "ConstantArray",
                Settings = {
                    Treshold = 1,
                    StringsOnly = true,
                    Shuffle = true,
                    Rotate = true,
                    LocalWrapperTreshold = 0
                }
            },
            {
                Name = "NumbersToExpressions",
                Settings = {}
            },
            {
                Name = "WrapInFunction",
                Settings = {}
            }
        }
    },

    --------------------------------------------------
    -- Strong
    --------------------------------------------------
    ["Strong"] = {
        LuaVersion = "Lua51",
        VarNamePrefix = "",
        NameGenerator = "MangledShuffled",
        PrettyPrint = false,
        Seed = 0,

        Steps = {
            {
                Name = "Vmify",
                Settings = {}
            },
            {
                Name = "EncryptStrings",
                Settings = {}
            },
            {
                Name = "AntiTamper",
                Settings = {}
            },
            {
                Name = "Vmify",
                Settings = {}
            },
            {
                Name = "ConstantArray",
                Settings = {
                    Treshold = 1,
                    StringsOnly = true,
                    Shuffle = true,
                    Rotate = true,
                    LocalWrapperTreshold = 0
                }
            },
            {
                Name = "NumbersToExpressions",
                Settings = {}
            },
            {
                Name = "WrapInFunction",
                Settings = {}
            }
        }
    }

}
