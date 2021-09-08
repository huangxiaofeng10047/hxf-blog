---
title: Day19 實際演練 - 自動 Build Image
date: 2021-09-08 11:56:00
tags:
- devops
categories: 
- devops
---

首先我們要先準備一份 `code`(以 golang 示範) 跟一份 `Dockerfile` 檔案，稍後將由 `Drone` 自動將程式 `build` 成 `Image`

-   專案結構(HelloWorld)：  
    .  
    ├── vendor (管理 golang pkg 專用)  
    ├── Dockerfile  
    ├── .drone.yml  
    └── main.go
    
    <!--more-->

```

package main

import (
"net/http"

"github.com/gin-gonic/gin"
)

func main() {
r := gin.Default()
r.GET("/", func(c *gin.Context) {

c.String(http.StatusOK, "Hello World")
})

r.Run() 
}

```

```


FROM golang:1.11.2-alpine AS build


COPY . /go/src/Project
WORKDIR /go/src/Project


RUN go build -o project


FROM alpine

COPY --from=build /go/src/Project/project /app/project
WORKDIR /app

ENTRYPOINT [ "./project" ]
```

首先準備好以上範例，接著我們準備來執行昨天的四個步驟：

1.  clone project (drone default action)
2.  編譯程式碼
3.  讀取 `Dockerfile` 並 `build` 成映像檔
4.  推至 `Harbor` 私有庫

### Step1: clone project (請先自行於 `Drone` 啟動專案)

完成以下 `yaml` 後，執行 `git push` 將會觸發 `drone` 執行 clone 事件

```

kind: pipeline
type: docker      
name: clone       
```

![](https://i.imgur.com/vBCwugY.png)

### Step2: 編譯程式碼

以 `golang` 來說，若不將程式內有用到的 `pkg` 一併上傳至 `gitlab` 等平台，那麼每次在 `build images` 之前，就必須要先將使用到的 `pkg` 重新對外在拉一次，因此這部份也可以交給 `drone` 自動完成。

```

kind: pipeline
type: docker      
name: clone       

steps:
  - name: build-golang                   
    image: neil605164/plugin-govendor    
    commands:                            
      - mkdir -p /usr/local/go/src/${DRONE_REPO_NAME}                 
      - ls -al vendor                                                 
      - rsync -r  /drone/src/* /usr/local/go/src/${DRONE_REPO_NAME}   
      - cd /usr/local/go/src/${DRONE_REPO_NAME}                       
      - govendor sync                                                 
      - rsync -r /usr/local/go/src/${DRONE_REPO_NAME}/* /drone/src    
      - ls -al vendor                                                 
```

當 `Drone` 編譯程式碼時，會自動至外部 `clone` 有用到的 `pkg`，當編譯完成後，所有有用到的 `pkg` 都會被放置 `vendor` 資料夾底下，如下圖所示：  
![](https://i.imgur.com/9yG9Nge.png)

**備註：**  
步驟二當中使用到的 `neil605164/plugin-govendor` 就是我是先封裝好的 `drone plugin`， 以下是 `neil605164/plugin-govendor` 的 `Dockerfile`

```

FROM golang:1.11.2-alpine


RUN apk add git rsync


RUN go get -u github.com/kardianos/govendor
```

### Step3: 讀取 `Dockerfile` 並 `build` 成映像檔 + 推至 Harbor 私有庫

當程式編譯完成後，當然就是要推到私有庫上啦，在這邊直接採用官方 `plugins/docker` ，這一個現成的 `plugin` 就已經夠方便啦，不僅自動 `build image` 還可以自動推到指定的私有庫，若真的不適合的話也可以透過原本作者寫的在往上疊加自己要的功能上去就好。

```

kind: pipeline
type: docker      
name: clone       

steps:
  - name: build-golang                                                
    image: neil605164/plugin-govendor                                 
    commands:                                                         
      - mkdir -p /usr/local/go/src/${DRONE_REPO_NAME}                 
      - ls -al vendor                                                 
      - rsync -r  /drone/src/* /usr/local/go/src/${DRONE_REPO_NAME}   
      - cd /usr/local/go/src/${DRONE_REPO_NAME}                       
      - govendor sync                                                 
      - rsync -r /usr/local/go/src/${DRONE_REPO_NAME}/* /drone/src    
      - ls -al vendor                                                 
  - name: build-image-push-harbor                   
    image: plugins/docker                           
    settings:
      username:                                     
        from_secret: docker_username
      password:                                     
        from_secret: docker_password
      repo: <harbor url> /library/golang-hello      
      tags: latest                                   
      registry: <harbor url>                        
```

![](https://i.imgur.com/U6FDAVt.png)

![](https://i.imgur.com/7tm2AFt.png)

今天就是範到這邊啦，以上步驟就完成了透過 `drone` 自動「編譯程式碼」、「build image」、「push image」三個動做，這樣是不是只需要寫一次發布腳本，接下來的流程每次都由 `drone` 自動完成。
