*This project has been created as part of the 42 curriculum by plbuet.*

# Inception

## Description

Inception is a system administration project from the 42 curriculum. The goal is to set up a small infrastructure composed of multiple services running in Docker containers, orchestrated with Docker Compose, inside a virtual machine.

The infrastructure consists of:
- **NGINX** — the only entry point, handling HTTPS with TLSv1.2/TLSv1.3
- **WordPress + PHP-FPM** — the web application
- **MariaDB** — the database

Each service runs in its own dedicated container, built from scratch using a custom Dockerfile based on `debian:bookworm`. No pre-made images are used.

---

## Project Description

### Use of Docker

Docker is used to isolate each service in its own container. Each container has a single responsibility, its own filesystem, and its own network identity. Containers are built from custom Dockerfiles and orchestrated with Docker Compose.

The project includes:
- 3 custom Dockerfiles (one per service)
- 1 `docker-compose.yml` to orchestrate all services
- 2 named Docker volumes for persistent storage
- 1 Docker bridge network for internal communication

### Main Design Choices

- PHP-FPM runs inside the WordPress container — NGINX communicates with it via FastCGI on port 9000
- MariaDB is initialized via a bootstrap script that creates the database and user on first start
- WordPress is installed automatically via WP-CLI at container startup
- All secrets are stored in a `.env` file, never committed to git
- PHP version is detected automatically at runtime for portability across machines

---

### Virtual Machines vs Docker

| | Virtual Machine | Docker |
|---|---|---|
| **Isolation** | Full OS virtualization | Process isolation, shared kernel |
| **Size** | Several GB | A few hundred MB |
| **Startup** | Minutes | Seconds |
| **Performance** | Overhead from hypervisor | Near-native performance |
| **Use case** | Full OS isolation needed | Service isolation, microservices |

A VM virtualizes an entire machine including hardware. Docker shares the host Linux kernel and only isolates the process environment — making it much lighter and faster to start.

---

### Secrets vs Environment Variables

| | Environment Variables | Docker Secrets |
|---|---|---|
| **Storage** | `.env` file | Encrypted, managed by Docker |
| **Access** | All processes in the container | Only specified services |
| **Security** | Visible in `docker inspect` | Not exposed in inspect |
| **Use case** | Development, simple projects | Production, sensitive credentials |

In this project, environment variables via `.env` are used. The `.env` file is never committed to git (listed in `.gitignore`). Docker Secrets would be the recommended approach for a production environment.

---

### Docker Network vs Host Network

| | Docker Bridge Network | Host Network |
|---|---|---|
| **Isolation** | Containers have their own network namespace | Container shares host network |
| **Security** | Containers only reach each other via defined network | Full access to host interfaces |
| **Communication** | By service name (e.g. `mariadb`, `wordpress`) | Via localhost |
| **Port exposure** | Explicit with `ports:` | Automatic |

This project uses a **bridge network** called `inception_network`. Host network (`network: host`) is explicitly forbidden by the subject. Containers communicate by service name — NGINX reaches WordPress at `wordpress:9000`, WordPress reaches MariaDB at `mariadb:3306`.

---

### Docker Volumes vs Bind Mounts

| | Docker Named Volumes | Bind Mounts |
|---|---|---|
| **Management** | Managed by Docker | Managed by the user |
| **Portability** | Portable across environments | Depends on host path |
| **Declaration** | In `volumes:` section | Inline in service definition |
| **Use in subject** | Required | Forbidden |

This project uses **named volumes** with a local driver pointing to `/home/login/data/` on the host machine, as required by the subject. This combines the benefits of named volumes (managed by Docker, visible with `docker volume ls`) with a defined storage location on the host.

---

## Instructions

### Prerequisites

- Docker and Docker Compose installed
- `make` available
- A virtual machine running Linux (required by the subject)

### Configuration

1. Clone the repository:
```bash
git clone <repo_url>
cd inception
```

2. Create the `.env` file inside `srcs/`:
```bash
cp srcs/.env.example srcs/.env
```

3. Edit `srcs/.env` with your own values:
```env
DOMAIN_NAME=login.42.fr
PATH_TO_VOLUMES=/home/login/data

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wppassword
MYSQL_ROOT_PASSWORD=rootpassword

WORDPRESS_DB_HOST=mariadb
WP_TITLE=Inception
WP_ADMIN_USER=myadmin
WP_ADMIN_PASSWORD=myadminpass
WP_ADMIN_EMAIL=admin@login.42.fr
WP_USER=wpeditor
WP_USER_EMAIL=editor@login.42.fr
WP_USER_PASSWORD=editorpass
```

### Build and Run

```bash
# Build images and start all containers
make

# Stop all containers
make down

# Stop, clean everything and restart from scratch
make re

# View logs
make logs           # all services
make logs-wp        # wordpress only
make logs-db        # mariadb only
make logs-nginx     # nginx only
```

### Access

- Website: `https://login.42.fr`
- Admin panel: `https://login.42.fr/wp-admin`

> A self-signed certificate warning will appear in the browser — this is expected. Click "Advanced" and proceed.

---

## MariaDB — Database Commands

### Connect to the database

```bash
# Connect as WordPress user (database selected directly)
docker exec -it srcs-mariadb-1 mariadb -u wpuser -pwppassword wordpress

# Connect as root (database selected directly)
docker exec -it srcs-mariadb-1 mariadb -u root -pchangeme wordpress

# Connect interactively (password prompt — does not appear in bash history)
docker exec -it srcs-mariadb-1 mariadb -u root -p
```

### Navigate the database

```sql
-- List all databases
SHOW DATABASES;

-- Select the WordPress database
USE wordpress;

-- List all tables
SHOW TABLES;

-- Describe a table structure
DESCRIBE wp_users;
```

### Query data

```sql
-- View all WordPress users
SELECT ID, user_login, user_email FROM wp_users;

-- View published posts
SELECT ID, post_title, post_status FROM wp_posts WHERE post_status = 'publish';

-- Count rows in a table
SELECT COUNT(*) FROM wp_posts;

-- Check database size (MB)
SELECT table_schema AS 'Database',
  ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables
GROUP BY table_schema;
```

### Manage users

```sql
-- List all MariaDB users
SELECT user, host FROM mysql.user;

-- Check privileges of a user
SHOW GRANTS FOR 'wpuser'@'%';

-- Create a new user
CREATE USER 'newuser'@'%' IDENTIFIED BY 'newpassword';

-- Grant privileges on the WordPress database
GRANT ALL PRIVILEGES ON wordpress.* TO 'newuser'@'%';

-- Apply changes
FLUSH PRIVILEGES;

-- Remove a user
DROP USER 'newuser'@'%';
FLUSH PRIVILEGES;
```

### Test a new user connection

```bash
docker exec -it srcs-mariadb-1 mariadb -u newuser -pnewpassword wordpress
```

### Exit MariaDB

```sql
EXIT;
```

---

## Resources

### Official Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Developer Documentation](https://developer.wordpress.org/)
- [WP-CLI Documentation](https://wp-cli.org/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [OpenSSL Documentation](https://www.openssl.org/docs/)

### Articles and Tutorials
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Understanding PID 1 in Docker](https://cloud.google.com/architecture/best-practices-for-building-containers)
- [Docker Networking Overview](https://docs.docker.com/network/)
- [Docker Volumes Documentation](https://docs.docker.com/storage/volumes/)

### AI Usage

AI (Claude by Anthropic) was used during this project for the following tasks:
- Debugging connection errors between containers (MariaDB ↔ WordPress)
- Understanding and explaining Docker concepts (PID 1, FastCGI, PHP-FPM pool configuration)
- Generating documentation files (README.md, USER_DOC.md, DEV_DOC.md)
