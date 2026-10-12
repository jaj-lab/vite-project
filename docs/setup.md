# Setup Guide

Guide to prepare the infrastructure required to run the Vite application and deploy it using GitHub Actions.

## 1. Architecture and Requirements

The solution consists of:

- **Application:** React, TypeScript, and Vite.
- **Containerization:** Docker.
- **Container registry:** Docker Hub.
- **Web server:** Nginx on Debian 13.
- **CI/CD:** GitHub Actions.
- **Private connectivity:** Tailscale.
- **Remote administration:** SSH.

Required resources:

- A GitHub account and this repository.
- A Docker Hub account.
- A Tailscale account.
- A Debian 13 server with network connectivity.
- Administrative access to configure the server.

The server can run on a physical machine or a virtual machine. The original implementation uses Debian 13 on QEMU/KVM with libvirt.

## 2. Prepare the Debian Server

Update the system and install the required packages:

- **Docker:** https://docs.docker.com/engine/install/debian/
- **Nginx:** https://nginx.org/en/linux_packages.html#Debian
- **OpenSSH server:** 
```bash
sudo apt install openssh-server -y
```

Enable the services:

```bash
sudo systemctl enable --now docker
sudo systemctl enable --now nginx
sudo systemctl enable --now ssh
```

Verify that Docker, Nginx, and SSH are running:

```bash
systemctl status docker
systemctl status nginx
systemctl status ssh
```

## 3. Configure the Deployment User

Create a dedicated user for remote deployments:

```bash
sudo adduser deploy
sudo usermod -aG docker deploy
```

The `deploy` user requires Docker access to pull images, replace containers, and start the application.
Apply the new group membership by starting a new SSH session after configuration.

## 4. Configure SSH Authentication

Generate an Ed25519 SSH key pair on the machine used to administer the deployment:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/vite_project
```

Install the public key for the `deploy` user:

```bash
sudo install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
```

Add the contents of `~/.ssh/vite_project.pub` to:

```text
/home/deploy/.ssh/authorized_keys
```

Set the correct ownership and permissions:

```bash
sudo chown deploy:deploy /home/deploy/.ssh/authorized_keys
sudo chmod 600 /home/deploy/.ssh/authorized_keys
```

Verify that key-based authentication works from a machine that can reach the server:

```bash
ssh -i ~/.ssh/vite_project deploy@SERVER_ADDRESS
```

Replace `SERVER_ADDRESS` with the server's reachable IP address or hostname.

The private key must remain secret and must never be committed to the repository.

## 5. Configure Nginx

Create `/etc/nginx/sites-available/vite-project`:

```nginx
server {
    listen 8080;

    location / {
        proxy_pass http://localhost:5173;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/vite-project \
  /etc/nginx/sites-enabled/vite-project
```

Validate the configuration and reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

The application container listens on port `5173`. Nginx exposes it on port `8080`.

## 6. Configure Tailscale

Install and authenticate Tailscale on the Debian server using the official instructions:

https://tailscale.com/kb/1031/install-linux

Ensure that the server is connected to the tailnet and has a stable Tailscale IP address.

```bash
tailscale status
```

Configure the tailnet access policy to allow the tagged GitHub Actions runner (`tag:ci`) to access the deployment server on TCP port `22`.

- Open Tailscale Admin Console: https://console.tailscale.com/admin
- Create tag via JSON policy: Paste tailscale-tag-policy.json from docs/configs

The deployment uses standard OpenSSH. Tailscale SSH must be disabled on the server if it intercepts connections intended for the system's OpenSSH service:

```bash
sudo tailscale set --ssh=false
```

Create Tailscale OAuth credentials for GitHub Actions with the permissions required by the Tailscale GitHub Action and authorize the `tag:ci` tag.

Official references:

- Installation: https://tailscale.com/kb/1031/install-linux
- GitHub Action: https://github.com/tailscale/github-action

## 7. Configure Docker Hub

Create a Docker Hub access token with permission to push images to the repository.

The workflow publishes the following image:

```text
jajalab/vite-project
```

It uses two tags:

- `latest` — the current image used by the deployment script.
- The Git commit SHA — an immutable reference to a specific build.

## 8. Configure GitHub Secrets

In the GitHub repository, open **Settings → Secrets and variables → Actions** and add the following repository secrets.

| Secret | Description |
|---|---|
| `REGISTRY_USER` | Docker Hub username |
| `REGISTRY_TOKEN` | Docker Hub access token |
| `TS_OAUTH_CLIENT_ID` | Tailscale OAuth client ID |
| `TS_OAUTH_SECRET` | Tailscale OAuth client secret |
| `DEPLOY_HOST` | Debian server's Tailscale IP address |
| `DEPLOY_USER` | `deploy` |
| `DEPLOY_SSH_KEY` | Private SSH key corresponding to the public key installed for `deploy` |

Do not store secrets in workflow files, commit them to Git, or expose them in logs.

## 9. Verify the Setup

Before running the deployment workflow, verify that:

- Docker, Nginx, and SSH are running on Debian.
- The `deploy` user can execute Docker commands.
- SSH key authentication works.
- The Debian server is connected to Tailscale.
- The Tailscale access policy permits the `tag:ci` runner to reach the server on TCP port `22`.
- All required GitHub repository secrets are configured.
- The Nginx configuration passes `nginx -t`.

Once these requirements are satisfied, proceed to the deployment instructions in [`deployment.md`](deployment.md).
