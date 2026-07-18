# 附录 002：内置规则与 RFC 001 目录对照矩阵

本文件维护 RFC 001 中的可清理项与内置规则 `id` 的映射及交付状态。

---

## 1. 系统 (system)

| RFC 001 项 | 规则 ID | 清理类型 | 风险等级 | 默认路径/命令 | 状态 | 备注 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 用户废纸篓 | `trash` | `dir` | `low` | `~/.Trash` | 已完成 | |
| 用户缓存 | `user-caches` | `dir` | `medium` | `~/Library/Caches` | 已完成 | v1 内置清理用户主要缓存目录 |
| Xcode DerivedData | `xcode-derived-data` | `dir` | `low` | `~/Library/Developer/Xcode/DerivedData` | 已完成 | |
| Xcode 归档 | `xcode-archives` | `dir` | `low` | `~/Library/Developer/Xcode/Archives` | 已完成 | |
| 用户临时目录 | `user-temp` | - | - | - | 已搁置 | 属动态环境变量，不在内置静态规则中支持，交由用户自定义规则或动态脚本处理 |

---

## 2. 浏览器 (browser)

> [!NOTE]
> Chromium 多 Profile 的目录动态解析展开由 [RFC 003](./completed/003-chromium-profile-discovery.md) 处理，此处矩阵为通用模板映射（如 `Default` 配置或通配符表示的通用路径，不在矩阵中按各 profile 展开占行）。

### 2.1 Google Chrome
| RFC 001 项 | 规则 ID | 清理类型 | 风险等级 | 默认路径/命令 | 状态 | 备注 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Chrome 缓存 | `chrome-cache` | `dir` | `low` | `~/Library/Caches/Google/Chrome` 等 | 已完成 | |
| Chrome Cookie 与历史 | `chrome-cookies-history` | `dir` | `medium` | `~/Library/Application Support/Google/Chrome/Default` 内 Cookie 与历史文件 | 已完成 | |

### 2.2 Safari
| RFC 001 项 | 规则 ID | 清理类型 | 风险等级 | 默认路径/命令 | 状态 | 备注 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Safari 缓存 | `safari-cache` | `dir` | `low` | `~/Library/Caches/com.apple.Safari` | 已完成 | |
| Safari 本地存储/数据库 | `safari-local-storage` | `dir` | `medium` | `~/Library/Safari/LocalStorage` 等 | 已完成 | |
| Safari 历史记录 | `safari-history` | `dir` | `medium` | `~/Library/Safari` (History.db 等) | 已完成 | |
| Safari 下载列表 | `safari-downloads` | - | - | - | 已搁置 | 仅 Safari 内部元数据；由于实际文件在 `~/Downloads` 中，为防误伤在 v1 中搁置 |

### 2.3 Firefox
| RFC 001 项 | 规则 ID | 清理类型 | 风险等级 | 默认路径/命令 | 状态 | 备注 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Firefox 缓存 | `firefox-cache` | `dir` | `low` | `~/Library/Caches/Firefox` | 已完成 | |
| Firefox Cookie与存储 | `firefox-cookies-history` | `dir` | `medium` | `~/Library/Application Support/Firefox/Profiles/*/cookies.sqlite` 等 | 已完成 | 使用 `Profiles/*` 通配展开 |
| Firefox 崩溃报告 | `firefox-crash-reports` | `dir` | `low` | `~/Library/Application Support/Firefox/Crash Reports` | 已完成 | |

### 2.5 Microsoft Edge
| RFC 001 项 | 规则 ID | 清理类型 | 风险等级 | 默认路径/命令 | 状态 | 备注 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Edge 缓存 | `edge-cache` | `dir` | `low` | `~/Library/Caches/Microsoft Edge` 等 | 已完成 | |
| Edge Cookie与历史 | `edge-cookies-history` | `dir` | `medium` | `~/Library/Application Support/Microsoft Edge/Default` 内 Cookie 与历史 | 已完成 | |

### 2.6 Arc
| RFC 001 项 | 规则 ID | 清理类型 | 风险等级 | 默认路径/命令 | 状态 | 备注 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Arc 缓存 | `arc-cache` | `dir` | `low` | `~/Library/Caches/Arc` 等 | 已完成 | |
| Arc Cookie与历史 | `arc-cookies-history` | `dir` | `medium` | `~/Library/Application Support/Arc/Default` 内 Cookie 与历史 | 已完成 | |

### 2.7 Brave
| RFC 001 项 | 规则 ID | 清理类型 | 风险等级 | 默认路径/命令 | 状态 | 备注 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Brave 缓存 | `brave-cache` | `dir` | `low` | `~/Library/Caches/BraveSoftware` 等 | 已完成 | |
| Brave Cookie与历史 | `brave-cookies-history` | `dir` | `medium` | `~/Library/Application Support/BraveSoftware/Brave-Browser/Default` 内 Cookie 与历史 | 已完成 | |

### 2.8 Opera
| RFC 001 项 | 规则 ID | 清理类型 | 风险等级 | 默认路径/命令 | 状态 | 备注 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Opera 缓存 | `opera-cache` | `dir` | `low` | `~/Library/Caches/com.operasoftware.Opera` 等 | 已完成 | |
| Opera Cookie与历史 | `opera-cookies-history` | `dir` | `medium` | `~/Library/Application Support/com.operasoftware.Opera/Default` 内 Cookie 与历史 | 已完成 | |

---

## 3. Docker (docker)

| RFC 001 项 | 规则 ID | 清理类型 | 风险等级 | 默认路径/命令 | 状态 | 备注 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 移除已停止容器 | `docker-container-prune` | `command` | `low` | `docker container prune -f` | 已完成 | |
| 移除未使用镜像 | `docker-image-prune` | `command` | `medium` | `docker image prune -a -f` | 已完成 | |
| 移除未使用卷 | `docker-volume-prune` | `command` | `medium` | `docker volume prune -f` | 已完成 | |
| 移除未使用网络 | `docker-network-prune` | `command` | `low` | `docker network prune -f` | 已完成 | |
| 移除构建缓存 | `docker-builder-prune` | `command` | `low` | `docker builder prune -a -f` | 已完成 | |
| 系统清理 | `docker-system-prune` | `command` | `medium` | `docker system prune -a -f` | 已完成 | |
| 回收磁盘空间 | `docker-desktop-reclaim` | `command` | `low` | `docker run --privileged --pid=host docker/desktop-reclaim-space` | 已完成 | |
| Docker Desktop 数据残留 | `docker-desktop-residues` | `dir` | `medium` | `~/Library/Group Containers/group.com.docker` 等 | 已完成 | 隐藏规则，配合 RFC 008 的 `hiddenFromRulesList` |

---

## 4. AI 工具 (ai-tools)

| RFC 001 项 | 规则 ID | 清理类型 | 风险等级 | 默认路径/命令 | 状态 | 备注 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Cursor 缓存与扩展缓存 | `cursor-cache` | `dir` | `low` | `~/Library/Application Support/Cursor` (Cache等) | 已完成 | |
| Antigravity 缓存 | `antigravity-cache` | `dir` | `low` | `~/Library/Application Support/Google Antigravity` (Cache等) | 已完成 | |
