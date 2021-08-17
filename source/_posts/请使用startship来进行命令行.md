---
title: 请使用startship来进行命令行
date: 2021-08-11 13:37:49
tags:
---

startship ：轻量级、反应迅速，可定制的高颜值终端！

### 前置要求

- A [Nerd Font (opens new window)](https://www.nerdfonts.com/)installed and enabled in your terminal.

### [#](https://starship.rs/zh-CN/#快速安装)快速安装



1. 安装 **starship** 二进制文件：

   #### [#](https://starship.rs/zh-CN/#安装最新版本)安装最新版本

   使用 Shell 命令：

   ```sh
   sh -c "$(curl -fsSL https://starship.rs/install.sh)"
   ```

   To update the Starship itself, rerun the above script. It will replace the current version without touching Starship's configuration.

   #### [#](https://starship.rs/zh-CN/#通过软件包管理器安装)通过软件包管理器安装

   使用 [Homebrew (opens new window)](https://brew.sh/)：

   ```sh
   brew install starship
   ```

   使用 [Scoop (opens new window)](https://scoop.sh/)：

   ```powershell
   scoop install starship
   ```

2. 将初始化脚本添加到您的 shell 的配置文件：

   #### [#](https://starship.rs/zh-CN/#bash)Bash

   在 `~/.bashhrc` 的最后，添加以下内容：

   ```sh
   # ~/.bashrc
   
   eval "$(starship init bash)"
   ```

   #### [#](https://starship.rs/zh-CN/#fish)Fish

   在 `~/.config/fish/config.fish` 的最后，添加以下内容：

   ```sh
   # ~/.config/fish/config.fish
   
   starship init fish | source
   ```

   #### [#](https://starship.rs/zh-CN/#zsh)Zsh

   在 `~/.zshrc` 的最后，添加以下内容：

   ```sh
   # ~/.zshrc
   
   eval "$(starship init zsh)"
   ```

遇到的问题：

在git环境下报：

[WARN] - (starship::utils): Executing command "git" timed out.

解决办法，引入配置文件

您需要创建配置文件 `~/.config/starship.toml` 以供 Starship 使用。

```sh
mkdir -p ~/.config && touch ~/.config/starship.toml
```

Starship 的所有配置都在此 [TOML (opens new window)](https://github.com/toml-lang/toml)配置文件中完成：

```toml
# Inserts a blank line between shell prompts
add_newline = true

# Replace the "❯" symbol in the prompt with "➜"
[character]                            # The name of the module we are configuring is "character"
success_symbol = "[➜](bold green)"     # The "success_symbol" segment is being set to "➜" with the color "bold green"

# Disable the package module, hiding it from the prompt completely
[package]
disabled = true
```

添加command_timeout=10000即可。

