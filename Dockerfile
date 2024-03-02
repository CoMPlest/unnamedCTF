FROM node:21-alpine AS builder

# Set the working directory in the container
WORKDIR /app

# Copy the package.json and package-lock.json files to the container
COPY package*.json ./
RUN npm install

# Copy the rest of the application code to the container
COPY . .

# Build the Next.js application
RUN npm run build

# Use the official Rust image as the base image for the API
FROM rust:latest AS api

WORKDIR /api

# Copy the API code to the container
COPY api .

# Build the Rust API
RUN cargo build --release

# Use the official PostgreSQL image as the base image for the database
FROM postgres:latest AS database

# Set the environment variables for the database
ARG user           # passed in via --build-arg s=foo
ARG pass           # passed in via --build-arg s=foo
ENV POSTGRES_USER=$user
ENV POSTGRES_PASSWORD=$pass
ENV POSTGRES_DB=sugondese

# Copy the SQL script to initialize the database
COPY init.sql /docker-entrypoint-initdb.d/

# Set up the final image
FROM node:21-alpine

# Set the working directory in the container
WORKDIR /app

# Copy the built Next.js application from the builder stage
COPY --from=builder /app/.next ./.next

# Copy the package.json and package-lock.json files to the container
COPY package*.json ./

# Install only production dependencies
RUN npm install --only=production

# Copy the API binary from the API stage
COPY --from=api /api/target/release/api ./api

# Expose the desired ports
EXPOSE 3000
EXPOSE 8000

# Start the Next.js application and the Rust API
CMD ["npm", "run", "start"]


