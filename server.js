const express = require('express');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.static('public'));

app.post('/obfuscate', (req, res) => {

const { code, preset, platform } = req.body

if (!code) {
return res.status(400).json({ error: "No code provided" })
}

const id = Date.now()

const inputFile = `temp_${id}.lua`
const outputFile = `temp_${id}.obfuscated.lua`

const inputPath = path.join(__dirname, inputFile)
const outputPath = path.join(__dirname, outputFile)

fs.writeFileSync(inputPath, code)

const args = [
"Prometheus/cli.lua",
"--preset", preset || "Medium",
inputFile
]

if(platform === "LuaU") args.unshift("--LuaU")
if(platform === "Lua51") args.unshift("--Lua51")

const lua = spawn("lua5.1", args)

let stderr = ""

lua.stderr.on("data", d => stderr += d.toString())

lua.on("close", () => {

if(fs.existsSync(outputPath)){

const result = fs.readFileSync(outputPath,"utf8")

try{
fs.unlinkSync(inputPath)
fs.unlinkSync(outputPath)
}catch{}

return res.json({result})
}

if(fs.existsSync(inputPath)) fs.unlinkSync(inputPath)

res.status(500).json({
error:"Obfuscation failed",
details:stderr || "Unknown error"
})

})

})

app.listen(PORT, () => {
    console.log("Server running on http://localhost:" + PORT);
});
