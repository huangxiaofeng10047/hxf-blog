### 配置SSH登录

这里SSH的一些相关操作需要SSH支持，如果你不确定，可以安装Git for Windows软件，会自带一个Git Bash，内置SSH命令，可以顺利运行下面的命令。

首先打开或创建`.ssh/config`文件，插入类似以下内容，虚拟机的IP地址可以在虚拟机内用`ip a`确定。

```
Host *
    ServerAliveInterval 20
    ServerAliveCountMax 10

Host arch
    Hostname 192.168.229.129
    User techstay
```

检查`~/.ssh`目录，看看是不是已经有了SSH密钥。如果没有的话需要创建一个，推荐ED25519算法，RSA算法已经不够安全了。

```
ssh-keygen -t ed25519 -C "your@email.com"
```

然后打开终端，输入`ssh-copy-id arch`，然后根据提示输入密码，这样就会将公钥复制到虚拟机中，以后就可以直接用`ssh arch`命令远程登录了。

### 安装其他软件

安装一些其他常用的软件包。

```
sh -c "$(wget -O- https://techstay.life/dotfiles/archlinux/i.sh)"
```