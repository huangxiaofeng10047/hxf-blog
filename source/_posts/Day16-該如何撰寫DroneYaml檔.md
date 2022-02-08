---
title: Day16 該如何撰寫DroneYaml檔
date: 2021-09-08 10:59:56
tags:
- devops
categories: 
- devops
---

花了兩天的時間完成了 `Gitlab` 與 `Drone` 的建置，那麼也該來示範一下該如何觸發 `Drone` 執行發布事件。

<!--more-->

-   首先手動到 Gitlab 建置一個專案  
    (以 demo 作為以下示範，我的 [GitHub](https://github.com/neil605164/CI-CD/tree/master/demo) 也可以找到示範用的代碼)  
    ![](https://i.imgur.com/WSK1Aj3.png)
    
-   如果是「本機」環境測試用，記得要開啟 `Gitlab` 本地端的 `webhook`  
    「Settings --> Network --> Outbound requests」  
    ![](https://i.imgur.com/rPOofa5.png)
    
-   接著重新回到 `Drone` 頁面 `Sync Gitlab` 資料  
    按下 `sync` 按鈕後，等待幾秒鐘即可看到 `demo` 專案顯示在 `drone` 首頁啦。  
    ![](https://i.imgur.com/yKKFMhJ.png)
    
-   啟用 `drone` 專案  
    當啟用成功後會看見以下話面，且表示 `Gitlab` 與`drone` 的 `webhook` 已經建立成功。  
    ![](https://i.imgur.com/bbrtB3h.png)  
    ![](https://i.imgur.com/uKOO5Qz.png)
    

以上的步驟就完成了，接著可以開始撰寫 `.drone.yml` [官方教學文件](https://docs.drone.io/)

**備註:Drone 0.8 與 1.0 後的 `yaml` 檔案撰寫差異很大，需要在依據官方文件做參考，以下示範1.0之後的版本 [Drone 0.8 文件](https://0-8-0.docs.drone.io/getting-started/)**

在 `yaml`檔案中，除了原本的 `clone` 事件外，還有三個事件分別是「host、echo、dev\_action」，

-   host: 打印出容器內 `/etc/hosts` 內容
-   echo: 印出 `78523` 內容
-   dev-action: 印出 `111111` 內容

```
kind: pipeline
type: docker      # 在 Docker 內部執行管道命令
name: clone       # 可自行定義的名稱

steps:
  # 事件一
  - name: host                           # 事件一：可自行定義的名稱
    image: alpine                        # 使用 alpine 容器
    commands:                            # 預執行的 shell 指令，這邊印出 hosts 內容
      - cat /etc/hosts
    when:                                # 無論 clone 成功或失敗，都會跑該事件
      status: [ success, failure ]
  # 事件二
  - name: echo                           # 事件二：可自行定義的名稱
    image: plugins/git                   # 使用 plugins/git  容器
    commands:                            # 預執行的 shell 指令，這邊印出 78523 內容
    - echo "78523"
    when:                                # 當觸發條件為 master 分支時會執行的動作
      branch:
      - master
  # 事件三
  - name: dev_action                     # 事件三：可自行定義的名稱
    image: plugins/git                   # 使用 plugins/git  容器
    commands:                            # 預執行的 shell 指令，這邊印出 111111 內容
    - echo "111111"
    when:                                # 當觸發條件為 develop 分支時會執行的動作
      branch:
      - develop

trigger:     # 觸發 pipeline 條件，分支為 master，且進行 push 行為
  branch: 
  - master
  event:
  - push
```

撰寫完 `yaml` 檔案後，只需要在 `master` 分支執行 `push` 行為，接下來 `Gitlab` 會自動 `tigger Drone` 執行事件。  
![](https://i.imgur.com/kSdiXl2.png)
