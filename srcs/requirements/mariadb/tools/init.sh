#!/bin/bash
set -e

echo "==> Initialisation MariaDB..."

# Initialiser le datadir s'il est vide
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "==> Premier démarrage : création de la base de données..."

    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Démarrer MariaDB temporairement (sans réseau)
    mysqld --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
    MYSQL_PID=$!

    # Attendre que MariaDB accepte les connexions
    echo "==> Attente de MariaDB..."
    for i in $(seq 1 30); do
        if mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent 2>/dev/null; then
            echo "==> MariaDB prêt !"
            break
        fi
        sleep 1
    done

    # Créer la base, l'utilisateur et le mot de passe root
    mysql --socket=/run/mysqld/mysqld.sock -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    echo "==> Base '${MYSQL_DATABASE}' et utilisateur '${MYSQL_USER}' créés."

    # Arrêter MariaDB temporaire proprement
    mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait $MYSQL_PID
    echo "==> Initialisation terminée."

else
    echo "==> Base de données existante, démarrage direct."
fi

# Lancer MariaDB en foreground
echo "==> Démarrage de MariaDB en production..."
exec mysqld --user=mysql
