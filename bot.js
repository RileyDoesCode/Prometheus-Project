require("dotenv").config();

const {
    Client,
    GatewayIntentBits,
    Partials,
    REST,
    Routes,
    SlashCommandBuilder,
    AttachmentBuilder
} = require("discord.js");

const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");
const http = require("http");
const fetch = require("node-fetch");

const PORT = process.env.PORT || 3000;

http.createServer((req, res) => {
    res.writeHead(200);
    res.end("Bot running");
}).listen(PORT);

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.DirectMessages
    ],
    partials: [Partials.Channel]
});

function generateRandomString(length = 16) {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    let result = "";

    for (let i = 0; i < length; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }

    return result;
}

function formatBytes(bytes) {
    if (bytes === 0) return "0 Bytes";

    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
}

const commands = [
    new SlashCommandBuilder()
        .setName("obfuscate")
        .setDescription("Obfuscate your Lua script using Prometheus")
        .setDMPermission(true)

        .addAttachmentOption(option =>
            option.setName("file")
                .setDescription("Upload a .lua or .txt file")
                .setRequired(true)
        )

        .addStringOption(option =>
            option.setName("platform")
                .setDescription("Target platform")
                .setRequired(true)
                .addChoices(
                    { name: "Universal (Lua5.1/5.4)", value: "--Lua51" },
                    { name: "LuaU", value: "--LuaU" }
                )
        )

        .addStringOption(option =>
            option.setName("preset")
                .setDescription("Obfuscation strength")
                .setRequired(true)
                .addChoices(
                    { name: "Minify", value: "Minify" },
                    { name: "Weak", value: "Weak" },
                    { name: "Medium", value: "Medium" },
                    { name: "Strong", value: "Strong" }
                )
        )
].map(cmd => cmd.toJSON());

async function registerCommands() {
    const rest = new REST({ version: "10" }).setToken(process.env.BOT_TOKEN);

    try {
        console.log("Registering slash commands...");

        await rest.put(
            Routes.applicationCommands(process.env.CLIENT_ID),
            { body: commands }
        );

        console.log("Commands registered.");
    } catch (err) {
        console.error("Command registration error:", err);
    }
}

client.once("ready", async () => {
    console.log(`Logged in as ${client.user.tag}`);

    await registerCommands();
});

client.on("interactionCreate", async interaction => {

    if (!interaction.isChatInputCommand()) return;

    if (interaction.commandName !== "obfuscate") return;

    if (interaction.guild) {
        return interaction.reply({
            content:
                "❌ **Security Warning**\nUse this command in **DMs only**.",
            ephemeral: true
        });
    }

    const attachment = interaction.options.getAttachment("file");
    const platform = interaction.options.getString("platform");
    const preset = interaction.options.getString("preset");

    if (!attachment.name.endsWith(".lua") && !attachment.name.endsWith(".txt")) {
        return interaction.reply({
            content: "❌ File must be `.lua` or `.txt`",
            ephemeral: true
        });
    }

    await interaction.deferReply();

    try {

        const res = await fetch(attachment.url);
        const code = await res.text();

        const random = generateRandomString(12);

        const input = path.join(__dirname, `input_${random}.lua`);
        const output = path.join(__dirname, `output_${random}.lua`);

        fs.writeFileSync(input, code);

        const lua = spawn("lua5.1", [
            "Prometheus/cli.lua",
            input,
            "--preset",
            preset,
            "--out",
            output,
            platform
        ]);

        let stderr = "";

        lua.stderr.on("data", data => {
            stderr += data.toString();
        });

        lua.on("close", async () => {

            if (!fs.existsSync(output)) {

                if (fs.existsSync(input)) fs.unlinkSync(input);

                return interaction.editReply(
                    "❌ Obfuscation failed\n```lua\n" +
                    (stderr.slice(0, 1500) || "Unknown error") +
                    "\n```"
                );
            }

            const stats = fs.statSync(output);

            const file = new AttachmentBuilder(output, {
                name: `obfuscated-${random}.lua`
            });

            await interaction.editReply({
                content:
                    `✅ **Obfuscation complete**\nSize: ${formatBytes(stats.size)}`,
                files: [file]
            });

            fs.unlinkSync(input);
            fs.unlinkSync(output);
        });

    } catch (err) {

        console.error(err);

        await interaction.editReply(
            "❌ Failed to download or process file."
        );
    }
});

client.login(process.env.BOT_TOKEN);
