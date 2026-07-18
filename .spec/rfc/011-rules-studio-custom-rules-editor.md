# RFC 011：Rules Studio — 自定义规则编辑器详细 UI 设计

**状态**：草案  
**创建日期**：2026-07-18  
**作者**：CleanSpace  
**依赖**：[RFC 005](./005-user-rules-yaml-and-settings-editor.md)、[RFC 009](./completed/009-user-rule-safety-and-exclusions.md)、[RFC 010](./completed/010-rules-workspace-ui-hig-and-collaboration.md)

---

## 摘要

本文定义 CleanSpace 的 **Rules Studio**：一个用于查看、创建、编辑、校验和保存自定义清理规则的独立规则工作区。

RFC 005 规定用户规则文件、合并、YAML 与保存后重载；RFC 011 只规定 **编辑器 UI、交互时间目标、错误反馈、窗口结构与验收标准**。

结论：自定义规则编辑不是普通偏好设置，不应塞进 macOS Settings 小窗；它是 CleanSpace 的核心能力，应作为独立规则工作区呈现。

---

## 背景与问题

当前用户规则只能通过文件维护，问题不在“能不能配置”，而在“用户是否敢配置”。

主要问题：

- 入口不可见：用户不知道自定义规则存在。
- 状态不可扫：无法快速知道哪些规则有效、冲突、被禁用。
- 编辑成本高：JSON/YAML 对普通用户不友好。
- 错误恢复慢：校验错误若只显示全局文本，用户仍需猜字段。
- 保存反馈弱：用户不知道保存是否生效，是否需要重启。

---

## 设计原则：最佳时间设计

Rules Studio 以用户完成任务所需时间为核心指标，不以实现省事为目标。

| 时间目标 | 设计要求 |
|---------|----------|
| 0 秒 | 入口可见：主菜单或主窗口工具栏可打开 Rules Studio |
| 5 秒 | 状态可扫：打开后可看到规则数量、错误数、启用数、来源 |
| 30 秒 | 常见编辑可完成：改名称、风险、路径、命令不需要碰 JSON |
| 1 秒内 | 操作反馈：编辑、校验、保存结果必须即时显示 |
| 出错后 10 秒内 | 可恢复：错误贴近字段，用户能直接修 |
| 保存后立即 | 当前会话规则重载，无需重启 |

---

## 范围

### 包含

- 独立 `Rules Studio` 窗口或 workspace。
- 用户规则列表、筛选、搜索。
- 字段化规则编辑器。
- `dir` 规则 path builder。
- `command` 规则 command safety panel。
- 保存前调用 RFC 009 `UserRuleValidator`。
- 保存成功后触发规则重载。
- JSON 文件读写。
- `disableBuiltinIds` 可视化入口。

### 不包含

- YAML 编辑器或 YAML 依赖引入。
- 导入/导出文件选择器，见 RFC 006。
- 审计日志，见 RFC 007。
- Docker 路径级重置向导，见 RFC 008。

---

## 信息架构

```text
Rules Studio
├── Toolbar
│   ├── Add
│   ├── Duplicate
│   ├── Delete
│   ├── Validate
│   ├── Save
│   └── Reveal File
├── Left Rail
│   ├── All User Rules
│   ├── Enabled
│   ├── Disabled
│   ├── Errors
│   └── Disabled Built-ins
├── Center Table
│   ├── Name
│   ├── Category
│   ├── Type
│   ├── Risk
│   └── Status
├── Detail Inspector
│   ├── Basic fields
│   ├── Type-specific editor
│   ├── Safety validation
│   └── Advanced JSON preview
└── Status Bar
    ├── Unsaved changes
    ├── Validation result
    └── Save/reload result
```

---

## UI 规范

### 窗口

- 使用独立窗口，不使用 Settings scene 作为主承载。
- 最小尺寸：`980 x 620 pt`。
- 推荐初始尺寸：`1120 x 720 pt`。
- 使用 macOS 原生 toolbar、table、form、split layout。
- 禁止卡片堆卡片。
- 用户可见文案必须走 `L10n`。

### Toolbar

| 操作 | 图标 | 启用条件 |
|------|------|----------|
| Add | `plus` | 始终可用 |
| Duplicate | `plus.square.on.square` | 已选择规则 |
| Delete | `trash` | 已选择用户规则 |
| Validate | `checkmark.shield` | 有规则 |
| Save | `square.and.arrow.down` | 有未保存更改且校验通过 |
| Reveal File | `folder` | 用户规则文件存在 |

所有按钮必须有 `.help()`。

### Left Rail

左侧只做筛选，不做深层导航。

筛选项：

- All User Rules
- Enabled
- Disabled
- Errors
- Disabled Built-ins

每项显示计数。错误计数使用系统红色，但不得只靠颜色表达状态。

### Center Table

表格用于快速比较，不用于编辑长文本。

列：

- Name：规则名
- Category：分类
- Type：`dir` / `command`
- Risk：low / medium / high
- Status：valid / invalid / unsaved / disabled

选择行后右侧显示详情。

### Detail Inspector

使用 `Form`，按信息重要度排列。

基础字段：

- Enabled
- Name
- Category
- Risk
- Type

`dir` 规则字段：

- Base
- Directories
- Add directory
- Remove directory
- Path preview

`command` 规则字段：

- Executable
- Arguments
- Command preview
- Safety result

高级区域默认折叠：

- Rule ID
- Raw JSON preview
- Override note
- Disable built-in IDs

---

## 校验与错误反馈

保存与手动校验必须调用 RFC 009 `UserRuleValidator`。

错误显示规则：

- 字段错误贴字段下方。
- 多字段错误在 status bar 汇总。
- 高风险命令或不在白名单命令阻止保存。
- JSON 写入失败使用 alert，因为属于阻断性系统错误。
- 普通校验失败不用 alert。

错误定位必须包含字段路径，例如：

- `rules[0].id`
- `rules[2].paths`
- `rules[4].command`

---

## 保存与重载

保存流程：

1. 收集当前编辑状态。
2. 转换为用户规则 JSON 数据结构。
3. 调用 `UserRuleValidator`。
4. 若失败，阻止保存并显示字段错误。
5. 若成功，写入 `user-cleaning-rules.json`。
6. 调用与启动时一致的加载路径。
7. 通知规则工作区刷新。
8. status bar 显示保存成功时间。

保存不得要求用户重启应用。

---

## 与 RFC 005 的关系

RFC 005 继续负责：

- JSON/YAML 文件规则。
- JSON 与 YAML 合并优先级。
- `disableBuiltinIds` 语义。
- 保存后内存重载要求。

RFC 011 负责：

- Rules Studio UI。
- 编辑体验。
- 字段错误呈现。
- 时间设计验收。

RFC 005 中“设置内编辑器”措辞应修订为“Rules Studio 编辑器”；若保留 Settings 入口，只能作为打开 Rules Studio 的入口，不作为主编辑界面。

---

## 验收标准

- 用户可从菜单或主窗口入口打开 Rules Studio。
- 用户可新增、复制、删除、编辑 JSON 用户规则。
- `dir` 与 `command` 类型显示不同编辑表单。
- 保存前必须调用 RFC 009 校验。
- 校验错误可定位到字段。
- 保存成功后当前会话规则列表刷新。
- 无 CJK UI 字面量；所有用户可见文案走 `L10n`。
- 自动化测试覆盖：
  - 规则编辑模型到 JSON 的编码。
  - JSON 到编辑模型的解码。
  - 校验错误到字段路径映射。
  - 保存后 reload 通知。
- 手动验收覆盖：
  - 新增路径规则。
  - 新增命令规则。
  - 非法命令保存被阻止。
  - 保存后主规则工作区立即出现新规则。

---

## 任务拆分

| ID | 任务 | 状态 | 备注 |
|----|------|------|------|
| TASK-011-01 | Rules Studio 数据模型与 JSON 读写适配 | 待办 | 不引入 YAML |
| TASK-011-02 | 独立窗口、toolbar、三栏布局 | 待办 | macOS 原生控件 |
| TASK-011-03 | 字段化编辑器：基础字段、dir、command | 待办 | 按 type 渐进披露 |
| TASK-011-04 | RFC009 校验接线与字段错误映射 | 待办 | 保存前阻断 |
| TASK-011-05 | 保存后 reload 通知与规则工作区刷新 | 待办 | 无需重启 |
| TASK-011-06 | L10n、单测、手动验收记录 | 待办 | en + zh-Hans |

---

## 风险

| 风险 | 处理 |
|------|------|
| UI 复杂度膨胀 | 只做 JSON 表单；YAML、导入导出另 RFC |
| 命令规则误伤 | 保存前强制 RFC009 校验 |
| 与主规则清理页职责混淆 | 主页只清理，Studio 只编辑 |
| 字段错误难映射 | 中间编辑模型保留字段路径 |
| 保存后状态不同步 | 单一 reload 通道，启动与保存共用加载路径 |

---

## 后续

- RFC 006 可把 Import / Export 按钮接入 Rules Studio toolbar。
- RFC 007 可在 Rules Studio 显示最近保存/校验事件。
- YAML 支持仍由 RFC 005 可选子阶段处理。
