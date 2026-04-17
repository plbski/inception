#!/bin/bash
set -e

WP_PATH="/var/www/html/wordpress"

echo "==> Attente de MariaDB sur ${WORDPRESS_DB_HOST}..."
until mysqladmin ping -h "${WORDPRESS_DB_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; do
    echo "    MariaDB pas encore prêt, nouvelle tentative dans 3s..."
    sleep 3
done
echo "==> MariaDB disponible !"

# Télécharger WordPress si absent
if [ ! -f "${WP_PATH}/wp-login.php" ]; then
    echo "==> Téléchargement de WordPress..."
    wp core download \
        --path="${WP_PATH}" \
        --locale=fr_FR \
        --allow-root
fi

# Créer wp-config.php si absent
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
    echo "==> Création de wp-config.php..."
    wp config create \
        --path="${WP_PATH}" \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${WORDPRESS_DB_HOST}" \
        --allow-root
fi

# Installer WordPress si pas encore installé
if ! wp core is-installed --path="${WP_PATH}" --allow-root 2>/dev/null; then
    echo "==> Installation de WordPress..."
    wp core install \
        --path="${WP_PATH}" \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    echo "==> Création de l'utilisateur secondaire..."
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --path="${WP_PATH}" \
        --allow-root

    echo "==> WordPress installé avec succès !"
fi

# Permissions correctes
chown -R www-data:www-data "${WP_PATH}"

echo "==> Démarrage de PHP-FPM..."
exec php-fpm8.2 -F
