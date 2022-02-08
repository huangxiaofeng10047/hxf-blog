---
title: Day18 該如何實現自動化
date: 2021-09-08 11:50:52
tags:
- devops
categories: 
- devops
---

從第十一天到第十七天的內容，一路完成了「建置 Harbor」、「建置 GitLab」、「建置 Drone」、「Drone 範例操作」，那麼該試著使用 `Drone` 在實際的環境中將重複的事情自動化，嘗試想著以下情境：

-   情境開始：

在公司服務已經全容器化，開發完畢後需要先將程式碼上至「開發」環境檢測，接著自我驗證完畢後需要在送至「QA」環境檢測，最後當「QA」團隊驗證完畢後才能夠將程式「Release」環境，比較嚴謹的團隊甚至還會再有一個「前哨」的擬正式環境。

<!--more-->

所以如果要將程式上至每個環境，就必需於本機完成 `build images` 並且將 `build` 好的映像檔推至 `Harbor` 私有庫，或者每個環境共用一個 `image` 但仍然需要工程師手動 `build images` 並且將 `build` 好的映像檔推至 `Harbor` 私有庫，每次都必須要輸入 `docker build` 的指令想到就很煩，所以小弟就衍生了以下的思想。

![](https://i.imgur.com/8NcVIIj.png)

因為小弟太懶惰了，所以指希望在小弟開發完畢後，只需要執行 `git push` 後續的動作完全都由 `Drone` 自動完成，看完流程圖後希望 `Drone` 幫我完成 `build image` 至 `Harbor`，所以來拆解一下 `Drone` 的步驟，讓明天的示範內容可以更順利。

1.  clone project (drone default action)
2.  編譯程式碼
3.  讀取 `Dockerfile` 並 `build` 成映像檔
4.  推至 `Harbor` 私有庫

今天的內容就寫到這，明天會一步一步的示範該如何撰寫今天借少的流程。
