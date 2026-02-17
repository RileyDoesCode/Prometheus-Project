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

    const luaCode = req.body.code;
    if (!luaCode) return res.status(400).json({ error: "No code provided" });

    const id = Date.now();
    const inputFile = `temp_${id}.lua`;
    const outputFile = `temp_${id}.obfuscated.lua`;

    const inputPath = path.join(__dirname, inputFile);
    const outputPath = path.join(__dirname, outputFile);

    fs.writeFileSync(inputPath, luaCode);

    const lua = spawn("lua5.1", [
        "Prometheus/cli.lua",
        inputFile,
        "--preset",
        "Medium"
    ]);

    let stderrData = "";

    lua.stderr.on("data", (data) => {
        stderrData += data.toString();
    });

    lua.on("close", () => {

        if (fs.existsSync(outputPath)) {

            const result = fs.readFileSync(outputPath, "utf8");

            try {
                fs.unlinkSync(inputPath);
                fs.unlinkSync(outputPath);
            } catch {}

            return res.json({ result });
        }

        if (fs.existsSync(inputPath)) fs.unlinkSync(inputPath);

        return res.status(500).json({
            error: "Obfuscation failed",
            details: stderrData || "Unknown error"
        });
    });
});

app.listen(PORT, () => {
    console.log("Server running on http://localhost:" + PORT);
});
