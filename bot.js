require('dotenv').config();
const { 
    Client, 
    GatewayIntentBits, 
    Partials, 
    REST, 
    Routes, 
    SlashCommandBuilder, 
    AttachmentBuilder 
} = require('discord.js');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.DirectMessages
    ],
    partials: [Partials.Channel]
});

function generateRandomString(length = 16) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
}

function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

const commands = [
    new SlashCommandBuilder()
        .setName('obfuscate')
        .setDescription('Obfuscate your Lua script using Prometheus')
        .setDMPermission(true)
        .addAttachmentOption(option =>
            option.setName('file')
                .setDescription('Pick one: provide a .txt or .lua file')
                .setRequired(true)
        )
        .addStringOption(option =>
            option.setName('platform')
                .setDescription('Universal (Lua5.1/5.4) or LuaU')
                .setRequired(true)
                .addChoices(
                    { name: 'Universal (Lua5.1/5.4)', value: '--Lua51' },
                    { name: 'LuaU', value: '--LuaU' }
                )
        )
        .addStringOption(option =>
            option.setName('presets')
                .setDescription('Minify, Weak, Medium, or Strong')
                .setRequired(true)
                .addChoices(
                    { name: 'Minify (Fastest, tiny)', value: 'Minify' },
                    { name: 'Weak (Fast, small)', value: 'Weak' },
                    { name: 'Medium (Recommended)', value: 'Medium' },
                    { name: 'Strong (Slowest, huge)', value: 'Strong' }
                )
        )
].map(command => command.toJSON());

client.once('ready', async () => {
    console.log(`🤖 Logged in as ${client.user.tag}!`);

    const rest = new REST({ version: '10' }).setToken(process.env.BOT_TOKEN);
    try {
        console.log('Started refreshing application (/) commands.');
        await rest.put(
            Routes.applicationCommands(client.user.id),
            { body: commands },
        );
        console.log('Successfully reloaded application (/) commands.');
    } catch (error) {
        console.error('Error registering commands:', error);
    }
});

client.on('interactionCreate', async interaction => {
    if (!interaction.isChatInputCommand()) return;

    if (interaction.commandName === 'obfuscate') {
        
        if (interaction.guild) {
            return interaction.reply({ 
                content: "❌ **Security Warning:** To protect your scripts, this command can **only be used in my DMs**.\nPlease right-click my profile and click 'Message' to use me!", 
                ephemeral: true 
            });
        }

        const attachment = interaction.options.getAttachment('file');
        const platformFlag = interaction.options.getString('platform');
        const preset = interaction.options.getString('presets');

        const originalName = attachment.name;
        if (!originalName.endsWith('.lua') && !originalName.endsWith('.txt')) {
            return interaction.reply({ 
                content: "❌ Invalid file! Please provide a `.lua` or `.txt` file.", 
                ephemeral: true 
            });
        }

        await interaction.deferReply();

        try {
            const response = await fetch(attachment.url);
            const luaCode = await response.text();

            const randomSuffix = generateRandomString(16);
            const nameWithoutExt = originalName.replace(/\.(lua|txt)$/i, "");
            const newFileName = `${nameWithoutExt}-${randomSuffix}.lua`;
            const inputPath = path.join(__dirname, `temp_in_${randomSuffix}.lua`);
            const outputPath = path.join(__dirname, newFileName);

            fs.writeFileSync(inputPath, luaCode);

            const spawnArgs = [
                "Prometheus/cli.lua",
                inputPath,
                "--preset", preset,
                "--out", outputPath,
                platformFlag
            ];

            const luaProcess = spawn("lua5.1", spawnArgs);

            let stderrData = "";
            luaProcess.stderr.on("data", (data) => {
                stderrData += data.toString();
            });

            luaProcess.on("close", async (code) => {
                if (fs.existsSync(outputPath)) {
                
                    const stats = fs.statSync(outputPath);
                    const fileSize = formatBytes(stats.size);
                    
                    const obfuscatedAttachment = new AttachmentBuilder(outputPath, { name: newFileName });

                    const successMessage = `**Obfuscated Success!** File: ${originalName} ${fileSize}\n\`${newFileName}\``;

                    await interaction.editReply({
                        content: successMessage,
                        files: [obfuscatedAttachment]
                    });
                    try {
                        fs.unlinkSync(inputPath);
                        fs.unlinkSync(outputPath);
                    } catch (err) {}

                } else {
                    if (fs.existsSync(inputPath)) fs.unlinkSync(inputPath);
                    const errorSnippet = stderrData.slice(0, 1500) || "Unknown Prometheus Error.";
                    await interaction.editReply(`❌ **Obfuscation Failed:**\n\`\`\`lua\n${errorSnippet}\n\`\`\``);
                }
            });

        } catch (error) {
            console.error(error);
            await interaction.editReply("❌ An error occurred while trying to download or process your file.");
        }
    }
});

client.login(process.env.BOT_TOKEN);
