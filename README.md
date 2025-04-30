# Nginx WebDAV Docker Image

This Docker image provides a Nginx-based WebDAV server with multiple user authentication and per-user directory isolation.

## Features

- Nginx with WebDAV module
- Multiple users with password authentication
- Each user gets their own isolated directory
- Configurable maximum upload file size
- Alpine-based for small image size

## Quick Start

### Using Docker Compose

1. Clone this repository
2. Modify the `docker-compose.yml` file to set up your users and passwords
3. Run the container:

```bash
docker-compose up -d
```

### Using Docker Command

```bash
docker build -t nginx-webdav .

docker run -d --name webdav \
  -p 8080:80 \
  -e CLIENT_MAX_BODY_SIZE=1G \
  -e WEBDAV_USER_user1=password1 \
  -e WEBDAV_USER_user2=password2 \
  -v /host/path/to/user1:/data/user1 \
  -v /host/path/to/user2:/data/user2 \
  nginx-webdav
```

## Configuration

### Environment Variables

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `WEBDAV_USER_<username>` | Create a WebDAV user with the specified password | none |
| `CLIENT_MAX_BODY_SIZE` | Maximum file upload size | 0 |

### Volume Mounts

Each user's data is stored in `/data/<username>/` within the container. You can mount these directories to different locations on your host system:

```yaml
volumes:
  - /host/path/for/user1:/data/user1
  - /host/path/for/user2
```

## Acknowledgements

This project includes nginx configuration snippets from [dgraziotin/docker-nginx-webdav-nononsense](https://github.com/dgraziotin/docker-nginx-webdav-nononsense), used under the MIT License.