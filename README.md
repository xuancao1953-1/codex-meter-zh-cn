<p align="center">
  <img src="docs/images/hero.svg" alt="Codex Meter 中文版——随时查看 Codex 剩余额度" width="100%">
</p>

<h1 align="center">Codex Meter 中文版</h1>

<p align="center"><strong>在 macOS 菜单栏查看 Codex 剩余额度、重置时间、模型用量与本地费用估算。</strong></p>

本仓库是基于 TheJhyeFactor/codex-meter 制作的简体中文独立版本。
上游仓库：https://github.com/TheJhyeFactor/codex-meter；原作者：[Jhye / The Jhye Factor](https://github.com/TheJhyeFactor)。
本项目保留并遵循上游的 MIT License，是非官方社区项目，不代表上游作者或 OpenAI。
导入的上游版本、固定提交及中文版变更见 [UPSTREAM.md](UPSTREAM.md)。

## 功能

- 在菜单栏直接显示当前最紧张的 Codex 剩余额度。
- 展示各额度周期的剩余比例与本地重置时间，并每两分钟自动刷新。
- 支持 10%、20% 或 30% 的低额度通知。
- 无法获取最新数据时明确显示不可用状态，不用过期数字冒充实时结果。
- 从本机 Codex 会话日志的汇总事件生成七天用量图和模型明细。
- 按内置公开价格快照估算 API 等价费用，并支持 USD、AUD 和 EUR。
- 管理本机账户资料，并可选择仅切换 Meter 或同时切换 Codex 桌面应用。
- 提供图标加百分比、仅百分比、仅图标和活动图等菜单栏显示方式。
- 附带可供自动化使用的 `codex-meter` 命令行工具源码与构建目标。
- 原生支持 Apple 芯片和 Intel Mac。

> 费用始终标为“API 等价估算”，并不是 ChatGPT 订阅账单。

## 系统要求

- macOS 13 Ventura 或更高版本
- 已安装并登录 ChatGPT/Codex
- 能返回额度信息的 Codex 方案

## 下载与安装

1. 从本仓库的 [Releases](../../releases/latest) 下载
   `Codex-Meter-ZH-CN-1.5.0-zh.1.zip`。
2. 解压后，将 **Codex Meter 中文版.app** 拖入 `/Applications`。
3. 首次打开后，菜单栏会出现仪表图标和剩余比例。

当前社区构建使用 ad-hoc 签名，未经过 Apple 公证。若 Gatekeeper 阻止首次启动，
请在 Finder 中按住 Control 点按 **Codex Meter 中文版.app**，选择“打开”，再确认一次。
之后可以正常双击启动。请只从本仓库 Releases 下载，并在需要时用同页的
`.sha256` 文件核对下载内容。

## 与上游英文版共存

中文版使用独立的应用名 **Codex Meter 中文版.app** 和独立 Bundle ID
`com.xuancao1953.codexmeter.zhcn`，不会覆盖上游的 **Codex Meter.app**。
安装脚本也只操作中文版路径，因此两个版本可以同时放在 `/Applications`；
但它们都读取同一套本机 Codex 状态，分别启用登录启动或通知时可能产生重复提示。

## 隐私

Codex Meter 中文版没有广告、分析 SDK 或独立云端服务。额度查询通过本机
`codex app-server` 完成；历史统计只从本机 rollout 日志中保留模型 ID、时间戳和
累计数字，不上传提示词、回复或工具载荷。账户资料与偏好保留在本机。

完整数据流与边界请参阅 [隐私说明](docs/privacy.md) 和
[架构说明](docs/architecture.md)。这两份上游文档目前仍以英文提供；若中文版实现
改变这些边界，会在发布前同步更新说明。

## 从源码构建

需要 macOS 上的 Swift 工具链：

```sh
git clone https://github.com/xuancao1953-1/codex-meter-zh-cn.git
cd codex-meter-zh-cn
SKIP_LIVE_CODEX_CHECK=1 ./scripts/test.sh
./scripts/build-app.sh dist
open "dist/Codex Meter 中文版.app"
```

`scripts/build-app.sh` 会生成通用架构应用、独立 CLI、
`Codex-Meter-ZH-CN-1.5.0-zh.1.zip` 及其 SHA-256 文件。若要进行完全干净的本地构建：

```sh
rm -rf .build .build-arm64 .build-x86_64 dist
SKIP_LIVE_CODEX_CHECK=1 ./scripts/test.sh
./scripts/build-app.sh dist
```

上面的清理命令只应在仓库根目录运行，它会删除本仓库的本地构建产物。

## 命令行工具

从源码构建后可直接使用 `dist/codex-meter`：

```sh
dist/codex-meter status
dist/codex-meter status --json
dist/codex-meter status --threshold 20
dist/codex-meter history --days 7 --json
```

更多参数见 [CLI 参考](docs/cli.md)（当前为英文）。

## 更新策略

中文版不会自动追踪上游每个提交。每次同步都会先固定并记录一个已审阅的上游提交，
再合入中文本地化、独立包标识和发布改动；详情记录在 [UPSTREAM.md](UPSTREAM.md)。
中文版使用 `v<上游版本>-zh.<修订号>` 标签，例如 `v1.5.0-zh.1`。上游的新功能、
接口变化或安全修复只有在完成审阅、中文审计和 macOS 构建验证后才会进入中文版。

## 许可证与项目关系

本项目依据 [MIT License](LICENSE) 开源，并保留原许可证文本。原始项目的著作权和
贡献归原作者及贡献者所有；中文版本的新增改动归相应贡献者所有。

Codex Meter 中文版是独立维护的非官方社区项目，与
[TheJhyeFactor/codex-meter](https://github.com/TheJhyeFactor/codex-meter)、
Jhye / The Jhye Factor 及 OpenAI 均不存在从属、认可、赞助或官方合作关系。
Codex 和 OpenAI 是其各自权利人的商标。
