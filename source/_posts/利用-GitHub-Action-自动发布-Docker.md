---
title: 利用 GitHub Action 自动发布 Docker
date: 2021-05-08 16:45:54
tags:
---

[![](https://i.loli.net/2021/03/26/UIZzdFfNb7exGvE.jpg)](https://i.loli.net/2021/03/26/UIZzdFfNb7exGvE.jpg)

# [](#前言 "前言")前言

最近公司内部项目的发布流程接入了 `GitHub Actions`，整个体验过程还是比较美好的；本文主要目的是对于没有还接触过 `GitHub Actions`的新手，能够利用它快速构建自动测试及打包推送 `Docker` 镜像等自动化流程。

# [](#创建项目 "创建项目")创建项目

本文主要以 `Go` 语言为例，当然其他语言也是类似的，与语言本身关系不大。

这里我们首先在 `GitHub` 上创建一个项目，编写了几段简单的代码 `main.go`：

<table><tbody><tr><td class="gutter"><pre><div class="line">1</div><div class="line">2</div><div class="line">3</div><div class="line">4</div><div class="line">5</div><div class="line">6</div><div class="line">7</div><div class="line">8</div><div class="line">9</div></pre></td><td class="code"><pre><div class="line"><span class="keyword">var</span> version = <span class="string">"0.0.1"</span></div><div class="line"></div><div class="line"><span class="function"><span class="keyword">func</span> <span class="title">GetVersion</span><span class="params">()</span> <span class="title">string</span></span> {</div><div class="line">	<span class="keyword">return</span> version</div><div class="line">}</div><div class="line"></div><div class="line"><span class="function"><span class="keyword">func</span> <span class="title">main</span><span class="params">()</span></span> {</div><div class="line">	fmt.Println(GetVersion())</div><div class="line">}</div></pre></td></tr></tbody></table>

内容非常简单，只是打印了了版本号；同时配套了一个单元测试 `main_test.go`：

<table><tbody><tr><td class="gutter"><pre><div class="line">1</div><div class="line">2</div><div class="line">3</div><div class="line">4</div><div class="line">5</div><div class="line">6</div><div class="line">7</div><div class="line">8</div><div class="line">9</div><div class="line">10</div><div class="line">11</div><div class="line">12</div><div class="line">13</div><div class="line">14</div><div class="line">15</div></pre></td><td class="code"><pre><div class="line"><span class="function"><span class="keyword">func</span> <span class="title">TestGetVersion1</span><span class="params">(t *testing.T)</span></span> {</div><div class="line">	tests := []<span class="keyword">struct</span> {</div><div class="line">		name <span class="keyword">string</span></div><div class="line">		want <span class="keyword">string</span></div><div class="line">	}{</div><div class="line">		{name: <span class="string">"test1"</span>, want: <span class="string">"0.0.1"</span>},</div><div class="line">	}</div><div class="line">	<span class="keyword">for</span> _, tt := <span class="keyword">range</span> tests {</div><div class="line">		t.Run(tt.name, <span class="function"><span class="keyword">func</span><span class="params">(t *testing.T)</span></span> {</div><div class="line">			<span class="keyword">if</span> got := GetVersion(); got != tt.want {</div><div class="line">				t.Errorf(<span class="string">"GetVersion() = %v, want %v"</span>, got, tt.want)</div><div class="line">			}</div><div class="line">		})</div><div class="line">	}</div><div class="line">}</div></pre></td></tr></tbody></table>

我们可以执行 `go test` 运行该单元测试。

<table><tbody><tr><td class="gutter"><pre><div class="line">1</div><div class="line">2</div><div class="line">3</div></pre></td><td class="code"><pre><div class="line">$ go <span class="built_in">test</span>                          </div><div class="line">PASS</div><div class="line">ok      <a class="vglnk" href="http://github.com/crossoverJie/go-docker" rel="nofollow"><span>github</span><span>.</span><span>com</span><span>/</span><span>crossoverJie</span><span>/</span><span>go</span><span>-</span><span>docker</span></a>       1.729s</div></pre></td></tr></tbody></table>

## [](#自动测试 "自动测试")自动测试

当然以上流程完全可以利用 `Actions` 自动化搞定。

首选我们需要在项目根路径创建一个 _\`.github/workflows/_.yml\`\* 的配置文件，新增如下内容：

<table><tbody><tr><td class="gutter"><pre><div class="line">1</div><div class="line">2</div><div class="line">3</div><div class="line">4</div><div class="line">5</div><div class="line">6</div><div class="line">7</div><div class="line">8</div><div class="line">9</div><div class="line">10</div></pre></td><td class="code"><pre><div class="line"><span class="attr">name:</span> go-docker</div><div class="line"><span class="attr">on:</span> push</div><div class="line"><span class="attr">jobs:</span></div><div class="line"><span class="attr">  test:</span></div><div class="line"><span class="attr">    runs-on:</span> ubuntu-latest</div><div class="line"><span class="attr">    if:</span> github.ref == <span class="string">'refs/heads/main'</span> || startsWith(github.ref, <span class="string">'refs/tags'</span>)</div><div class="line"><span class="attr">    steps:</span></div><div class="line"><span class="attr">      - uses:</span> actions/checkout@v2</div><div class="line"><span class="attr">      - name:</span> Run Unit Tests</div><div class="line"><span class="attr">        run:</span> go test</div></pre></td></tr></tbody></table>

简单解释下：

* `name` 不必多说，是为当前工作流创建一个名词。
* `on` 指在什么事件下触发，这里指代码发生 `push` 时触发，更多事件定义可以参考官方文档：

[Events that trigger workflows](https://docs.github.com/en/actions/reference/events-that-trigger-workflows)

* `jobs` 则是定义任务，这里只有一个名为 `test` 的任务。

该任务是运行在 `ubuntu-latest` 的环境下，只有在 `main` 分支有推送或是有 `tag` 推送时运行。

运行时会使用 `actions/checkout@v2` 这个由他人封装好的 `Action`，当然这里使用的是由官方提供的拉取代码 `Action`。

* 基于这个逻辑，我们可以灵活的分享和使用他人的 `Action` 来简化流程，这点也是 `GitHub Action`扩展性非常强的地方。

最后的 `run` 则是运行自己命令，这里自然就是触发单元测试了。

* 如果是 Java 便可改为 `mvn test`.

之后一旦我们在 `main` 分支上推送代码，或者有其他分支的代码合并过来时都会自动运行单元测试，非常方便。

[![](https://i.loli.net/2021/03/26/K7YuUF2iTJzRpwd.jpg)](https://i.loli.net/2021/03/26/K7YuUF2iTJzRpwd.jpg)

[![](https://i.loli.net/2021/03/26/NbIpDG1vA8fwK4z.jpg)](https://i.loli.net/2021/03/26/NbIpDG1vA8fwK4z.jpg)

与我们本地运行效果一致。

## [](#自动发布 "自动发布")自动发布

接下来考虑自动打包 `Docker` 镜像，同时上传到 `Docker Hub`；为此首先创建 `Dockerfile` ：

<table><tbody><tr><td class="gutter"><pre><div class="line">1</div><div class="line">2</div><div class="line">3</div><div class="line">4</div><div class="line">5</div><div class="line">6</div><div class="line">7</div><div class="line">8</div><div class="line">9</div><div class="line">10</div></pre></td><td class="code"><pre><div class="line"><span class="keyword">FROM</span> golang:<span class="number">1.15</span> AS builder</div><div class="line">ARG VERSION=<span class="number">0.0</span>.<span class="number">10</span></div><div class="line"><span class="keyword">WORKDIR</span><span class="bash"> /go/src/app</span></div><div class="line"><span class="keyword">COPY</span><span class="bash"> main.go .</span></div><div class="line"><span class="keyword">RUN</span><span class="bash"> go build -o main -ldflags=<span class="string">"-X 'main.version=<span class="variable">${VERSION}</span>'"</span> main.go</span></div><div class="line"></div><div class="line"><span class="keyword">FROM</span> debian:stable-slim</div><div class="line"><span class="keyword">COPY</span><span class="bash"> --from=builder /go/src/app/main /go/bin/main</span></div><div class="line"><span class="keyword">ENV</span> PATH=<span class="string">"/go/bin:${PATH}"</span></div><div class="line"><span class="keyword">CMD</span><span class="bash"> [<span class="string">"main"</span>]</span></div></pre></td></tr></tbody></table>

这里利用 `ldflags` 可在编译期间将一些参数传递进打包程序中，比如打包时间、go 版本、git 版本等。

这里只是将 `VERSION` 传入了 `main.version` 变量中，这样在运行时就便能取到了。

<table><tbody><tr><td class="gutter"><pre><div class="line">1</div><div class="line">2</div><div class="line">3</div></pre></td><td class="code"><pre><div class="line">docker build -t go-docker:last .</div><div class="line">docker run --rm go-docker:0.0.10</div><div class="line">0.0.10</div></pre></td></tr></tbody></table>

接着继续编写 `docker.yml` 新增自动打包 `Docker` 以及推送到 `docker hub` 中。

<table><tbody><tr><td class="gutter"><pre><div class="line">1</div><div class="line">2</div><div class="line">3</div><div class="line">4</div><div class="line">5</div><div class="line">6</div><div class="line">7</div><div class="line">8</div><div class="line">9</div><div class="line">10</div><div class="line">11</div><div class="line">12</div><div class="line">13</div><div class="line">14</div><div class="line">15</div><div class="line">16</div><div class="line">17</div><div class="line">18</div><div class="line">19</div><div class="line">20</div><div class="line">21</div><div class="line">22</div><div class="line">23</div><div class="line">24</div><div class="line">25</div><div class="line">26</div><div class="line">27</div><div class="line">28</div><div class="line">29</div><div class="line">30</div><div class="line">31</div><div class="line">32</div><div class="line">33</div><div class="line">34</div><div class="line">35</div><div class="line">36</div><div class="line">37</div><div class="line">38</div><div class="line">39</div><div class="line">40</div></pre></td><td class="code"><pre><div class="line"><span class="attr">deploy:</span></div><div class="line"><span class="attr">    runs-on:</span> ubuntu-latest</div><div class="line"><span class="attr">    needs:</span> test</div><div class="line"><span class="attr">    if:</span> startsWith(github.ref, <span class="string">'refs/tags'</span>)</div><div class="line"><span class="attr">    steps:</span></div><div class="line"><span class="attr">      - name:</span> Extract Version</div><div class="line"><span class="attr">        id:</span> version_step</div><div class="line"><span class="attr">        run:</span> <span class="string">|</span></div><div class="line">          echo "##[set-output name=version;]VERSION=${GITHUB_REF#$"refs/tags/v"}"</div><div class="line">          echo "##[set-output name=version_tag;]$GITHUB_REPOSITORY:${GITHUB_REF#$"refs/tags/v"}"</div><div class="line">          echo "##[set-output name=latest_tag;]$GITHUB_REPOSITORY:latest"</div><div class="line"></div><div class="line"><span class="attr">      - name:</span> Set up QEMU</div><div class="line"><span class="attr">        uses:</span> docker/setup-qemu-action@v1</div><div class="line"></div><div class="line"><span class="attr">      - name:</span> Set up Docker Buildx</div><div class="line"><span class="attr">        uses:</span> docker/setup-buildx-action@v1</div><div class="line"></div><div class="line"><span class="attr">      - name:</span> Login to DockerHub</div><div class="line"><span class="attr">        uses:</span> docker/login-action@v1</div><div class="line"><span class="attr">        with:</span></div><div class="line"><span class="attr">          username:</span> ${{ secrets.DOCKER_USER_NAME }}</div><div class="line"><span class="attr">          password:</span> ${{ secrets.DOCKER_ACCESS_TOKEN }}</div><div class="line"></div><div class="line"><span class="attr">      - name:</span> PrepareReg Names</div><div class="line"><span class="attr">        id:</span> read-docker-image-identifiers</div><div class="line"><span class="attr">        run:</span> <span class="string">|</span></div><div class="line">          echo VERSION_TAG=$(echo $<span class="template-variable">{{ steps.version_step.outputs.version_tag }}</span> | tr '[:upper:]' '[:lower:]') &gt;&gt; $GITHUB_ENV</div><div class="line">          echo LASTEST_TAG=$(echo $<span class="template-variable">{{ steps.version_step.outputs.latest_tag  }}</span> | tr '[:upper:]' '[:lower:]') &gt;&gt; $GITHUB_ENV</div><div class="line"></div><div class="line"><span class="attr">      - name:</span> Build and push Docker images</div><div class="line"><span class="attr">        id:</span> docker_build</div><div class="line"><span class="attr">        uses:</span> docker/build-push-action@v2<span class="number">.3</span><span class="number">.0</span></div><div class="line"><span class="attr">        with:</span></div><div class="line"><span class="attr">          push:</span> <span class="literal">true</span></div><div class="line"><span class="attr">          tags:</span> <span class="string">|</span></div><div class="line">            $<span class="template-variable">{{env.VERSION_TAG}}</span></div><div class="line">            $<span class="template-variable">{{env.LASTEST_TAG}}</span></div><div class="line"><span class="attr">          build-args:</span> <span class="string">|</span></div><div class="line">            $<span class="template-variable">{{steps.version_step.outputs.version}}</span></div></pre></td></tr></tbody></table>

新增了一个 `deploy` 的 job。

<table><tbody><tr><td class="gutter"><pre><div class="line">1</div><div class="line">2</div></pre></td><td class="code"><pre><div class="line"><span class="attr">needs:</span> test</div><div class="line"><span class="attr">if:</span> startsWith(github.ref, <span class="string">'refs/tags'</span>)</div></pre></td></tr></tbody></table>

运行的条件是上一步的单测流程跑通，同时有新的 `tag` 生成时才会触发后续的 `steps`。

`name: Login to DockerHub`

在这一步中我们需要登录到 `DockerHub`，所以首先需要在 GitHub 项目中配置 hub 的 `user_name` 以及 `access_token`.

[![](https://i.loli.net/2021/03/26/A8DtcYazfU1HC7O.jpg)](https://i.loli.net/2021/03/26/A8DtcYazfU1HC7O.jpg)

[![](https://i.loli.net/2021/03/26/XI8u4nU6lEP1bCF.jpg)](https://i.loli.net/2021/03/26/XI8u4nU6lEP1bCF.jpg)

配置好后便能在 action 中使用该变量了。

[![](https://i.loli.net/2021/03/26/KzOQB8L7SRFDVNr.jpg)](https://i.loli.net/2021/03/26/KzOQB8L7SRFDVNr.jpg)

这里使用的是由 docker 官方提供的登录 action\(`docker/login-action`\)。

有一点要非常注意，我们需要将镜像名称改为小写，不然会上传失败，比如我的名称中 `J` 字母是大写的，直接上传时就会报错。

[![](https://i.loli.net/2021/03/26/a5WBhtEorzelfOK.jpg)](https://i.loli.net/2021/03/26/a5WBhtEorzelfOK.jpg)

所以在上传之前先要执行该步骤转换为小写。

[![](https://i.loli.net/2021/03/26/LPcNBvznGqEd9jy.jpg)](https://i.loli.net/2021/03/26/LPcNBvznGqEd9jy.jpg)

最后再用这两个变量上传到 Docker Hub。

[![](https://i.loli.net/2021/03/26/cw4EekaZXpJi1Kh.jpg)](https://i.loli.net/2021/03/26/cw4EekaZXpJi1Kh.jpg)

今后只要我们打上 `tag` 时，`Action` 就会自动执行单测、构建、上传的流程。

# [](#总结 "总结")总结

`GitHub Actions` 非常灵活，你所需要的大部分功能都能在 `marketplace` 找到现成的直接使用，

比如可以利用 `ssh` 登录自己的服务器，执行一些命令或脚本，这样想象空间就很大了。

使用起来就像是搭积木一样，可以很灵活的完成自己的需求。

参考链接：

[How to Build a CI/CD Pipeline with Go, GitHub Actions and Docker](https://tonyuk.medium.com/how-to-build-a-ci-cd-pipeline-with-go-github-actions-and-docker-3c69e50b6043)