# FeastFlow Frontend - Container Operations Guide

A Next.js 16 food delivery application frontend demonstrating container building, execution, and debugging workflows for local development and DevOps practices.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Building the Container Image](#building-the-container-image)
- [Running Containers Locally](#running-containers-locally)
- [Container Debugging and Inspection](#container-debugging-and-inspection)
- [Screenshots](#screenshots)
- [Local Development (Non-Docker)](#local-development-non-docker)
- [Container Management Commands](#container-management-commands)
- [Troubleshooting Common Issues](#troubleshooting-common-issues)
- [Technology Stack](#technology-stack)

---

## Overview

This frontend application is containerized using Docker with a multi-stage build process. This README focuses on **operational confidence with containers** - building images locally, running containers with correct configurations, inspecting runtime state, and debugging issues before they reach CI/CD pipelines.

**Key Learning Objectives:**
- Validate container blueprints through local builds
- Run containers with intentional port, environment, and volume configurations
- Inspect container state, logs, and metadata for debugging
- Use interactive debugging to diagnose runtime issues
- Resolve and validate container fixes in a complete feedback loop

---

## Prerequisites

- **Docker Desktop** installed and running
- **Git** for version control
- Basic understanding of Docker commands
- Terminal/PowerShell access

Verify Docker installation:
```bash
docker --version
docker ps
```

---

## Building the Container Image

Building an image locally is the **first validation step** after writing or modifying a Dockerfile. A successful build confirms dependencies, instructions, and file paths are correct.

### Build Command

Navigate to the frontend app directory:
```bash
cd frontend/app
```

Build the image with a tag:
```bash
docker build -t feastflow-frontend .
```

### Understanding the Build Process

The Dockerfile uses a **multi-stage build** with four stages:

1. **base** - Base Node.js 20 Alpine image
2. **deps** - Install dependencies with `npm ci`
3. **builder** - Copy dependencies, source code, and run `npm run build`
4. **runner** - Production image with only runtime files, non-root user

### Build Output Validation

A successful build should show:
```
[+] Building 2.0s (21/21) FINISHED
=> exporting to image
=> => naming to docker.io/library/feastflow-frontend:latest
```

Verify the image was created:
```bash
docker images | grep feastflow-frontend
```

### Build with No Cache (Clean Build)

If you encounter caching issues or need a fresh build:
```bash
docker build --no-cache -t feastflow-frontend .
```

---

## Running Containers Locally

Running a container involves **intentional decisions** about ports, environment variables, and execution modes. These choices affect application accessibility, logging, and host system interaction.

### Basic Run Command (Foreground)

```bash
docker run -p 3000:3000 feastflow-frontend
```

**What this does:**
- Maps host port 3000 to container port 3000 (`-p 3000:3000`)
- Runs in foreground (you see logs directly)
- Container stops when you press `Ctrl+C`

### Run in Background (Detached Mode)

```bash
docker run -d -p 3000:3000 --name feastflow-app feastflow-frontend
```

**Flags explained:**
- `-d` - Detached mode (runs in background)
- `-p 3000:3000` - Port mapping (host:container)
- `--name feastflow-app` - Assigns a name for easier management

### Verify Container is Running

```bash
docker ps
```

Expected output:
```
CONTAINER ID   IMAGE                  COMMAND         STATUS          PORTS
a49c1993d7a7   feastflow-frontend    "node server.js"  Up 2 minutes    0.0.0.0:3000->3000/tcp
```

### Access the Application

Open your browser:
```
http://localhost:3000
```

---

## Container Debugging and Inspection

**Logs are the primary debugging interface for containers.** When applications fail or exit unexpectedly, logs provide the first clues.

### View Container Logs

```bash
# View logs from a running container
docker logs feastflow-app

# Follow logs in real-time (-f for follow)
docker logs -f feastflow-app

# View last 50 lines
docker logs --tail 50 feastflow-app
```

### Inspect Container Metadata

View detailed container configuration:
```bash
docker inspect feastflow-app
```

This shows:
- Environment variables
- Port bindings
- Volume mounts
- Network configuration
- Resource limits

Filter specific information:
```bash
# View environment variables
docker inspect -f '{{.Config.Env}}' feastflow-app

# View port mappings
docker inspect -f '{{.NetworkSettings.Ports}}' feastflow-app
```

### Interactive Debugging

**When logs alone aren't enough**, use interactive access to execute commands inside the running container:

```bash
docker exec -it feastflow-app sh
```

**Inside the container, you can:**
```bash
# Check working directory
pwd

# List files
ls -la

# View environment variables
env | grep NODE

# Check running processes
ps aux

# Test network connectivity
wget -O- http://localhost:3000

# Exit the container
exit
```

**When to use interactive debugging:**
- Verify file permissions
- Check if files were copied correctly
- Test environment variable values
- Inspect running processes
- Debug network connectivity issues

### Check Container Resource Usage

```bash
docker stats feastflow-app
```

Shows real-time CPU, memory, and network usage.

### View Container Processes

```bash
docker top feastflow-app
```

---

## Screenshots

### Docker Desktop - Container Running Successfully

![Docker Desktop Container Running](/screenshot/docker-desktop-container.png)

*Screenshot showing the feastflow-app container running in Docker Desktop with status "Running (2 minutes ago)" and port mapping 3000:3000. The container is accessible at http://localhost:3000.*

### Terminal - Build and Run Process

![Docker Build and Run Commands](/screenshot/docker-terminal-build-run.png)

*Terminal screenshot demonstrating the complete Docker workflow: building the image with `docker build -t feastflow-frontend .` showing the multi-stage build process (21/21 FINISHED), followed by `docker run` command launching the Next.js application successfully with "Ready in 99ms" on localhost:3000.*

---

## Local Development (Non-Docker)

For rapid development without Docker:

### Install Dependencies
```bash
npm install
```

### Run Development Server
```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to view the application.

### Build for Production
```bash
npm run build
npm start
```

### Lint Code
```bash
npm run lint
```

---

## Container Management Commands

### Stop a Running Container
```bash
docker stop feastflow-app
```

### Start a Stopped Container
```bash
docker start feastflow-app
```

### Restart a Container
```bash
docker restart feastflow-app
```

### Remove a Container
```bash
# Must be stopped first
docker rm feastflow-app

# Force remove even if running
docker rm -f feastflow-app
```

### Remove the Image
```bash
docker rmi feastflow-frontend
```

### View All Containers (Including Stopped)
```bash
docker ps -a
```

### Clean Up All Stopped Containers
```bash
docker container prune
```

### View Container Logs with Timestamps
```bash
docker logs -t feastflow-app
```

---

## Troubleshooting Common Issues

### Issue 1: Port Already in Use

**Symptom:** 
```
Error: bind: address already in use
```

**Diagnosis:**
```bash
# Windows - Find process using port 3000
netstat -ano | findstr :3000
```

**Fix:**
```bash
# Kill the process (replace <PID> with actual process ID)
taskkill /PID <PID> /F

# Or use a different host port
docker run -p 3001:3000 feastflow-frontend
```

### Issue 2: Container Exits Immediately

**Diagnosis:**
```bash
# Check exit code and logs
docker ps -a
docker logs feastflow-app
```

**Common causes:**
- Missing dependencies (check build logs)
- Incorrect CMD or ENTRYPOINT
- Application crashes on startup

**Debug:**
```bash
# Run with interactive shell to investigate
docker run -it feastflow-frontend sh
```

### Issue 3: Application Not Accessible

**Diagnosis checklist:**
1. Verify container is running: `docker ps`
2. Check port mapping: `docker port feastflow-app`
3. Check application logs: `docker logs feastflow-app`
4. Verify firewall settings

**Fix:**
```bash
# Ensure correct port mapping
docker run -p 3000:3000 feastflow-frontend
```

### Issue 4: Build Failures

**Symptom:** Build fails at specific stage

**Fix:**
```bash
# Clean build with no cache
docker build --no-cache -t feastflow-frontend .

# Check available disk space
docker system df

# Prune unused resources
docker system prune
```

### Issue 5: File Not Found in Container

**Diagnosis:**
```bash
# Check if files were copied correctly
docker exec -it feastflow-app ls -la /app
```

**Fix:** Verify `.dockerignore` and `COPY` instructions in Dockerfile

---

## Technology Stack

| Technology | Version | Purpose |
|-----------|---------|---------|
| **Next.js** | 16.1.6 | React framework with App Router |
| **React** | 19.2.3 | UI library |
| **TypeScript** | 5.x | Type-safe JavaScript |
| **Tailwind CSS** | 4.x | Utility-first CSS framework |
| **Node.js** | 20 Alpine | Runtime environment |
| **Docker** | - | Container platform |

### Docker Configuration Highlights

- **Multi-stage build** - Optimized image size
- **Standalone output** - Self-contained deployment
- **Non-root user** - Security best practice (nextjs:nodejs)
- **Alpine Linux** - Minimal base image (~40MB)
- **Port 3000** - Exposed for HTTP traffic

---

## Project Structure

```
frontend/app/
├── src/
│   ├── app/              # Next.js App Router pages
│   │   ├── page.tsx      # Home page
│   │   ├── layout.tsx    # Root layout
│   │   ├── admin/        # Admin dashboard
│   │   └── restaurant/   # Restaurant pages
│   ├── components/       # Reusable components
│   ├── context/          # React Context providers
│   ├── data/            # Mock data
│   └── types/           # TypeScript types
├── public/              # Static assets
├── Dockerfile           # Container blueprint
├── .dockerignore        # Files excluded from build
├── next.config.ts       # Next.js configuration
├── package.json         # Dependencies
└── README.md           # This file
```

---

## DevOps Learning Objectives

This project demonstrates:

✅ **Container Building** - Multi-stage Dockerfile with optimization  
✅ **Local Execution** - Running containers with proper configuration  
✅ **Runtime Debugging** - Log inspection and interactive debugging  
✅ **State Inspection** - Metadata and process monitoring  
✅ **Issue Resolution** - Complete debugging feedback loop  
✅ **Operational Confidence** - Understanding container lifecycle

---

## Learn More

- [Docker Documentation](https://docs.docker.com/)
- [Next.js Documentation](https://nextjs.org/docs)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)

---

**Part of Sprint #3: Building, Running, and Debugging Containers Locally**

This README demonstrates practical container execution and debugging workflows essential for DevOps practices and CI/CD pipeline reliability.
