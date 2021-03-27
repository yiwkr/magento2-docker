Dockerfile and docker-compose.yml for magento2
==============================================

Magentoお試し用のDockerfileとdocker-compose.ymlです。

## Installation

env.sampleを.envにリネームしてから.envを編集します。  
（.envで設定した変数はmagento/entrypoint.shスクリプト内で使用されます）

下記2つの変数の値は変更必須です。

```
MAGENTO_SETUP_MARKETPLACE_PUBLIC_KEY=PUBLIC_KEY
MAGENTO_SETUP_MARKETPLACE_PRIVATE_KEY=PRIVATE_KEY
```

Elasticsearchのデータ保存先のディレクトリを作成します。

```
mkdir -p volumes/elasticsearch/data/
sudo chmod g+rwx volumes/elasticsearch/data/
sudo chgrp 0 volumes/elasticsearch/data/
```

コンテナを起動します。初回はイメージのビルドとMagentoのインストールが走るため時間がかかります。

```
docker-compose up -d
```

インストールの進捗をログから確認します。

```
docker-compose logs -f magento
```

インストールが完了したらAdmin URIの確認します。

```
docker-compose run --rm magento magento2/bin/magento info:adminuri
```

cronを設定します。

```
*/15 * * * * /usr/local/bin/docker-compose -f /<absolute path to this repository's root directory>/docker-compose.yml run --rm magento /usr/local/bin/php /var/www/html/magento2/bin/magento cron:run 2>&1 | grep -v 'Ran jobs by schedule' >> /tmp/magento.cron.log
```

## Add sample data

サンプルデータを追加します。

```
docker-compose exec magento magento2/bin/magento sampledata:deploy
docker-compose exec magento magento2/bin/magento setup:upgrade
```

