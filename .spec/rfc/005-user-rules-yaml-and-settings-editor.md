# RFC 005：用户规则 YAML 与设置内编辑器

**状态**：草案  
**创建日期**：2026-04-12  
**作者**：CleanSpace  
**依赖**：[RFC 001](./001-ccleaner-style-cleaning-spec.md) 长期能力、用户规则存放与合并；[RFC 009](./completed/009-user-rule-safety-and-exclusions.md)（校验器由 009 定义，本 RFC **调用**该校验，不复制安全策略）。

---

## 摘要

v1 已支持 `user-cleaning-rules.json` 与内置合并。RFC 001「后续」提出 YAML 与设置页编辑。本 RFC 规定：**可选 YAML 读取**、与 JSON 的**优先级**、以及应用内**自定义规则**界面的最小能力（增删改、启用/禁用、校验错误展示）。**表单编辑 + JSON 落地**为默认用户路径；YAML 为文件侧增强，可与 JSON **并存**（优先级见下文定案）。

---

## 背景与问题

- 仅文件编辑门槛高；设置内表单可降低门槛。YAML 对部分用户友好，但易引入缩进错误，故 **错误提示须可定位**（见验收）。
- 无 UI 时难以发现合并错误或 `id` 冲突。

---

## 范围

**在本 RFC 内**

- 用户规则文件（固定目录 `~/Library/Application Support/CleanSpace/`）：**`user-cleaning-rules.json` 为必选实现**；**`user-cleaning-rules.yaml` 为可选**。**定案加载顺序**：若仅存在其一，则加载该文件；若二者均存在，先载入 JSON 全部条目，再载入 YAML；**同一 `id` 以 YAML 中定义覆盖 JSON**（仅 YAML 出现的 `id` 则追加）。实现须在 `AGENTS.md` 或开发者文档中写明该顺序。
- 设置（或独立窗口）中列表展示用户规则；编辑后写回并 **定案：保存成功后立即触发与启动时相同的规则加载路径，使当前会话内列表与合并结果更新**（无需重启）。若某平台版本存在技术阻碍，须在首版实现 PR 中说明并 **临时** 退化为「下次启动生效」，且须在矩阵/ROADMAP 标明为技术债并在同一 RFC 周期内收回。
- **校验**：保存与加载路径均须调用 [RFC 009](./completed/009-user-rule-safety-and-exclusions.md) 规定的**单一校验模块**（`type` / `paths` / `command` 等与 001 schema 及安全策略一致）；错误时阻止保存并指出字段。
- **`disableBuiltinIds`**（001 已提及）**定案于本 RFC**：语义与字段名以 RFC 001 为准；009 仅校验其形式（若属于用户规则 schema 一部分），**不**另起冲突定义。

**不在本 RFC 内**

- 导入/导出文件选择器见 [RFC 006](./006-rules-import-and-export.md)。
- 用户命令白名单见 [RFC 009](./completed/009-user-rule-safety-and-exclusions.md)。

---

## 提案要点

1. YAML：若实现，须在 `README` 或 `AGENTS.md` 锁定 **SPM 包名、版本、SPDX 许可证**；解析失败时错误信息须含 **行号与列号**（若库支持）或 **出错片段附近的文本定位**，不得仅显示「YAML 无效」。
2. 用户规则在 UI 中打「自定义」标签，与内置区分。
3. 与 [RFC 006](./006-rules-import-and-export.md) 的入口分工：编辑器提供「导出/导入」按钮位置在 006 描述；安全与合并策略以 006、009 为准。

---

## 验收标准

- 样例 `user-cleaning-rules.json` 与（若启用）样例 YAML 可被加载并与内置合并；故意错误 YAML/JSON 有可见错误信息且 **满足行号/定位要求**（JSON 至少指出字段路径，如 `rules[2].paths`）。
- 自动化测试覆盖解析、合并与 **保存后内存重载**（不依赖真实用户目录时可用临时路径注入）。
- **分阶段（可接受）**：首版可仅交付 JSON + 表单 + 009 校验；YAML 作为明确标出的后续子阶段，但不得无限期停留在「草案未承诺」——须在 `ROADMAP.md` 标明。

---

## 与 RFC 001 的关系

实现 001「后续」中关于 YAML 与设置页的主体部分。
