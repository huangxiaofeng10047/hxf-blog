---
title: gitea启动报错
date: 2021-08-05 17:21:08
tags:
---

lib/gitea/gitea
❯ cp gitea.db gitea.db.20210805

lib/gitea/gitea
❯ sqlite3 gitea.db
SQLite version 3.36.0 2021-06-18 18:36:39
Enter ".help" for usage hints.
sqlite>  `UPDATE version SET version=186 WHERE id=1;`
   ...> UPDATE version SET version=186 WHERE id=1;
Error: near "`UPDATE version SET version=186 WHERE id=1;`": syntax error
sqlite> UPDATE version SET version=186 WHERE id=1;
sqlite>

