---
title: Day20 Let's Kubernetes
date: 2021-09-08 13:20:45
tags:
  - devops
categories:
  - devops
---

> docker container 變多惹，好難管理....  
> k8s 是什麼...

![](https://i.imgur.com/MH6M9VM.png)

終於來到 `DevOps` 現今最夯的技術 `Kubernetes` 啦，先說說為什麼我會介紹使用 `Kubernete` ，隨著團隊的服務越來越多相對的 `container` 數量也越來越龐大，想當然的如果 `container` 異常就必須查看錯誤問題，但是 `container` 卻分散於各處的「`VM`」管理上相當不容易，除了「`container`」 數量增加，「`VM`」的數量當然也會跟著增加，當時我就在想...能不能有什麼東西是可以統一管理 `container` 的工具呢？

<!--more-->

當時就有朋友介紹了 `docker swarm` 跟 `Kubernete`，然後就開始踏上這一條不歸路了，起初有點害怕面對 `Kubernete`，因為有很多人都說 `Kubernete` 不易學習，而且安裝上也非常的不容易，所以逃避了一陣子跑去學了 `docker swarm`， 碰了 `docker swarm` 一段時間後突然有個想法～為什麼要學習管理 `container` 工具不學學看現在最潮最可以裝逼的技術呢，哈哈哈...所以就是因為想要學一個最屌的東西然後就開始了我的 `Kubernete` 道路，在學習 `Kubernete` 的道路上，最感謝的就是這一篇的作者 [Kubernetes 教學](https://ithelp.ithome.com.tw/articles/10192401) ，小弟就是看著這30天的文章學習 `Kubernete` 的技術，在加上看完這30天的內容後，公司突然說要將服務都轉移到 `Kubernete` 上，就是這麼的偶然跟幸運的半推半將就讓我有機會可以練習剛剛學完的 `Kubernete` 在加上導入 `Kubernete` 期間還有一個很強大的前輩可以詢問，真的是讓人非常安心的處理，所以很感謝這一段時間陪伴我學習 `Kubernete` 的所有人，好啦～前面這麼多廢話，是時候該來介紹一下什麼是 `Kubernete` 。

___

## What is Kubernete ?

`Kubernete` 又稱為 `k8s` 是一個用於「佈署」、「自動擴展服務」、「管理容器」的偉大工具，雖然安裝上不太容易，但是只要能更靈活運用 `Kubernete` 就能夠減少許多需要進到「`VM`」的時間，未來的 `Kubernete` 發展聽說還能夠跨越機房與群集進行佈署。

講的白話一點就是，當你設定好服務的規則後，若服務 `loading` 拉高並且到達設定規則後， `Kubernete` 會自動幫你建置一個新的 `container` 服務，減少其他服務的 `loading` 達到一個自動橫向擴展的行為，且服務死亡或異常時也會嘗試自動先生出一個新的 `container` 在將就的服務移除。

## etcd

在 `Kubernete` 中 `etcd` 可以說是最重要的資料，如果你的 `master` 機器死亡，且 `etcd` 的資料有定期備份，那麼只需要將 `etcd` 匯入新的 `master` 機器，所有的服務就又恢復正常啦。

那麼到底什麼是 `etcd` ，`etcd`是 `Kubernete` 永久性的資料 當我們在執行 `Kubernete` 命令時，命令請求會送往 `master` 機器做驗證並執行 `Kubernete API` 行為，此外 `etcd` 本身也紀錄了各台 worker 機器的服務的資料，所以這麼重要的資料當然不能更只有單一一台 `master` 作為儲存，為了預防 `etcd` 資料遺失，官網建議 3 或 5 個的節點作為 etcd cluster [官方文件](https://k8smeetup.github.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)。

接下來剩沒幾天，所以我會以概念為主，明天開始會講解 `Kubernete` 更詳細的內容。
