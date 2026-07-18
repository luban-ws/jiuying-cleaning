# RFC 002：内置清理规则与 RFC 001 目录对齐

**状态**：已完成  
**创建日期**：2026-04-12  
**作者**：CleanSpace  
**依赖**：[RFC 001](./001-ccleaner-style-cleaning-spec.md)（规范来源；本 RFC 只跟踪**实现缺口**）

---

## 摘要

RFC 001 已用表格列出系统、多浏览器、Docker、AI 工具等可清理项。当前内置 `cleaning-rules.json` 仅覆盖其中一部分。本 RFC 规定：**逐项对齐**规范中的路径与风险等级，使产品行为与 001 正文可核对、可测试。

---

## 背景与问题

- 用户对照 RFC 001 会期望「表里写的都能勾到」；缺项会被视为产品未完成。
- 浏览器侧除 Chrome 外，Safari、Firefox、Edge、Arc、Brave、Opera 等在 001 中均有路径说明，需独立验收。
- 系统侧除废纸篓、DerivedData 外，001 还列 Xcode Archives、用户缓存策略等，需明确 v1 是否纳入及优先级。

---

## 范围

**在本 RFC 内**

- 维护「RFC 001 表格行 ↔ 内置规则 `id`」的对应关系；缺则补规则或明确标注「刻意推迟」并改 001 或本 RFC 状态。
- **矩阵文件唯一约定**：对照表固定为仓库内 [`appendix-002-rfc001-rules-matrix.md`](./appendix-002-rfc001-rules-matrix.md)（与本 RFC 同目录），不得再「附录或 docs 任选」；RFC 002 正文仅链接该文件。
- **矩阵行语义**：一行对应**一条逻辑内置规则**（一个稳定 `id`）。Chromium 多 Profile 的目录展开见 [RFC 003](./003-chromium-profile-discovery.md)，不在矩阵中按 profile 重复占行。
- 每条新增规则须含 `risk` / `warning`（与 001 一致）、并通过现有加载与 UI 流程。

**不在本 RFC 内**

- Chromium **多 Profile** 通配（见 [RFC 003](./003-chromium-profile-discovery.md)）。
- 用户自定义规则编辑（见 [RFC 005](./005-user-rules-yaml-and-settings-editor.md)）。

---

## 提案要点

1. 以 RFC 001 第 2、3、4 节表格为检查单，维护 [`appendix-002-rfc001-rules-matrix.md`](./appendix-002-rfc001-rules-matrix.md)；完成一类（如「Firefox 全表」）即在任务跟踪与矩阵中更新状态。
2. **对外说明**：矩阵仅供研发/验收；用户可见文案与功能说明仍在应用内或独立帮助，不要求用户阅读本附录。
3. 若某路径在 macOS 新版本变更，以 001 为准修订规范，再同步 JSON 与矩阵。
4. **分阶段交付（可演进）**：允许按浏览器/按大类拆 PR，但每一合并须更新矩阵对应行，避免「大爆炸式一次填满」阻塞发布。

---

## 验收标准

- 矩阵中 **Phase v1 承诺** 项在 `cleaning-rules.json` 均有对应规则或已文档化推迟理由。
- `swift test` 中针对规则解码：**除**新增/变更规则形状的 **合法片段** 外，须包含 **故意损坏的 JSON 片段**（缺字段、类型错误、未知枚举）断言 **失败路径**，避免仅测 happy path。
- `ROADMAP.md` 中本 RFC 状态随进度更新。

---

## 与 RFC 001 的关系

001 是**规范**；002 是**内置数据与规范一致性的跟踪与交付**，不重复抄写路径表。
