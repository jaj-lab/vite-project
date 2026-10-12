# Deployment Guide

### For initial infrastructure configuration, see [`setup.md`](setup.md).

Guide to run the application locally and deploy it to the Debian server using GitHub Actions.

## 1. Run Locally with Docker

### Pull and run the Latest vite-project Docker image:
```bash
docker pull jajalab/vite-project:latest

docker run -d \
  --name vite-project \
  -p 5173:5173 \
  jajalab/vite-project:latest
```

### Build the Docker image yourself:

```bash
git clone https://github.com/jaj-lab/vite-project.git vite-project
cd vite-project
docker build -t vite-project .
```

Start the container:

```bash
docker run -d \
  --name vite-project \
  -p 5173:5173 \
  vite-project
```

### Verify that the application is available:

```bash
curl -I http://localhost:5173
```

Open `http://localhost:5173` in a browser.

### Run Through Nginx

The deployed application runs in a Docker container on port `5173`. Nginx listens on port `8080` and reverse-proxies HTTP requests to the container.

After completing the infrastructure setup and deploying the application, open:

```text
http://SERVER_ADDRESS:8080
```

Replace `SERVER_ADDRESS` with the Debian server's reachable IP address or hostname.

Verify the response from the server:

```bash
curl -I http://SERVER_ADDRESS:8080
```

The expected response is HTTP `200 OK`.

### To stop and remove the container:

```bash
docker rm -f vite-project
```

## 2. Automatic Deployment


The CI/CD pipeline is defined in `.github/workflows/deploy.yaml`.

Every push to the `main` branch triggers the workflow, which consists of two jobs.

### Build

GitHub Actions:

1. Checks out the repository.
2. Authenticates to Docker Hub using repository secrets.
3. Builds the Docker image.
4. Tags the image with the commit SHA and `latest`.
5. Pushes both tags to Docker Hub.

The published image is `jajalab/vite-project`.

### Deploy

After the build job succeeds, GitHub Actions:

1. Connects to Tailscale using the configured OAuth credentials and the `tag:ci` tag.
2. Downloads `scripts/deploy.sh` from the `main` branch.
3. Configures SSH authentication using `DEPLOY_SSH_KEY`.
4. Copies the deployment script to `/tmp/deploy.sh` on the Debian server.
5. Executes the script over SSH.

The deployment job does not clone the repository on the server. It downloads the published Docker image directly from Docker Hub.

## 3. Deployment Script

The deployment logic is implemented in [`scripts/deploy.sh`](../scripts/deploy.sh).

The script performs the following operations:

1. Verifies Docker availability.
2. Pulls the latest `jajalab/vite-project:latest` image.
3. Removes the existing `vite-project` container, if present.
4. Starts a new container with port `5173` published on the server.
5. Checks whether the application responds with HTTP `200`.
6. Checks the Nginx endpoint.

The script exits with a non-zero status if a validation step fails, allowing GitHub Actions to report a failed deployment.

## 4. Verify the Deployment

Open the GitHub repository and navigate to **Actions**.

Select the latest **Build & Deploy** workflow run and verify that both jobs completed successfully:

- `build` — Docker image built and pushed.
- `deploy` — deployment script executed successfully.

On the Debian server, check the container:

```bash
docker ps --filter name=vite-project
```

Inspect application logs if needed:

```bash
docker logs vite-project
```

Check Nginx:

```bash
sudo nginx -t
sudo systemctl status nginx
```

Test the application through Nginx:

```bash
curl -I http://localhost:8080
```

The application should return HTTP `200`.

To access it from another device, use the Debian server's reachable IP address or hostname and port `8080`, subject to the server's network and firewall configuration.

## 5. Troubleshooting

| Problem | Checks |
|---|---|
| Docker image pull fails | Check Docker Hub image availability and registry permissions. |
| SSH connection fails | Check Tailscale connectivity, the access policy, SSH service, and GitHub secrets. |
| Container does not start | Run `docker ps -a` and `docker logs vite-project`. |
| Application check fails | Check the container state and whether Vite is listening on port `5173`. |
| Nginx check fails | Check `sudo nginx -t`, `sudo systemctl status nginx`, and the proxy configuration. |
| Deployment job fails | Review the failed step in the GitHub Actions logs. |
