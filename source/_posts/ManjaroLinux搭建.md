---


title: ManjaroLinux搭建
date: 2021-08-11 10:23:02
tags: linnux manjarco
---

下载压缩包：Manjarco.zip

解压压缩包如一下目录所示

![image-20210811105044473](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210811105044473.png)

双击Manjarco.exe则进行linux的安装，需要等一会，会告诉安装成功
<!--more-->



查看安装后的命令输入

![image-20210811105147021](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210811105147021.png)

如果成功则可以看见Manjaro的命令。

通过wsl -d Manjaro则可进入到服务器。

`wsl -d Manjaro`

![image-20210811105354401](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210811105354401.png)

### 换源更新[#](https://www.cnblogs.com/zsmumu/p/archlinux-wsl2.html#509598612)

PS: 以下部分都以 root 用户身份运行命令。

```bash
passwd # 设置密码
# 设置软件源
echo 'Server = https://mirrors.neusoft.edu.cn/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist

# 初始化 keyring
pacman-key --init
pacman-key --populate
pacman -Syu # 更新
```

其他镜像源请见通过 [Pacman Mirrorlist 生成器](https://www.archlinux.org/mirrorlist/)生成的[国内源列表](https://www.archlinux.org/mirrorlist/?country=CN&protocol=http&protocol=https&ip_version=4)，用自己学校的更快哦！建议看看 [镜像状态列表](https://www.archlinux.org/mirrors/status/)，使用 Mirror Status 较低的国内镜像站

### 启用 multilib 库[#](https://www.cnblogs.com/zsmumu/p/archlinux-wsl2.html#3927474463)

multilib 库包含 64 位系统中需要的 32 位软件和库。

`vim /etc/pacman.conf`，取消这几行的注释：

```
[multilib]
Include = /etc/pacman.d/mirrorlist
```

并且取消该文件中`#Color`这一行的注释，以启用彩色输出。

### 添加 archlinuxcn 源[#](https://www.cnblogs.com/zsmumu/p/archlinux-wsl2.html#515215996)

Arch Linux 中文社区仓库 是由 Arch Linux 中文社区驱动的非官方用户仓库。包含中文用户常用软件、工具、字体/美化包等。

```bash
vim /etc/pacman.conf
```

在文件末尾加上：

```conf
[archlinuxcn]
Server = https://mirrors.aliyun.com/archlinuxcn/$arch
# 其他的见 https://github.com/archlinuxcn/mirrorlist-repo，最好是用自己学校的
[archlinuxcn]
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
```

然后：

```bash
pacman -Syy
pacman -S archlinuxcn-keyring
```

### 创建用户[#](https://www.cnblogs.com/zsmumu/p/archlinux-wsl2.html#1153411218)

有需要就创建吧。
*注：此处的 yourname 是你要创建的用户名*

```bash
# 新建用户。-m 为用户创建家目录；-G wheel 将用户添加到 wheel 用户组
useradd -m -G wheel xfhuang
# 设置密码
passwd xfhuang
123
123
# 因为 visudo 需要 vi
ln -s /usr/bin/vim /usr/bin/vi
# 编辑 /etc/sudoers
visudo
```

将以下两行行首的`#`去掉

```bash
# %wheel ALL=(ALL) ALL
# %wheel ALL=(ALL) NOPASSWD: ALL
```

在 powershell 中进入到  Manjaro.exe 所在文件夹，设置 WSL 默认登陆用户和默认的 WSL：

```powershell
 Arch.exe  config --default-user xfhuang
wsl -s Manjaro

```

重新打开，就是在 xfhuang用户了。

![image-20211103141941713](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211103141941713.png)

## 安装常用软件[#](https://www.cnblogs.com/zsmumu/p/archlinux-wsl2.html#1880665260)

PS: 这部分以 xfhuang用户身份运行命令。

### 安装 yay[#](https://www.cnblogs.com/zsmumu/p/archlinux-wsl2.html#1538716494)

```bash
sudo pacman -S --needed base-devel openssh
```

出现`:: fakeroot is in IgnorePkg/IgnoreGroup. Install anyway? [Y/n]`，选 n，接下来一直回车即可。

```bash
sudo pacman -S --needed yay
# yay 换源
yay --aururl "https://aur.tuna.tsinghua.edu.cn" --save
```

![image-20211103154829100](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211103154829100.png)

### 安装其他的一些软件[#](https://www.cnblogs.com/zsmumu/p/archlinux-wsl2.html#3500358456)

```bash
sudo pacman -S --needed neofetch lolcat bat tokei tree screenfetch
neofetch | lolcat -a
```

### 安装 gcc、clang、qemu 等[#](https://www.cnblogs.com/zsmumu/p/archlinux-wsl2.html#1080076022)

```bash
sudo pacman -S --needed gcc clang lib32-gcc-libs gdb make binutils git openssh man-pages ccls
```

安装 qemu（有需要就安装吧）：

```bash
sudo pacman -S --needed qemu-arch-extra
```

### 安装 zsh[#](https://www.cnblogs.com/zsmumu/p/archlinux-wsl2.html#2194599011)

给 windows 安装以下字体，并且改变 windows terminal 的字体设置(这里就不细说了)：

- [MesloLGS NF](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Meslo/S/Regular/complete) *powerlevel10k 作者推荐*
- [FiraCode NF](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FiraCode/Regular/complete) *我更喜欢这个*

安装 zsh 并且将其设置为默认 shell：

```bash
sudo pacman -S --needed zsh
# 编辑 /etc/passwd 文件，将 root 用户和 yourname 用户的 /bin/bash 改为 /bin/zsh
# 或者使用 chsh -s /bin/zsh 来改变当前用户的默认shell
sudo vim /etc/passwd
touch ~/.zshrc
# 在yourname用户创建软链接，让root用户也使用yourname用户的.zshrc
# 我觉得这样比较方便
sudo ln -s ~/.zshrc /root/.zshrc
```

### 使用 proxychains 代理终端程序[#](https://www.cnblogs.com/zsmumu/p/archlinux-wsl2.html#2378191044)

可以使用 windows 的 [qv②ray](https://qv2ray.net/)/clash/ssr 等代理软件来代理 wsl 中的程序！先安装 proxychains：

```bash
sudo pacman -S --needed proxychains-ng
```

首先，`sudo vim /etc/proxychains.conf`，

*将`proxy_dns`这一行注释。*

*（这样能够让 proxychains 代理 yay）*

## 问题如下

```bash
$ proxychains yay -S petal
[proxychains] config file found: /etc/proxychains.conf
[proxychains] preloading /usr/lib/libproxychains4.so
[proxychains] DLL init: proxychains-ng 4.14
Get https://aur.archlinux.org/rpc.php?arg%5B%5D=petal&type=info&v=5: dial tcp 224.0.0.1:443: connect: network is unreachable
```



## 解决方法

修改proxychains配置文件，把proxy_dns注释掉。

1. 打开proxychains.conf文件

```bash
$ sudo vim /etc/proxychains.conf
```

1. 找到52行的位置，在proxy_dns前加上#号

```bash
52 # proxy_dns
```

**修改完成后就可以愉快的使用yay了**

如果用的是 WSL 1，那就 `sudo vim /etc/proxychains.conf`，将最后一行的 socks4 127.0.0.1 9095 修改为：

```
socks5 127.0.0.1 7890
```

这个 7890 是我的 qv②ray 的 socks5 端口号，改成你自己的。如果你用的是 WSL 2，由于目前 WSL 2 和 windows 的 ip 不同，我们需要先`cp -f /etc/proxychains.conf ~/.proxychains.conf`，然后在`~/.zshrc`中添加以下内容：

```bash
# 获取windows的ip
export WIN_IP=`cat /etc/resolv.conf | grep nameserver | awk '{print $2}'`
# 删除 ~/.proxychains.conf 中 [ProxyList] 所在行到文件末尾的全部内容
sed -i '/\[ProxyList\]/,$d' ~/.proxychains.conf
# 往文件末尾添加socks5设置，这个 7890 是我的 qv②ray 的 socks5 端口号，改成你自己的
echo '[ProxyList]\nsocks5 '${WIN_IP}' 7890' >> ~/.proxychains.conf
# 设置别名；使用 ~/.proxychains.conf 作为proxychains的配置文件；让proxychains quiet（不输出一大串东西）
alias pc='proxychains4 -q -f ~/.proxychains.conf'
# 用来手动开关代理，建议走 http 协议，因为 wget 不支持 socks5
my_proxy=http://${WIN_IP}:7891
alias p-on='export all_proxy='${my_proxy}' http_proxy='${my_proxy}' https_proxy='${my_proxy}''
alias p-off='unset all_proxy http_proxy https_proxy'
```

然后：

```bash
# 在 yourname 用户中
sudo ln -s ~/.proxychains.conf /root/.proxychains.conf
source ~/.zshrc
```

**如果你发现还是无法代理，[那可能是因为你的代理软件没打开`允许来自局域网的连接`选项](https://github.com/microsoft/WSL/issues/4402#issuecomment-570474468)**

注：`pc ping google.com`是没有效果的，因为 proxychains 只会代理 TCP。

注意为了让wsl能通过代理访问，需要放开防火墙

命令来源：https://github.com/microsoft/WSL/issues/4585

```ps1
# 直接放开 `vEthernet (WSL)` 这张网卡的防火墙
New-NetFirewallRule -DisplayName "WSL" -Direction Inbound -InterfaceAlias "vEthernet (WSL)" -Action Allow
```

参考文档：

 [WSL2 的一些网络访问问题]( https://lengthmin.me/posts/wsl2-network-tricks/)

### 安装 antigen

注：安装 antigen 时会从 github 下载文件，准备好代理软件。

使用 antigen 管理 zsh 的插件：

需要吧yay的源换回自己的，再用翻墙的

```bash
yay --aururl "https://aur.archlinux.org" --save
pc yay -S antigen
```

往`~/.zshrc`中添加如下内容，以启用历史命令、按键绑定、命令补全、语法高亮、powerlevel10k 主题：

```bash
# 初始化 antigen
source /usr/share/zsh/share/antigen.zsh
# Load the oh-my-zsh's library
# oh-my-zsh 会启用历史命令、按键绑定等功能
antigen use oh-my-zsh
# 启用一些 bundle
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
# Load the theme
antigen theme romkatv/powerlevel10k
# Tell antigen that you're done
antigen apply
```

然后`pc zsh`，antigen 就会给你安装插件，安装完后就会开始让你选择 powerlevel10k 的主题样式，如果没出现，就`p10k configure`，我比较喜欢 pure 这个主题。`~/.p10k.zsh`是 powerlevel10k 主题的配置文件，[项目主页](https://github.com/romkatv/powerlevel10k) 有详细的介绍。

之后给 root 用户创建软链接：

```bash
Copy# 在 yourname 用户中
sudo ln -s ~/.p10k.zsh /root/.p10k.zsh
```

### systemd[#](https://www.cnblogs.com/zsmumu/p/archlinux-wsl2.html#2178938276)（选择1）

WSL 不支持 systemd，但可以使用其他方法运行 systemd。详见[systemd/systemctl](https://github.com/yuk7/ArchWSL/wiki/Known-issues#systemdsystemctl)。之前有 genie-systemd aur 软件包，但现在没了，还好我找到了[PKGBUILD](https://github.com/arkane-systems/genie/issues/82#issuecomment-695821616)。

`vim PKGBUILD`，填入如下内容：

```sh
# Maintainer: Arley Henostroza <arllk10[at]gmail[dot]com>
# Contibutor: facekapow

pkgname=genie-systemd
_pkgname=genie
pkgver=1.28
pkgrel=1
pkgdesc="A quick way into a systemd \"bottle\" for WSL"
arch=('x86_64')
url="https://github.com/arkane-systems/genie"
license=('custom:The Unlicense')
depends=('daemonize' 'dotnet-runtime>=3.1' 'dotnet-host>=3.1' 'inetutils')
makedepends=('dotnet-sdk>=3.1')
conflicts=('genie-systemd')
provides=('genie-systemd')
source=("${url}/archive/${pkgver}.tar.gz")
sha256sums=('688253faad5e3c40c9277dac00a481f48bc5ed62cf2bc82c2c1234d92604ea96')

prepare() {
  tar -xzf ${pkgver}.tar.gz
}

package() {
  export DOTNET_CLI_TELEMETRY_OPTOUT=1
  export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=true
  ls -alh
  cd genie-${pkgver}/genie
  export DESTDIR=$pkgdir
  make build
  make install
  mkdir -p ${pkgdir}/usr/bin
  chmod +x ${pkgdir}/usr/libexec/genie
  ln -s /usr/libexec/genie/main/genie ${pkgdir}/usr/bin/genie
}
```

然后进行安装（注意需要和 PKGBUILD 在相同目录）

```bash
yay -S daemonize
makepkg -si # 处理依赖并安装
```

然后就可以使用 genie 了

```bash
# 运行 genie -i，让ArchWSL可以正常使用systemd
genie -i #windows11 不可用 需要下载genie包，进行安装版本1.44
#安装命令
sudo pacman -U genie-systemd-1.44-1-x86_64.pkg.tar.zst
```

接下来让 ArchWSL 在 windows 开机时，就能够自动`genie -i`。

```bash
sudo echo 'genie -i' > /etc/init.wsl
sudo chmod +x /etc/init.wsl
```

在 windows 上创建`ArchWSL-init.vbs`文件（这里的 Arch 是该 wsl 发行版的名称，可通过`wsl -l`命令查看），文件内容为：

```vbs
Set ws = CreateObject("Wscript.Shell")
ws.run "wsl -d Arch -u root /etc/init.wsl", vbhide
```

然后在`C:\Users\用户名\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup`中新建快捷方式，指向刚才创建的 vbs 文件。这样下次 windows 开机时就会自动在 ArchWSL 中执行`genie -i`，然后退出，注意：`wsl --shutdown`命令会把 wsl“关机”，所以你 shutdown 之后，需要再手动运行`ArchWSL-init.vbs`。

PS: 我打开.vbs 文件的时候出现了`Windows 无法访问指定设备、路径或文件。你可能没有适当的权限访问该项目。`的错误，解决方法是用[Default Programs Editor](http://defaultprogramseditor.com/)，把`.vbs`的默认程序设置为`C:\Windows\System32\wscript.exe`。

引入startship

[startship](https://starship.rs/guide/#%F0%9F%9A%80-installation)

连接图形界面：

1. 在 windows 上安装 [VcXsrv](https://sourceforge.net/projects/vcxsrv/)
2. 首先找到软件的安装路径，比如 C:\Program Files\VcXsrv，然后对两个可执行文件 vcxsrv.exe 和 xlaunch.exe 进行操作：右键点击可执行文件 –> 属性 –> 兼容性 – > 更改高 DPI 设置 –> 勾选替代高 DPI 缩放行为。*如果不做这一步，VcXsrv 的显示效果会不够清晰*
3. 打开软件。Display settings 选择左下的第三个（我通常都选左上的第一个），Display number 输入 23789(前文提到过，如果这个端口被占用了就换一个)，然后下一步，下一步
4. 在 Extra settings 界面，下方的 Additional parameters for VcXsrv 里填写`-screen 0 1280x720+100+100`以设置窗口大小和位置
5. 如果使用的是 WSL 2，那么还需要勾选 Disable access control，然后下一步
6. 你可以 Save configuration 保存配置文件，这样将来就可以双击配置文件直接启动或者开机时自启
   1. 按 win+R 键打开运行窗口，输入`shell:startup`，回车，会打开一个文件夹
   2. 将配置文件或者它的快捷方式复制进该文件夹，这样开机时就会自启已经配置好的 VcXsrv
7. 点击完成，这时看到的是黑色的窗口，因为我们还没启动 ArchWSL 的桌面。

打开 wsl，运行如下命令以启动桌面：

```
startxfce4

```

```
sudo pacman -S --needed xfce4 mousepad parole ristretto thunar-archive-plugin thunar-media-tags-plugin xfce4-battery-plugin xfce4-datetime-plugin xfce4-mount-plugin xfce4-netload-plugin xfce4-notifyd xfce4-pulseaudio-plugin xfce4-screensaver xfce4-taskmanager xfce4-wavelan-plugin xfce4-weather-plugin xfce4-whiskermenu-plugin xfce4-xkb-plugin file-roller network-manager-applet leafpad epdfview galculator lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings capitaine-cursors arc-gtk-theme xdg-user-dirs-gtk
```

```
sudo pacman -S --needed xorg
```

 

# 三、启用systemctl

# 二、安装常用软件

```bash
sudo pacman -S base-devel
sudo pacman -S net-tools
sudo pacman -S mycli
sudo pacman -S pgcli
sudo pacman -S scp
sudo pacman -S openssh
sudo pacman -S less
sudo pacman -S which
sudo pacman -S git
sudo pacman -S nodejs
sudo pacman -S gcc
sudo pacman -S npm
sudo pacman -S gzip
sudo pacman -S unzip
sudo pacman -S bat
sudo pacman -S lsd
sudo pacman -S fd
sudo pacman -S tcpdump
sudo pacman -S inetutils
sudo pacman -S bash-completion
sudo pacman -S axel
sudo pacman -S jq
sudo pacman -S cargo
sudo pacman -S systemd
sudo pacman -S httpie
sudo pacman -S iputils
sudo pacman -S curlie
sudo pacman -S yay
sudo pacman -S redis
```

## 3.1 安装subsystemctl

新建目录下载 [PKGBUILD](https://github.com/sorah/arch.sorah.jp/tree/master/aur-sorah/PKGBUILDs/subsystemctl)，cd到有`PKGBUILD`文件的目录下，执行以下命令：

```bash
# 生成后缀.pkg.tar.xz的压缩文件
makepkg
# 使用pacman安装
sudo pacman -U *.pkg.tar.xz
```

安装失败可能是缺少软件，使用 `sudo pacman -S xxx` 进行安装。

安装成功后重新启动wsl

```powershell
wsl -d Archlinux -u root -- subsystemctl start
```

或者执行以下命令：

```bash
sudo subsystemctl start
```

【推荐】可以写一个vb脚本(wsl-startup.vbs) 放入windows的自启动目录（**C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup**）

```vb.net
set ws=wscript.createobject("wscript.shell")
ws.run "C:\Windows\System32\wsl.exe -d Archlinux -u root -- subsystemctl start",0
```

## 3.2 启用Docker

```shell
sudo pacman -S docker
sudo subsystemctl exec sudo systemctl start docker
sudo subsystemctl exec sudo systemctl enable docker
```

验证`subsystemctl`可用，此时已经可以使用完整的`systemctl`命令。

```
sudo vi /etc/docker/daemon.json
{
    "registry-mirrors": [
       "https://d8b3zdiw.mirror.aliyuncs.com"
    ],
 
    "insecure-registries": [
       "https://ower.site.com"
    ]
}

```

 `sudo subsystemctl exec sudo systemctl daemon-reload`
