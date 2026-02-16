const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.static('public'));

app.post('/obfuscate', (req, res) => {
    const luaCode = req.body.code;

    if (!luaCode) {
        return res.status(400).json({ error: "No code provided" });
    }

    const id = Date.now();
    const inputPath = path.join(__dirname, `temp_${id}.lua`);
    const expectedOutputPath = path.join(__dirname, `temp_${id} (Obfuscated).lua`);

    fs.writeFileSync(inputPath, luaCode);

    const command = `lua5.1 Prometheus/cli.lua --preset Medium --LuaVersion LuaU "${inputPath}"`;

    exec(command, (error, stdout, stderr) => {
        if (fs.existsSync(expectedOutputPath)) {
            let obfuscatedCode = fs.readFileSync(expectedOutputPath, 'utf8');

            obfuscatedCode = obfuscatedCode.replace(/^--.*\n?/gm, '');
            obfuscatedCode = obfuscatedCode.replace(/^\s*[\r\n]/gm, '');

            try {
                fs.unlinkSync(inputPath);
                fs.unlinkSync(expectedOutputPath);
            } catch (err) {}

            res.json({ result: obfuscatedCode.trim() });

        } else {
            if (fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
            
            res.status(500).json({ 
                error: "Obfuscation failed", 
                details: stderr || stdout 
            });
        }
    });
});

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
