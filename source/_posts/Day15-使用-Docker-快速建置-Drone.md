---
title: Day15 使用 Docker 快速建置 Drone
date: 2021-09-08 10:57:14
tags:
  - devops
categories: 
  - devops
---

> 1.於本機環境示範  
> 2.本日內容參考[Docker Drone](https://chunkai.me/2018/06/18/setting-up-drone-for-gitlab-integration/)，並些許做修正  
> 3. [完整 Drone yaml](https://github.com/neil605164/CI-CD/tree/master/Drone)

今天會示範使用 `Docker` 安裝 `Drone` ，並講解 `Drone Yaml` 該如何調整。

<!--more-->

-   clone github 專案

```
$ git clone https://github.com/neil605164/CI-CD.git
```

-   編輯 `/etc/hosts`  
    如果你是照著 github 範本走，那麼第一步驟需要設定 hosts

```
## vi /etc/hosts 增加以下內容，等等開網頁會用到
<your host ip> drone.local.com
```

-   調整 .env 內容
    
    -   DRONE\_SERVER\_HOST：drone.local.com:8090 (drone 對外Port + 網址)
    -   DRONE\_SERVER\_PROTO： http (本機練習沒有走憑證)
    -   DRONE\_GITLAB\_CLIENT\_ID：昨天設置 `Gitlab OAuth` 的 `Application ID`
    -   DRONE\_GITLAB\_CLIENT\_SECRET：昨天設置 `Gitlab OAuth` 的 `Secret`
    -   GITLAB\_SERVER： or
-   調整 `docker-compose.yml` 檔案內容  
    因為是在本機進行測試，若 `Domain` 再沒有 `DNS` 解析情況下，除了本機要設定 `/etc/hosts` 之外，容器內的 `hosts` 也需要進行設定
    

```
## 看到 yml 檔的以下設定，IP 記得調整成自己本機 IP
extra_hosts:
- "drone.local.com:<host ip>"
```

-   建置 Drone
    -   修改完成後，直接執行 `docker-compose up -d`，即可完成 `Drone` 建置

接著可以開啟 [Drone頁面](http://drone.local.com:8090/)，會被要求登入 `GitLab`，並點選「Authorize」進行 Auth 驗證

![](https://i.imgur.com/CdAxLDk.png)  
![](https://i.imgur.com/F73OHw2.png)

接著跳轉回到 `drone` 首頁，表示 `Drone` 安裝成功  
![](https://i.imgur.com/d3PELql.png)

今天就講到這啦～明天會示範 `Gitlab` 該如何觸發 `Drone` 執行 `pipeline` 事件。

