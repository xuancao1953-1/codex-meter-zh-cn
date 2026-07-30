# 上游来源与归属

Codex Meter 中文版来源于以下开源项目：

- 上游项目：`TheJhyeFactor/codex-meter`
- 上游地址：https://github.com/TheJhyeFactor/codex-meter
- 原作者：Jhye / The Jhye Factor
- 导入版本：`v1.5.0`
- 固定提交：`75e3a1e8c4284afc842fb6d4910a4d8127fe203c`
- 许可证：MIT License（完整文本见 [LICENSE](LICENSE)）

固定提交是本中文版当前可追溯的代码基线。仓库保留上游的提交历史和 LICENSE，
上游作者及贡献者对原始代码的著作权与贡献不因中文版发布而改变。

## 简体中文版变更

- 增加固定的 `zh-Hans` 文案目录和本地化访问层，翻译菜单栏应用界面。
- 使用独立应用名、Bundle ID、版本后缀、安装目标和 ZIP 文件名，可与英文版共存。
- 增加本地化与打包审计，检查中文资源、字符串占位符和发布契约。
- 提供中文 README、上游归属说明及中文版专用的 CI/Release 流程。

## 同步方式

中文版不声称与上游实时同步。后续更新会明确记录新的上游提交，在独立分支中审阅
差异，并重新完成本地化审计、离线测试、双架构构建、签名和发布包验证。中文版标签
采用 `v<上游版本>-zh.<修订号>` 格式。

本仓库是非官方社区项目，不代表 The Jhye Factor 或 OpenAI，也未获得双方认可或赞助。
