# RFC 009 — argv 白名单与子命令扩展

加载 / 保存 / 导入用户规则时，命令校验由 `UserRuleValidator` 统一执行（见 [RFC 009](rfc/009-user-rule-safety-and-exclusions.md)）。

## 当前 argv[0] 白名单

| argv[0] | 说明 |
|---------|------|
| `docker` | 仅允许文档化子命令前缀 |
| `/opt/homebrew/bin/docker` | Homebrew Apple Silicon 默认路径 |
| `/usr/local/bin/docker` | Homebrew Intel / 手工安装常见路径 |

裸 `docker` 由运行时 PATH 解析；带路径的 argv[0] 必须规范化后精确命中上表。`/tmp/docker` 这类同名可执行文件必须拒绝。

## 当前 `docker` 子命令前缀

| Token 前缀 | 允许的后续 flag |
|------------|-----------------|
| `system prune` | `-a`、`-f`、`--all`、`--force` |

## 扩展流程

1. 在 PR 中更新 `UserRuleValidationPolicy.defaultAllowedExecutables` 与/或 `defaultDockerTokenPrefixes`（及 flag 集）。
2. 同步更新本文件表格与单元测试（`UserRuleValidatorTests`）。
3. **禁止**仅在本地配置或运行时静默加宽白名单。
