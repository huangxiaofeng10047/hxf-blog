---
title: Day14 使用 Docker 快速建置 GitLab
date: 2021-09-07 16:19:55
tags:
- devops
categories: 
- devops
---

> 1.於本機環境示範  
> 2.本日內容參考[Docker GitLab](http://www.damagehead.com/docker-gitlab/)，並些許做修正

今天會示範如何透過 `docker` 建立 `gitlab` ，並設定 `OAuth` 取得 `Application ID` & `Secret`，為什麼需要設定 `OAuth`， 因為 `Drone` 會透過 `Application ID` & `Secret` 進行用戶驗證。

<!--more-->

-   首先下載 [Docker GitLab](https://github.com/neil605164/CI-CD/tree/master/GitLab)
    
-   調整 .env 檔內容
    
    -   GITLAB\_SERVER: or
    -   GITLAB\_WEB\_PORT: Gitlab 網頁 Port
    -   GITLAB\_SSH\_PORT: ssh Port
    -   DB\_USER: postgresql 帳號
    -   DB\_PASS: postgresql 密碼
    -   DB\_NAME： postgresql 資料庫名稱
-   調整 yaml 檔內容
    
    -   倘若本機有設定 host，需一併設定容器內的 host，請開啟 `extra_hosts` 並調整設定(線上環境不建議使用該設定)
-   建置 GitLab
    
    -   修改完成後，直接執行 `docker-compose up -d`，並靜待幾分鐘讓DB初始化

以上四個步驟即可完成 `GitLab` 建置，接著可以開啟 [GitLab頁面](http://localhost:10080/)，並記得設定密碼

**預設帳號：root**  
![](https://i.imgur.com/rwoZfr7.png)

-   登入後，點選左上角「板手」圖示  
    ![](https://i.imgur.com/KV0bNzb.png)
    
-   點選「Applications」->「New application」  
    ![](https://i.imgur.com/l8T4wrm.png)
    
-   填寫 Outh
    
    -   Name: 可以自行定義
    -   Redirect URI: 表示驗證通過後，會倒轉置 `Drone`的 login 頁面，需填入 `http://YOUR_DRONE_HOST/login`
    -   Scopes: 選項記得要勾選 api，使 `Drone`可以有權限操作`GitLab API`  
        ![](https://i.imgur.com/ML5ktev.png)
-   設定完成後，可以看到以下畫面
    
    -   `Application ID` 與 `Secret`，明天建置 `Drone` 時會使用到
    -   `Callback URL` 隨時都可以更換  
        ![](https://i.imgur.com/JhhMznG.png)

以上就是使用 `docker` 建置 `gitlab` 外加設定 `outh` 認證方式
