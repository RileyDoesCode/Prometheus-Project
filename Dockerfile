# Use an official Node.js image
FROM node:18-alpine

# Install Lua 5.1 (Crucial for Prometheus to work)
RUN apk update && apk add --no-cache lua5.1

# Create app directory
WORKDIR /app

# Install app dependencies
COPY package.json ./
RUN npm install

# Copy the rest of the bot and Prometheus files
COPY . .

# Start the bot
CMD ["node", "bot.js"]
