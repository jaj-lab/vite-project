# Vite Project — Docker & CI/CD

A simple React + TypeScript web application built with Vite, containerized with Docker, and deployed to a Debian server behind Nginx.

## Architecture

- **Application:** React, TypeScript, Vite
- **Containerization:** Docker
- **Container registry:** Docker Hub
- **Web server:** Nginx reverse proxy on Debian 13
- **CI/CD:** GitHub Actions
- **Private connectivity:** Tailscale
- **Remote deployment:** OpenSSH

### CI/CD Workflow

```text
        Push to main
             |
             v
      GitHub Actions
             |
             v
      Build Docker Image
             |
             v
       Push to Docker Hub
       (SHA + latest tags)
             |
             v
     Connect through Tailscale
             |
             v
       Deploy over SSH
             |
             v
       Debian Server
             |
             v
       Docker Container
         (port 5173)
             |
             v
       Nginx Reverse Proxy
         (port 8080)
             |
             v
         Web Browser
```

Every push to `main` triggers the workflow. After a successful build and image publication, the deployment job connects to the server, pulls the latest image, replaces the running container, and verifies application availability through the container and Nginx.

## Run Locally

Run the published Docker image:

```bash
docker pull jajalab/vite-project:latest

docker run -d \
  --name vite-project \
  -p 5173:5173 \
  jajalab/vite-project:latest
```

Open [http://localhost:5173](http://localhost:5173).

To stop and remove the container:

```bash
docker rm -f vite-project
```

## Deployment

The deployed application is served through Nginx on port `8080`, which reverse-proxies requests to the Docker container on port `5173`.

After completing the server setup and deployment, access the application at:

```text
http://SERVER_ADDRESS:8080
```

Replace `SERVER_ADDRESS` with the Debian server's reachable IP address or hostname.

## Documentation

- [Setup Guide](docs/setup.md) — server preparation, Docker, Nginx, SSH, Tailscale, Docker Hub, and GitHub Secrets.
- [Deployment Guide](docs/deployment.md) — local execution, CI/CD workflow, deployment verification, and troubleshooting.

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── deploy.yaml
├── docs/
│   ├── configs/
│   ├── setup.md
│   └── deployment.md
├── scripts/
│   └── deploy.sh
├── Dockerfile
└── README.md
```
