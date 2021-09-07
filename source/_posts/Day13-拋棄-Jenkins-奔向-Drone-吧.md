---
title: Day13 拋棄 Jenkins 奔向 Drone 吧
date: 2021-09-07 15:57:01
tags:
- devops
categories: 
- devops
---

終於有機會可以分享為什麼我們團隊放棄使用 `Jenkins` 改採用 `Drone`，接下來的這幾天會介紹 `Drone` 的優點以及該如何讓 `Drone` 與 `Gitlab` 溝通，打造一個以`Docker` 容器建置的「持續交付平台」 。

首先說明為什麼我們團隊會放棄使用 `Jenkins`:

<!--more-->

-   每次有新專案需要建置發布事件時，總是需要花費許多時間建置與測試
-   通常改個發布事件後，容易造成故障
-   學習成本高，太多東西要設定，無法讓團隊的每個人都了有時間學習
-   套件不易擴充
-   難以維護，尤其是資深前輩離職後，更難以接管。
-   頁面複雜功能性多，但實際上用到的不多，新手難以上手

還是有好多不好使用的缺點想列出來...不過還是趕快介紹主角比較適合

## [Drone](https://drone.io/)

是一套以 Golang 開發的一套 CI/CD 系統工具，建置速度快又便利，只需要幾分鐘的時間執行 `docker-compose.yml` 即完成 Drone 建置

![](https://i.imgur.com/16aDzSk.png)

### 優點：

-   任何步驟都在 Docker Container 內執行，完成後會自動移除 Container 不會在機器上留下不必要的垃圾資料。
-   學習成本低 + 容易維護，新手好上手。
-   透過 .drone.yml 觸發 CI/CD 流程，所以可加入版本控管
-   由 container 執行每個 pipeline 行為，所以支援各種語言
-   支援常見程式碼管理平台(gitlab、github、gittea、gitbucket...)

### 缺點：

-   套件不足時，需要自己開發

### 系統架構：

`Drone` 是透過 `Gitlab WebHook` 觸發發布機制，由 `Drone Server` 接收到工作命令後，分派由 `Drone Agent` 執行 `Pipeline` 動作。  
![](https://i.imgur.com/kUozaiI.png)

### 佈署流程：

下圖為利用 `Drone` CI/CD 工具，執行以下行為：

-   自動測試
-   編譯程式碼
-   建置映像檔
-   佈署程式
-   「成功/失敗」的訊息通知

![](https://i.imgur.com/EkjERYS.png)

明天會介紹如何快速建置 `Drone` 服務並與 Gitlab 溝通。

