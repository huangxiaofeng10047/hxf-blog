---
title: '用 Docker 每日自动化备份 MySQL, Postgres 或 MongoDB 并上传到 minio'
date: 2021-07-29 11:38:11
tags: docker 备份
---

由于备份[PostgreSQL](https://www.postgresql.org/)的指令[pg_dump](https://docs.postgresql.tw/reference/client-applications/pg_dump)需要特定版本才可以备份，故制作用[Docker](https://www.docker.com/)容器方式来自己备份，此工具支持[MySQL](https://www.mysql.com/)，PostgreSQL跟[MongoDB](https://www.mongodb.com/)，只要一个docker-compose yaml 档案就可以进行线上的备份，并且上传到minio，另外也可以设定每天晚上固定时间点进行时间备份，也就是饮食所设定的定时任务。没有使用，或者管理机房的朋友们，就可以通过这小工具，进行每天半夜线上备份，避免资料被误判。

使用方式：

```yaml
services:
  minio:
    image: minio/minio:edge
    restart: always
    volumes:
      - data1-1:/data1
    ports:
      - 9000:9000
    environment:
      MINIO_ACCESS_KEY: 1234567890
      MINIO_SECRET_KEY: 1234567890
    command: server /data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  postgres:
    image: postgres:12
    restart: always
    volumes:
      - pg-data:/var/lib/postgresql/data
    logging:
      options:
        max-size: "100k"
        max-file: "3"
    environment:
      POSTGRES_USER: db
      POSTGRES_DB: db
      POSTGRES_PASSWORD: db
```

挑选特定资料库版本的Docker Image

```yaml
backup_postgres:
    image: appleboy/docker-backup-database:postgres-12
    logging:
      options:
        max-size: "100k"
        max-file: "3"
    environment:
      STORAGE_DRIVER: s3
      STORAGE_ENDPOINT: minio:9000
      STORAGE_BUCKET: test
      STORAGE_REGION: ap-northeast-1
      STORAGE_PATH: backup_postgres
      STORAGE_SSL: "false"
      STORAGE_INSECURE_SKIP_VERIFY: "false"
      ACCESS_KEY_ID: 1234567890
      SECRET_ACCESS_KEY: 1234567890

      DATABASE_DRIVER: postgres
      DATABASE_HOST: postgres:5432
      DATABASE_USERNAME: db
      DATABASE_PASSWORD: db
      DATABASE_NAME: db
      DATABASE_OPTS:
```

Final Step: [manage bucket lifecycle](https://docs.min.io/docs/minio-bucket-lifecycle-guide.html) using [MinIO Client (mc)](https://docs.min.io/docs/minio-client-quickstart-guide.html).

```shell
$ mc ilm import minio/test <<EOF
{
    "Rules": [
        {
            "Expiration": {
                "Days": 7
            },
            "ID": "backup_postgres",
            "Filter": {
                "Prefix": "backup_postgres/"
            },
            "Status": "Enabled"
        }
    ]
}
EOF
```

上面设定是快乐的备份，也就是手动使用`docker-compose up backup_postgres`就可以进行一次备份，当然可以每天晚上来备份

```yaml
 backup_mysql:
    image: appleboy/docker-backup-database:mysql-8
    logging:
      options:
        max-size: "100k"
        max-file: "3"
    environment:
      STORAGE_DRIVER: s3
      STORAGE_ENDPOINT: minio:9000
      STORAGE_BUCKET: test
      STORAGE_REGION: ap-northeast-1
      STORAGE_PATH: backup_mysql
      STORAGE_SSL: "false"
      STORAGE_INSECURE_SKIP_VERIFY: "false"
      ACCESS_KEY_ID: 1234567890
      SECRET_ACCESS_KEY: 1234567890

      DATABASE_DRIVER: mysql
      DATABASE_HOST: mysql:3306
      DATABASE_USERNAME: root
      DATABASE_PASSWORD: db
      DATABASE_NAME: db
      DATABASE_OPTS:

      TIME_SCHEDULE: "@daily"
      TIME_LOCATION: Asia/Shanghai
```

`TIME_LOCATION`可以设为上海时区，美食预设会是UTC+8时间。更多详细的设置可以[参考文件](https://github.com/appleboy/docker-backup-database)。

```
./mc alias set minio http://minio:9000 1234567890 1234567890
./mc mb minio/test
./mc ilm import minio/test <<EOF
{
    "Rules": [
        {
            "Expiration": {
                "Days": 7
            },
            "ID": "backup_postgres",
            "Filter": {
                "Prefix": "backup_postgres/"
            },
            "Status": "Enabled"
        }
    ]
}
EOF
```
