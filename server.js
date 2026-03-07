const express = require("express");
const { spawn } = require("child_process");
const fs = require("fs").promises;
const os = require("os");
const path = require("path");
const crypto = require("crypto");
const cors = require("cors");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: "50mb" }));
app.use(express.static("public"));

async function obfuscateLua(code, preset, platform) {
    const id = crypto.randomUUID();
    const tmpDir = os.tmpdir();
    
    const inputFile = path.join(tmpDir, `temp_${id}.lua`);
    const outputFile = path.join(tmpDir, `temp_${id}.obfuscated.lua`);

    await fs.writeFile(inputFile, code, "utf8");

    return new Promise((resolve, reject) => {
        const cliPath = path.join(__dirname, "Prometheus", "cli.lua");
        const args = [cliPath];

        if (platform === "LuaU") args.push("--LuaU");
        else args.push("--Lua51");

        args.push("--preset", preset || "Medium");
        args.push("--nocolors");
        args.push(inputFile);

        const luaProcess = spawn("lua5.1", args, {
            cwd: __dirname,
            timeout: 15000 
        });

        let stdout = "";
        let stderr = "";

        luaProcess.stdout.on("data", (d) => stdout += d.toString());
        luaProcess.stderr.on("data", (d) => stderr += d.toString());

        luaProcess.on("error", (err) => {
            reject(new Error(`Failed to start Lua process: ${err.message}`));
        });

        luaProcess.on("close", async () => {
            try {
                const result = await fs.readFile(outputFile, "utf8");
                resolve(result);
            } catch (err) {
                reject(new Error(stderr || stdout || "Unknown obfuscation error."));
            } finally {
                fs.unlink(inputFile).catch(() => {});
                fs.unlink(outputFile).catch(() => {});
            }
        });
    });
}

app.post("/obfuscate", async (req, res) => {
    try {
        const { code, preset, platform } = req.body;

        if (!code || typeof code !== "string" || code.trim() === "") {
            return res.status(400).json({ error: "Invalid or empty Lua code provided." });
        }

        const obfuscatedCode = await obfuscateLua(code, preset, platform);

        return res.json({ result: obfuscatedCode });

    } catch (err) {
        console.error("[Obfuscator Error]:", err.message);
        return res.status(500).json({
            error: "Obfuscation failed",
            details: err.message
        });
    }
});

setInterval(async () => {
    try {
        const tmpDir = os.tmpdir();
        const files = await fs.readdir(tmpDir);
        const now = Date.now();
        const THREE_HOURS = 3 * 60 * 60 * 1000;

        for (const file of files) {
            if (file.startsWith("temp_") && file.endsWith(".lua")) {
                const filePath = path.join(tmpDir, file);
                const stats = await fs.stat(filePath);
                
                if (now - stats.mtimeMs > THREE_HOURS) {
                    await fs.unlink(filePath).catch(() => {});
                    console.log(`[Garbage Collector] Cleared unnecessary file: ${file}`);
                }
            }
        }
    } catch (err) {
        console.error("[Garbage Collector Error]:", err.message);
    }
}, 60 * 60 * 1000);

app.listen(PORT, () => {
    console.log(`🚀 Server running at http://localhost:${PORT}`);
});
