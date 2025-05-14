# web-ui/birthday-manager/Dockerfile

FROM node:18-slim

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the code
COPY . .

# Build the app
RUN npm run build

# Start the app (assuming you're using react-scripts)
CMD ["npm", "start"]

