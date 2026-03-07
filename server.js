const express = require("express")
const { spawn } = require("child_process")
const fs = require("fs")
const path = require("path")
const cors = require("cors")

const app = express()
const PORT = 3000

app.use(cors())
app.use(express.json({ limit: "50mb" }))
app.use(express.static("public"))

app.post("/obfuscate", async (req, res) => {

    try {

        const { code, preset, platform } = req.body

        if (!code || typeof code !== "string") {
            return res.status(400).json({ error: "No Lua code provided" })
        }

        const id = Date.now() + "_" + Math.floor(Math.random() * 100000)

        const inputFile = `temp_${id}.lua`
        const outputFile = `temp_${id}.obfuscated.lua`

        const inputPath = path.join(__dirname, inputFile)
        const outputPath = path.join(__dirname, outputFile)

        fs.writeFileSync(inputPath, code, "utf8")

        const args = ["Prometheus/cli.lua"]

        if (platform === "LuaU") args.push("--LuaU")
        else args.push("--Lua51")

        args.push("--preset", preset || "Medium")
        args.push("--nocolors")

        args.push(inputFile)

        const lua = spawn("lua5.1", args, {
            cwd: __dirname
        })

        let stderr = ""
        let stdout = ""

        lua.stdout.on("data", d => stdout += d.toString())
        lua.stderr.on("data", d => stderr += d.toString())

        lua.on("error", err => {
            cleanup()
            return res.status(500).json({
                error: "Lua process failed",
                details: err.message
            })
        })

        lua.on("close", () => {

            if (fs.existsSync(outputPath)) {

                const result = fs.readFileSync(outputPath, "utf8")

                cleanup()

                return res.json({ result })
            }

            cleanup()

            return res.status(500).json({
                error: "Obfuscation failed",
                details: stderr || stdout || "Unknown error"
            })
        })

        function cleanup() {
            try {
                if (fs.existsSync(inputPath)) fs.unlinkSync(inputPath)
                if (fs.existsSync(outputPath)) fs.unlinkSync(outputPath)
            } catch {}
        }

    } catch (err) {

        return res.status(500).json({
            error: "Server error",
            details: err.message
        })

    }

})

app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`)
})
