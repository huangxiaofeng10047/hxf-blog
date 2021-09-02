---
title: Day12 什么是CICD
date: 2021-09-02 08:32:39
tags:
- devops
categories: 
- devops
---
那么何谓`DevOps``CICD``CICD``CICD`

那么何谓`CICD`
<!--more-->
但实际上 `CI``CD``CICD``git push``Gitlab``Server``Jenkins`

![](https://i.imgur.com/aCKJLPK.png)

**那么CI & CD 分别负责哪些工作，且看下方介绍：**

## CI(Continuous integration)，即是「持续整合」

-   流程：
    
    -   「程式建置」  
        
    -   「程式测试」  
        
-   目的：
    
    -   将低人为疏失风险
    -   减少人工手动的反覆步骤
    -   进行版控管制
    -   增加系统一致性与透明化
    -   减少团队Loading

## CD(Continuous Deployment)，即是「持续布署」

-   流程：
    
    -   「部署服务」  
        
-   目的：
    
    -   保持每次更新程式都可顺畅完成
    -   确保服务存活

所以CICD 通常会遵循着以下流程：

![](https://i.imgur.com/V5nuckV.png)  
(取至网路)

## CICD 工具介绍

-   GitLab (版控工具)
-   GitHub (版控工具)
-   Jenkins (自动化建置工具)
-   Drone (自动化建置工具)
-   Circle (自动化建置工具)
-   Docker (迅速布署环境工具)
-   K8S (管理Docker Container 工具)
-   Helm (快速建置各环境K8S 工具)
-   Grafana (機器數據監控工具)
-   ELK (Log 蒐集工具)
-   Telegram (通訊、錯誤通知工具)
-   Slack (通訊、錯誤通知工具)

可以看一下此流程圖：

![](https://i.imgur.com/wZSqPY2.png)

-   當 `Jenkins` 或者 `ELK`、`Grafana` 等監控工具發現異常時，可即時傳送至`Telegram` 等通訊軟體作為提醒。