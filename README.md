# mac-bootstrap

一个可重复执行的 macOS 新机初始化项目。它会安装 Xcode Command Line Tools、
Homebrew、常用命令行及桌面软件，并通过 mise 安装 Node LTS、Bun、Go、Rust 和
Python。

支持 Apple Silicon 与 Intel Mac。脚本不会配置账号、登录服务，也不包含任何密钥。

## 首次使用

先下载或克隆本项目，然后进入目录：

```bash
chmod +x bootstrap.sh scripts/verify.sh
./bootstrap.sh
```

如果 Xcode Command Line Tools 尚未安装，macOS 会弹出系统安装窗口。完成窗口中的
安装后，脚本会自动继续。Homebrew 首次安装可能要求输入当前 Mac 用户的密码。

脚本完成后重新打开终端，或运行：

```bash
exec zsh -l
```

单独检查环境：

```bash
./scripts/verify.sh
```

## 默认安装内容

- Homebrew CLI：mise、Git、GitHub CLI、curl、wget、jq、ripgrep、fd、fzf、tree、tmux
- 桌面软件：Visual Studio Code、iTerm2、Docker Desktop、Obsidian
- mise 工具：Node LTS、Bun latest、Go latest、Rust stable、Python latest

不需要的软件可以在首次执行前从 `Brewfile` 删除。已安装的软件不会重复安装。

## 更新软件

更新 Homebrew 软件及桌面应用：

```bash
brew update
brew upgrade
brew cleanup
```

根据 `mise.toml` 安装当前声明对应的版本，并同步用户级默认版本，最简单的方式是
重新运行：

```bash
./bootstrap.sh
```

脚本设计为可重复执行；它不会重复向 zsh 配置写入相同内容。

## 添加新工具

系统命令行工具放进 `Brewfile`：

```ruby
brew "shellcheck"
```

桌面应用也放进 `Brewfile`：

```ruby
cask "firefox"
```

编程语言或运行时放进 `mise.toml` 的 `[tools]`：

```toml
python = "3.13"
pnpm = "latest"
```

然后重新运行 `./bootstrap.sh`。`bootstrap.sh` 会读取 `[tools]` 中的简单
`工具 = "版本"` 声明并同步为用户级默认版本。

## 常见问题

### `xcode-select --install` 提示已请求安装，但脚本一直等待

检查是否有被其他窗口遮住的系统安装对话框。也可以终止脚本，手动完成安装后再
运行 `./bootstrap.sh`；已完成的步骤会被跳过。

### 终端中找不到 `brew` 或 `mise`

重新打开终端，或执行 `exec zsh -l`。脚本会把 Homebrew 加入 `~/.zprofile`，
并把 mise 激活命令加入 `${ZDOTDIR:-$HOME}/.zshrc`。

### 某个桌面软件安装失败

应用可能已经通过官网安装，或当前 macOS 版本不受该应用支持。先确认应用是否能
正常使用；如不希望 Homebrew 管理它，可从 `Brewfile` 删除对应的 `cask` 后重试。

### `brew bundle` 因一个软件失败而停止

查看错误中对应的软件名，确认网络、磁盘空间和 macOS 兼容性。修复后直接重新运行
脚本即可，不需要卸载已经成功安装的软件。

### mise 工具验证失败

运行：

```bash
mise doctor
mise install
./scripts/verify.sh
```

如果刚修改过 shell 配置，请先运行 `exec zsh -l`。

## 安全注意事项

- 执行前阅读 `bootstrap.sh`，只从自己信任的仓库或压缩包运行。
- 不要使用未经检查的 `curl ... | bash` 链接。
- 不要提交 SSH 私钥、API Key、Token、`.env`、浏览器 Cookie 或密码。
- 私密信息应保存在 1Password、Bitwarden 或 macOS 钥匙串等密码管理工具中。
- `.gitignore` 只能降低误提交风险，不能替代提交前检查。
- Homebrew 安装脚本来自其官方 GitHub 仓库，运行时仍应关注终端提示。

## 文件说明

```text
mac-bootstrap/
├── bootstrap.sh       # 主安装脚本
├── Brewfile           # Homebrew 软件清单
├── mise.toml          # 开发工具版本
├── scripts/
│   └── verify.sh      # 安装后验证
├── .gitignore
└── README.md
```
