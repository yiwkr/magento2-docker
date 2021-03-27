#!/bin/bash

if [[ $# -ne 0 ]]; then
  docker-php-entrypoint "$@"
else
  set -x
  MAGENTO_SETUP_PROJECT_NAME="${MAGENTO_SETUP_PROJECT_NAME:-magento2}"
  MAGENTO_SETUP_DOCUMENT_ROOT="${MAGENTO_SETUP_DOCUMENT_ROOT:-/var/www/html}"
  MAGENTO_SETUP_BASE_URL="${MAGENTO_SETUP_BASE_URL:-http://localhost/}"

  PROJECT_DIR="${MAGENTO_SETUP_DOCUMENT_ROOT%/}/${MAGENTO_SETUP_PROJECT_NAME}"
  SERVER_NAME=$(echo "$MAGENTO_SETUP_BASE_URL" | sed -E 's;http(s)?://;;' | grep -o '^[^/]*')

  if [[ ! -d "$PROJECT_DIR" ]]; then
    : ${MAGENTO_SETUP_MARKETPLACE_PUBLIC_KEY:?MAGENTO_SETUP_MARKETPLACE_PUBLIC_KEY is required}
    : ${MAGENTO_SETUP_MARKETPLACE_PRIVATE_KEY:?MAGENTO_SETUP_MARKETPLACE_PRIVATE_KEY is required}

    composer config -g http-basic.repo.magento.com             \
      $MAGENTO_SETUP_MARKETPLACE_PUBLIC_KEY                    \
      $MAGENTO_SETUP_MARKETPLACE_PRIVATE_KEY

    composer create-project                                    \
      --repository-url=https://repo.magento.com/               \
      magento/project-community-edition                        \
      "$MAGENTO_SETUP_PROJECT_NAME"

    cd "$MAGENTO_SETUP_PROJECT_NAME"

    bin/magento setup:install                                  \
      --base-url="$MAGENTO_SETUP_BASE_URL"                     \
      --db-host="$MAGENTO_SETUP_DB_HOST"                       \
      --db-name="$MAGENTO_SETUP_DB_NAME"                       \
      --db-user="$MAGENTO_SETUP_DB_USER"                       \
      --db-password="$MAGENTO_SETUP_DB_PASSWORD"               \
      --admin-firstname="$MAGENTO_SETUP_ADMIN_FIRSTNAME"       \
      --admin-lastname="$MAGENTO_SETUP_ADMIN_LASTNAME"         \
      --admin-email="$MAGENTO_SETUP_ADMIN_EMAIL"               \
      --admin-user="$MAGENTO_SETUP_ADMIN_USER"                 \
      --admin-password="$MAGENTO_SETUP_ADMIN_PASSWORD"         \
      --language="$MAGENTO_SETUP_LANGUAGE"                     \
      --currency="$MAGENTO_SETUP_CURRENCY"                     \
      --timezone="$MAGENTO_SETUP_TIMEZONE"                     \
      --use-rewrites="$MAGENTO_SETUP_USE_REWRITES"             \
      --search-engine="$MAGENTO_SETUP_SEARCH_ENGINE"           \
      --elasticsearch-host="$MAGENTO_SETUP_ELASTICSEARCH_HOST" \
      --amqp-host="$MAGENTO_SETUP_AMQP_HOST"                   \
      --amqp-port="$MAGENTO_SETUP_AMQP_PORT"                   \
      --amqp-user="$MAGENTO_SETUP_AMQP_USER"                   \
      --amqp-password="$MAGENTO_SETUP_AMQP_PASSWORD"

    # fix files and directories permission and ownership
    find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
    find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
    chown -R :www-data .
    chmod u+x bin/magento

    # disable 2 factor authentication
    bin/magento module:disable -n Magento_TwoFactorAuth

    # add japanese plugin
    composer require veriteworks/m2-japaneselocale
  fi

  cd "$MAGENTO_SETUP_PROJECT_NAME"

  if [[ -z "$MAGENTO_SETUP_DISABLE_AUTO_FIX_APACHE_CONFIG" ]]; then
    sed -i 's;ServerName .*;ServerName '"$SERVER_NAME"';'      \
      /etc/apache2/sites-enabled/000-default.conf
    sed -i 's;DocumentRoot .*;DocumentRoot '"$PROJECT_DIR"';'  \
      /etc/apache2/sites-enabled/000-default.conf
  fi

  if [[ -n "$MAGENTO_SETUP_SAMPLEDATA" ]]; then
    : ${MAGENTO_SETUP_MARKETPLACE_PUBLIC_KEY:?MAGENTO_SETUP_MARKETPLACE_PUBLIC_KEY is required}
    : ${MAGENTO_SETUP_MARKETPLACE_PRIVATE_KEY:?MAGENTO_SETUP_MARKETPLACE_PRIVATE_KEY is required}
    composer config -g http-basic.repo.magento.com             \
      $MAGENTO_SETUP_MARKETPLACE_PUBLIC_KEY                    \
      $MAGENTO_SETUP_MARKETPLACE_PRIVATE_KEY
    bin/magento sampledata:deploy
    bin/magento setup:upgrade
  fi
  set +x
  exec docker-php-entrypoint apache2-foreground
fi
