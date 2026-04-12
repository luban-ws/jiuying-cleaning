# RFC 003：Chromium 系浏览器多 Profile 路径解析

**状态**：草案  
**创建日期**：2026-04-12  
**作者**：CleanSpace  
**依赖**：[RFC 001](./001-ccleaner-style-cleaning-spec.md) § 多配置/多 profile

---

## 摘要

今日内置规则多假定单一 `Default`（或等价）配置。用户常用多 Profile 时，清理范围不完整。本 RFC 规定：在**不破坏**现有 `dir` + `paths` schema 的前提下，为 Chromium 布局实现 **Profile 发现与规则展开**（或等价机制），使缓存/Cookie 等项覆盖全部 profile 目录。

---

## 背景与问题

- RFC 001 指出 Chrome 等多配置路径为 `Application Support/.../Chrome/<配置名>/`。
- 硬编码多条 profile 不可维护；完全手写 `*` 与当前 `dirs` 语义需界定。

---

## 范围

**在本 RFC 内**

- 明确实现策略：例如扫描 `~/Library/Application Support/Google/Chrome` 下子目录、过滤 profile 形态，再与规则模板合并生成待删路径。
- 适用范围：至少 Chrome；Edge / Brave / Arc / Opera 等同构浏览器复用同一套逻辑（配置根路径不同）。

**不在本 RFC 内**

- 非 Chromium 浏览器（Safari、Firefox）的 profile 模型（可归入 [RFC 002](./002-builtin-rules-catalog-parity.md) 单路径规则）。

---

## Profile 判定（可测试、实现须一致）

下列规则为 **v1 最小约定**；若 Chromium/厂商变更布局，以单元测试夹具锁定行为后再改正文。

**Chromium 应用根（示例）**  
在 `~/Library/Application Support/` 下各浏览器自有子路径（如 `Google/Chrome`、`Microsoft Edge`、`BraveSoftware/Brave-Browser` 等），**应用根**指该浏览器数据目录下、**直接包含 profile 子目录**的那一层（与当前 RFC 001 表格一致）。

**典型布局说明**：Chromium 常在**应用根**放置文件 `Local State`。单元测试须覆盖 **「应用根含 Local State」与「不含 Local State」** 两种夹具；后者仅依赖下列子目录形态判定，不得崩溃。

**视为 profile 的子目录（须同时满足）**

1. 为应用根下的**直接子路径**，且为**目录**。若该路径为符号链接，**解析后的真实路径**须仍位于应用根之下；否则**跳过**并记录诊断（与 [RFC 009](./009-user-rule-safety-and-exclusions.md)「用户域内路径」原则一致）。
2. 目录名**不以**句点开头（忽略 `.` 开头项，除非未来有实测需求另开修订）。
3. 该子目录至少满足下列**任一**「profile 形态」启发式（实现可增不可减，除非修订 RFC）：
   - 存在文件 `Preferences` 或 `Secure Preferences`；或
   - 存在 `Network/Cookies` 或文件 `Cookies`；或
   - 目录名为已知 profile 名：`Default`、`Guest Profile`、`System Profile`，或前缀为 `Profile ` 且后缀为十进制数字（如 `Profile 1`）。

**非目录、损坏或未知条目**：跳过，不中断整次解析；可选 `os_log` 级诊断，便于排障。

**零 profile**：不崩溃；该规则对用户展示为「无可清理子项」或等价空结果，**不得**与「已清理」混淆。

## 提案要点

1. 扫描与清理**共用同一解析结果**（同一次解析结构传入预览、计积与执行），避免「扫描到一个 profile、清理到另一个」。
2. 性能：profile 数量大时避免全盘重复枚举；可缓存于**单次会话**内（与一次「扫描/清理」会话对齐）。
3. 解析规则变更须同步更新本节与单元测试夹具。

---

## 验收标准

- 机器上存在 `Profile 1`、`Default` 等多目录时，勾选「Chrome 缓存」类规则后，预览与扫描均能体现**各 profile 下**目标路径（或合并体积）。
- 单元测试使用临时目录构造假 Chromium 布局，断言解析出的路径集合；并覆盖：**零 profile**、**非目录子项**、**指向应用根外的符号链接**（应跳过且不崩溃）。

---

## 与 RFC 001 的关系

落实 001 中「多配置/多 profile」小节，替代仅 `Default` 的过渡方案。
