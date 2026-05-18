# 个人博客项目分析文档

> 分析日期：2026-05-18  
> 项目路径：`C:\Users\86198\Desktop\个人博客`  
> 作者：老蒋（jianghuaqi85-sys）  
> 域名：https://laojiang666.cn

---

## 目录

1. [项目概述](#1-项目概述)
2. [整体架构](#2-整体架构)
3. [前端 — Hugo 博客（Terminal Blog 主题）](#3-前端--hugo-博客terminal-blog-主题)
4. [后端 — GIn 高性能聊天服务器](#4-后端--gin-高性能聊天服务器)
5. [网易云音乐 API 代理](#5-网易云音乐-api-代理)
6. [内容管理系统 — TinaCMS](#6-内容管理系统--tinacms)
7. [部署与运维](#7-部署与运维)
8. [项目文件结构全览](#8-项目文件结构全览)
9. [数据流与交互](#9-数据流与交互)
10. [安全与性能](#10-安全与性能)

---

## 1. 项目概述

### 1.1 项目简介

这是一个功能齐全的个人博客系统，采用 **Hugo 静态站点生成器** 构建前端，搭配多种后端服务：

- **博客前台**：暗黑终端风格的个人博客，展示文章、音乐、个人空间、聊天室、友情链接等
- **聊天室**：基于 Go + Gin 框架的高性能实时聊天服务器，支持 WebSocket 推送、多频道、管理面板
- **音乐播放**：集成网易云音乐 API，支持在线歌单播放
- **内容管理**：TinaCMS（基于 Git 的内容管理系统），提供可视化文章编辑
- **公网穿透**：Cloudflare Tunnel 实现内网服务对外暴露

### 1.2 域名与服务映射

| 域名                                 | 服务     | 技术                                      |
| ---------------------------------- | ------ | --------------------------------------- |
| `https://laojiang666.cn`           | 博客主站   | Hugo（端口 1313）                           |
| `https://chat.laojiang666.cn`      | 聊天室    | Cloudflare Tunnel → Go（端口 8080）         |
| `https://music-api.laojiang666.cn` | 音乐 API | Cloudflare Tunnel → NeteaseAPI（端口 3000） |

### 1.3 技术栈总览

| 层级               | 技术                                 |
| ---------------- | ---------------------------------- |
| **静态站点**         | Hugo v0.161.1（Extended）            |
| **前端样式**         | 原生 CSS（CSS Custom Properties 设计系统） |
| **前端脚本**         | 原生 JavaScript（零依赖）                 |
| **聊天后端**         | Go 1.25 + Gin v1.10                |
| **聊天数据库**        | MySQL 8.x（GORM）/ 可选内存存储            |
| **聊天缓存/消息总线**    | Redis（go-redis v8）                 |
| **聊天 WebSocket** | Gorilla WebSocket v1.5             |
| **聊天认证**         | JWT（golang-jwt v5）+ bcrypt         |
| **内容管理**         | TinaCMS v2.7.0                     |
| **音乐 API**       | NeteaseCloudMusicApi v4.31.0       |
| **公网穿透**         | Cloudflare Tunnel（cloudflared）     |
| **可观测性**         | OpenTelemetry（OTLP）                |
| **日志**           | Logrus（结构化 JSON）                   |

---

## 2. 整体架构

### 2.1 系统架构图

```
┌─────────────────────────────────────────────────────────┐
│                   用户浏览器                              │
│  https://laojiang666.cn                                  │
└──────────────────────┬──────────────────────────────────┘
                       │
              ┌────────┴────────┐
              │  Cloudflare      │
              │  DNS + Proxy     │
              └────────┬────────┘
                       │
         ┌─────────────┼─────────────┐
         │             │             │
  ┌──────┴──────┐ ┌───┴────┐ ┌──────┴──────┐
  │ Hugo Blog   │ │ CF Tun │ │ CF Tun      │
  │ :1313       │ │ :8080  │ │ :3000       │
  └──────┬──────┘ └───┬────┘ └──────┬──────┘
         │            │             │
  ┌──────┴──────┐ ┌───┴────────┐ ┌──┴──────────┐
  │ 静态文件     │ │ GIn Chat   │ │ Netease API  │
  │ public/     │ │ Go Server  │ │ Node.js      │
  └─────────────┘ │ :8080      │ │ :3000        │
                  └───┬────────┘ └──────────────┘
                      │
            ┌─────────┴─────────┐
            │                   │
       ┌────┴────┐        ┌────┴────┐
       │  Redis  │        │  MySQL  │
       │ 缓存/总线│        │ 持久化   │
       └─────────┘        └─────────┘
```

### 2.2 TinaCMS 管理端

```
┌──────────────────────────────────────┐
│        TinaCMS Admin UI              │
│        http://localhost:4002          │
├──────────────────────────────────────┤
│  可视化编辑 ─→ Git 提交 ─→ Hugo 构建   │
└──────────────────────────────────────┘
```

---

## 3. 前端 — Hugo 博客（Terminal Blog 主题）

### 3.1 主题设计理念

**暗黑终端风格（Terminal Theme）**，灵感来源于 Linux 终端和 neofetch 系统信息工具。设计特点：

- 全黑背景（`#0a0a0a`）搭配绿色终端色（`#00ff41`）
- 等宽字体为主（JetBrains Mono / Fira Code）
- 终端命令提示符前缀（`>` / `$`）
- 打字机动画效果
- macOS 风格窗口标题栏（红黄绿圆点）
- 卡片悬浮发光效果
- 自定义滚动条

### 3.2 设计系统（CSS Custom Properties）

定义在 `tokens.css` 中的设计令牌：

```css
:root {
  /* 配色 */
  --bg-primary: #0a0a0a;
  --bg-secondary: #111111;
  --color-terminal: #00ff41;
  --color-terminal-glow: rgba(0, 255, 65, 0.15);
  --color-text: #e0e0e0;
  --color-text-muted: #888888;
  --color-border: #1a1a1a;

  /* 字体 */
  --font-mono: 'JetBrains Mono', 'Fira Code', 'Cascadia Code', monospace;
  --font-sans: 'Noto Sans SC', 'PingFang SC', 'Microsoft YaHei', sans-serif;

  /* 布局 */
  --max-width: 1200px;
  --nav-height: 60px;
}
```

### 3.3 页面结构

| 路由              | 页面                         | 布局文件                           |
| --------------- | -------------------------- | ------------------------------ |
| `/`             | 首页（neofetch + 文章列表 + 快捷入口） | `layouts/index.html`           |
| `/posts/:slug/` | 文章详情                       | `layouts/_default/single.html` |
| `/about/`       | 关于我                        | `layouts/about/list.html`      |
| `/music/`       | 音乐播放                       | `layouts/music/list.html`      |
| `/space/`       | 个人空间（时间线）                  | `layouts/space/list.html`      |
| `/chat/`        | 聊天室（iframe 嵌入）             | `layouts/chat/list.html`       |
| `/links/`       | 友情链接                       | `layouts/links/list.html`      |

### 3.4 页面模板组件

#### 3.4.1 首页（`index.html`）

- **neofetch 窗口**：模拟 Linux neofetch 命令输出
  - 终端窗口标题栏（红黄绿三色点 + "bash" 标题）
  - ASCII 艺术 Logo
  - 系统信息（操作系统、Shell、技能、GitHub Repos/Stars/Followers）
  - 配色色块展示
- **文章列表**：`ls -la ~/posts/` 终端风格标题
  - 文章卡片网格（日期、标签、标题、摘要、阅读时间）
- **快捷入口**：`cat ~/shortcuts.sh` 终端风格标题
  - 6 个快捷卡片：聊天室、歌单、个人空间、关于、GitHub、友链

#### 3.4.2 文章详情（`single.html`）

- 文章元数据（日期 + 阅读时间）
- 标签列表
- 侧边目录（TOC）—— IntersectionObserver 高亮当前章节
- 正文内容
- 上一篇 / 下一篇导航
- 代码复制按钮

#### 3.4.3 关于页（`about/list.html`）

- `whoami --verbose` 标题
- 技能卡片（后端、前端、AI/架构、DevOps）
- 联系方式（GitHub、Email）

#### 3.4.4 音乐页（`music/list.html`）

- `ncmpcpp` 终端风格标题
- 歌单卡片网格（从 `data/playlists.yaml` 读取）
- APlayer 播放器集成
- 骨架屏加载效果
- 歌词显示（lrcType: 3）
- 缓存机制（localStorage 24 小时缓存歌单数据）
- **分步加载策略**：先加载第一首歌立即播放，剩余歌曲后台加载

#### 3.4.5 聊天室页（`chat/list.html`）

- 独立 `baseof.html`（全屏布局，无 padding-top）
- 通过 iframe 嵌入 `https://chat.laojiang666.cn`
- 全屏适配（`position: fixed`）
- 加载中动画

#### 3.4.6 个人空间（`space/list.html`）

- `ls -la ~/space/` 标题
- 时间线布局（绿色圆点 + 竖线连接）
- 个生活记录/里程碑

#### 3.4.7 友链页（`links/list.html`）

- `cat friends.conf` 标题
- 友链卡片网格

### 3.5 JavaScript 模块

#### 3.5.1 `typewriter.js` — 打字机效果

- 逐行显示 neofetch 信息（`opacity + translateY` 过渡）
- 每行间隔 300ms
- 最后添加闪烁光标

#### 3.5.2 `toc.js` — 目录高亮

- IntersectionObserver 监听文章标题
- 自动高亮当前阅读章节对应的目录项
- `rootMargin: '-80px 0px -80% 0px'` 精确检测

#### 3.5.3 `copy-code.js` — 代码复制

- 为每个 `<pre>` 添加"复制"按钮
- 使用 Clipboard API
- 反馈：复制成功 → "已复制!"（2 秒后恢复）

#### 3.5.4 `mini-player.js` — 全站迷你播放器

- 页面底部固定播放器（56px 高度）
- 音源来自音乐页面播放的歌曲
- **接力播放**：音乐页 → 其他页面，通过 `sessionStorage`（30 秒 TTL）+ `localStorage`（24 小时 TTL）无缝接力
- 支持播放/暂停、上一首/下一首、进度条拖拽
- 响应式：移动端隐藏进度条

### 3.6 文章内容

| 文章                            | 日期         | 标签                  | 分类  |
| ----------------------------- | ---------- | ------------------- | --- |
| Hello World - 我的第一篇博客         | 2026-05-15 | 入门, Hugo            | 随笔  |
| Go 并发模式：从 goroutine 到 channel | 2026-05-14 | Go, 并发, 编程          | 技术  |
| AI Agent 入门                   | 2026-05-13 | AI, Agent, LLM      | AI  |
| Vue 3 响应式原理深度解析               | 2026-05-12 | Vue, 前端, JavaScript | 前端  |

### 3.7 配置数据（`data/`）

#### `data/profile.yaml`

- 作者信息（姓名、GitHub 用户名）
- ASCII 艺术图
- 系统信息（OS、Shell、技能、GitHub 数据）
- 配色色板（8 种 Dracula 风格颜色）

#### `data/playlists.yaml`

- 网易云音乐歌单配置（歌单 ID、名称、描述、图标）

### 3.8 GitHub 数据集成

在 `layouts/partials/neofetch.html` 中：

- **构建时**：Hugo 通过 `resources.GetRemote` 从 GitHub API 获取用户数据（repos、stars、followers）
- **运行时**：JavaScript 从 GitHub API 刷新数据，缓存到 localStorage（1 小时 TTL）
- 双重机制确保数据实时性

---

## 4. 后端 — GIn 高性能聊天服务器

### 4.1 概述

**GIn** 是一个基于 Go + Gin 框架的高性能实时聊天服务器，是整个项目中技术最复杂、功能最丰富的组件。

- 入口：`chat-server/cmd/api/main.go`
- 模块：`github.com/example/gin-high-performance`
- Go 版本：1.25

### 4.2 核心功能

#### 4.2.1 用户系统

- 注册/登录（bcrypt 密码哈希）
- JWT 认证（HS256，可配置过期时间）
- 修改密码 / 修改用户名
- 会话持久化（localStorage 自动登录）

#### 4.2.2 多频道聊天

- 创建/列出/切换频道
- WebSocket 实时消息推送（支持自动重连）
- 消息编辑与删除（用户限自己的消息）
- 消息历史分页加载（基于时间戳游标）
- 在线用户列表（实时同步）

#### 4.2.3 管理面板

- 服务器统计（在线人数、注册用户、频道数、消息数）
- 用户管理：列表、删除、封禁、解封
- 频道管理：列表、删除、清空消息
- 全局广播公告
- **权限分级**：普通用户 → 管理员（admin）→ 超级管理员（super_admin）

#### 4.2.4 实时同步机制

- 频道创建/删除 → 所有用户自动更新
- 消息编辑/删除 → 实时更新
- 封禁用户 → 自动断开连接
- 用户名修改 → 全客户端同步（含历史消息）
- 断线重连 → 自动加载遗漏消息

### 4.3 架构设计

#### 4.3.1 路由结构

```
请求
  │
  ├── Recovery（panic 恢复）
  ├── Gzip（响应压缩）
  ├── OTel（链路追踪）
  └── Logging（请求日志）
      │
      ├── /api/public/*  → 限流(20/min) → 认证处理器
      ├── /api/*         → 限流(100/min) → JWT 认证 → 业务处理器
      ├── /api/admin/*   → 限流(100/min) → JWT 认证 → 管理员中间件 → 管理处理器
      ├── /api/admin/set-admin|remove-admin → + 超级管理员中间件
      └── /api/ws        → WebSocket 升级 → 认证(首条消息)
```

#### 4.3.2 WebSocket 架构（256 桶 + 64 分片）

```
Hub（全局管理中心）
  │
  ├── 桶 0 (goroutine)   → 客户端 A, 客户端 B
  ├── 桶 1 (goroutine)   → 客户端 C
  ├── ...
  └── 桶 255 (goroutine) → 客户端 N

频道分片（FNV-32a 哈希）：
  shard[0]: { 频道A: [客户端1, 客户端2], 频道B: [客户端3] }
  shard[1]: { 频道C: [客户端4] }
  ...
  shard[63]: ...
```

**关键设计决策**：

- **256 哈希分桶客户端池**：按用户 ID 的 FNV-32a 哈希分配桶，独立 goroutine，降低锁竞争
- **64 分片频道锁**：按频道 ID 的 FNV-32a 哈希分配分片，支持频道操作并发
- **Write-behind 持久化**：消息先广播再入队（容量 4096 的 channel），Worker 池异步写库

#### 4.3.3 多实例扩展（Redis Pub/Sub）

```
实例 A                    实例 B
  Hub                      Hub
  客户端1, 客户端2          客户端3, 客户端4
     │                        │
     └──────────┬─────────────┘
                │
       Redis Pub/Sub
  频道: chat:ch:<channel_id>
```

配置 `REDIS_ADDR` 后自动启用，根据本地客户端计数管理订阅生命周期。

### 4.4 API 接口

#### 公开接口（无需认证）

| 方法   | 路径                     | 说明              | 限流        |
| ---- | ---------------------- | --------------- | --------- |
| POST | `/api/public/register` | 用户注册            | 20次/分钟/IP |
| POST | `/api/public/login`    | 登录，返回 JWT Token | 20次/分钟/IP |
| GET  | `/api/public/health`   | 健康检查            | 20次/分钟/IP |

#### 认证接口

| 方法     | 路径                           | 说明       |
| ------ | ---------------------------- | -------- |
| GET    | `/api/me`                    | 获取当前用户   |
| PUT    | `/api/password`              | 修改密码     |
| GET    | `/api/channels`              | 频道列表     |
| POST   | `/api/channels`              | 创建频道     |
| GET    | `/api/channels/:id/messages` | 消息历史（分页） |
| PUT    | `/api/messages/:id`          | 编辑消息     |
| DELETE | `/api/messages/:id`          | 删除消息     |
| GET    | `/api/online`                | 在线用户     |
| GET    | `/api/tunnel`                | 隧道地址     |

#### 管理员接口

| 方法     | 路径                                 | 说明           |
| ------ | ---------------------------------- | ------------ |
| GET    | `/api/admin/stats`                 | 服务器统计        |
| GET    | `/api/admin/users`                 | 用户列表         |
| DELETE | `/api/admin/users/:id`             | 删除用户         |
| POST   | `/api/admin/ban`                   | 封禁用户         |
| POST   | `/api/admin/unban`                 | 解封用户         |
| DELETE | `/api/admin/channels/:id`          | 删除频道         |
| DELETE | `/api/admin/channels/:id/messages` | 清空消息         |
| DELETE | `/api/admin/messages/:id`          | 删除任意消息       |
| POST   | `/api/admin/broadcast`             | 全局广播         |
| POST   | `/api/admin/set-admin`             | 设为管理员（超级管理员） |
| POST   | `/api/admin/remove-admin`          | 撤销管理员（超级管理员） |

### 4.5 WebSocket 协议

#### 客户端 → 服务器

| type      | 字段                      | 说明                  |
| --------- | ----------------------- | ------------------- |
| `auth`    | `token`                 | JWT 认证（首条消息，10 秒超时） |
| `join`    | `channel_id`            | 加入频道                |
| `leave`   | `channel_id`            | 离开频道                |
| `message` | `channel_id`, `content` | 发送消息（最大 200 字符）     |

#### 服务器 → 客户端

| type      | 字段                                                           | 说明   |
| --------- | ------------------------------------------------------------ | ---- |
| `auth_ok` | `content`(用户名)                                               | 认证成功 |
| `error`   | `content`                                                    | 错误消息 |
| `message` | `channel_id`, `user_id`, `username`, `content`, `created_at` | 新消息  |
| `system`  | `channel_id`(可选), `content`, `created_at`                    | 系统通知 |

#### 连接参数

| 参数      | 值           |
| ------- | ----------- |
| Ping 间隔 | 54 秒        |
| Pong 超时 | 60 秒        |
| 写入截止时间  | 10 秒        |
| 认证超时    | 10 秒        |
| 默认读取限制  | 512 字节（可配置） |
| 发送缓冲    | 256 条消息     |

#### 客户端重连策略

1. 指数退避：1s → 2s → 4s → 8s → 16s → 30s（上限）
2. 连续 5 次失败 → 降级为 HTTP 轮询（5 秒/次）
3. WebSocket 恢复 → 自动切回

### 4.6 数据模型

#### 用户（User）

| 字段            | 类型           | 说明                               |
| ------------- | ------------ | -------------------------------- |
| id            | varchar(36)  | UUID 主键                          |
| username      | varchar(64)  | 唯一，字母数字下划线                       |
| password_hash | varchar(255) | bcrypt 哈希                        |
| role          | varchar(16)  | `admin` / `super_admin` / `user` |
| banned        | boolean      | 封禁标志                             |

#### 频道（Channel）

| 字段         | 类型          | 说明       |
| ---------- | ----------- | -------- |
| id         | varchar(36) | UUID 主键  |
| name       | varchar(64) | 唯一频道名    |
| created_by | varchar(36) | 创建者用户 ID |
| created_at | timestamp   | 创建时间     |

#### 消息（Message）

| 字段         | 类型          | 说明              |
| ---------- | ----------- | --------------- |
| id         | varchar(36) | UUID 主键         |
| channel_id | varchar(36) | 索引外键            |
| user_id    | varchar(36) | 作者 ID           |
| username   | varchar(64) | 作者用户名（冗余字段）     |
| content    | text        | 消息内容（最大 200 字符） |
| created_at | timestamp   | 索引创建时间          |

### 4.7 中间件链

| 中间件                      | 作用                    |
| ------------------------ | --------------------- |
| `gin.Recovery()`         | 捕获 panic，返回 500       |
| `gzip.Gzip()`            | 响应压缩                  |
| `OtelMiddleware()`       | 创建 OpenTelemetry Span |
| `LoggingMiddleware()`    | 结构化请求日志（sync.Pool 优化） |
| `AuthMiddleware()`       | JWT Bearer Token 认证   |
| `AdminMiddleware()`      | 管理员角色校验               |
| `SuperAdminMiddleware()` | 超级管理员校验               |
| `RateLimitMiddleware()`  | Redis 滑动窗口限流          |

### 4.8 安全加固

| 措施                  | 位置                 | 说明            |
| ------------------- | ------------------ | ------------- |
| 消息长度限制              | chat_handler.go    | 单条消息最大 200 字符 |
| 日志 IP 脱敏            | logging.go         | 生产环境隐藏 IP 末位  |
| WebSocket Origin 检查 | ws.go              | 防止 CSWSH 攻击   |
| JWT 认证              | auth.go            | Token 过期可配置   |
| bcrypt 密码哈希         | user_repository.go | 不可逆存储         |
| 滑动窗口限流              | rate_limit.go      | 防暴力破解/DDoS    |
| 角色权限控制              | admin.go           | 分级访问控制        |

### 4.9 环境配置

| 变量                  | 默认值              | 说明                       |
| ------------------- | ---------------- | ------------------------ |
| `APP_ENV`           | `development`    | 开发/生产模式切换                |
| `APP_PORT`          | `8080`           | API 端口                   |
| `JWT_SECRET`        | **必填**           | 签名密钥，≥32 字符              |
| `REDIS_ADDR`        | `localhost:6379` | Redis 地址                 |
| `MYSQL_DSN`         | *(空)*            | MySQL 连接。留空则用内存存储        |
| `CLOUDFLARED_PATH`  | *(空)*            | cloudflared 路径，设置后自动启动隧道 |
| `WS_READ_LIMIT`     | `512`            | WebSocket 消息最大字节数        |
| `WS_ALLOWED_ORIGIN` | *(空)*            | 允许的 WebSocket Origin     |

---

## 5. 网易云音乐 API 代理

### 5.1 概述

位于 `netease-api/` 目录，是一个 Node.js 服务，基于 `NeteaseCloudMusicApi` 库封装。

- **端口**：3000
- **框架**：Node.js + NeteaseCloudMusicApi v4.31.0
- **入口**：`server.js`

### 5.2 核心功能

```javascript
const { serveNcmApi } = require('NeteaseCloudMusicApi/server');
serveNcmApi({ port: 3000, checkVersion: false });
```

- 包装 NeteaseCloudMusicApi 的所有接口
- 自动创建 `anonymous_token` 文件（临时目录）
- 通过 `cookie` 参数携带认证信息（硬编码的 `MUSIC_U` Token）

### 5.3 前端调用链

```
音乐页面 → APlayer.js
  → fetch(`https://music-api.laojiang666.cn/playlist/detail?id=${id}&cookie=...`)
  → fetch(`https://music-api.laojiang666.cn/song/url?id=${id}&cookie=...`)
  → fetch(`https://music-api.laojiang666.cn/lyric?id=${id}&cookie=...`)
```

### 5.4 缓存策略

- localStorage 缓存歌单歌曲列表（24 小时 TTL）
- 分步加载：先获取第一首立即播放，后台加载剩余歌曲
- 缓存满时自动清理旧的 `music_*` 缓存项
- 页面加载时自动恢复播放状态

---

## 6. 内容管理系统 — TinaCMS

### 6.1 概述

TinaCMS 是一个基于 Git 的开源内容管理系统，与 Hugo 深度集成。

- **版本**：TinaCMS v2.7.0 / @tinacms/cli v1.9.0
- **端口**：4002（管理端 UI）/ 9001（数据层）
- **配置**：`tina/config.ts`

### 6.2 内容模型

#### 文章（post）

| 字段         | 类型        | 说明           |
| ---------- | --------- | ------------ |
| title      | string    | 标题（必填）       |
| date       | datetime  | 发布日期（必填）     |
| draft      | boolean   | 草稿状态         |
| tags       | string[]  | 标签           |
| categories | string[]  | 分类           |
| summary    | textarea  | 摘要           |
| body       | rich-text | 正文（Markdown） |

#### 个人空间（space）

| 字段    | 类型        | 说明           |
| ----- | --------- | ------------ |
| title | string    | 标题（必填）       |
| draft | boolean   | 草稿状态         |
| body  | rich-text | 正文（Markdown） |

#### 关于我（about）

| 字段    | 类型        | 说明           |
| ----- | --------- | ------------ |
| title | string    | 标题（必填）       |
| body  | rich-text | 正文（Markdown） |

#### 友链（links）

| 字段    | 类型        | 说明           |
| ----- | --------- | ------------ |
| title | string    | 标题（必填）       |
| body  | rich-text | 正文（Markdown） |

### 6.3 本地模式

配置为本地模式（不依赖 TinaCloud），TinaCMS 管理界面通过 `localhost:4002` 访问，内容直接写入本地 Git 仓库的 Markdown 文件。

### 6.4 工作流程

```
用户编辑内容 → TinaCMS UI → 修改 Markdown 文件 → Git 提交 → Hugo 重新构建 → 生成静态页面
```

---

## 7. 部署与运维

### 7.1 本地开发启动

#### 普通模式（仅 Hugo）

```bash
start.bat
```

启动：聊天服务器（8080）→ 网易云 API（3000）→ Hugo（1313）→ Cloudflare Tunnel

#### TinaCMS 模式（带内容管理）

```bash
start-tina.bat / start-tina.ps1
```

启动：TinaCMS（4002）+ Hugo（1313）

### 7.2 生产部署

`deploy-server.ps1` 是**服务器端部署脚本**，自动完成：

1. 安装 Hugo Extended（v0.147.4）
2. 安装 Go（v1.24.4）
3. 安装 cloudflared
4. 提示通过远程桌面上传文件
5. 生成 `C:\deploy\start.bat` 启动脚本

### 7.3 服务启动顺序

```
1. 停止旧进程（hugo, cloudflared, api.exe, node.exe）
2. 启动聊天服务器（api.exe :8080）
3. 启动网易云 API（node server.js :3000）
4. 启动 Hugo（hugo server :1313）
5. 启动 Cloudflare Tunnel（cloudflared tunnel run gin-chat）
6. 验证所有服务端口
```

### 7.4 验证机制

`start.bat` 自动验证 4 项服务：

- Chat Server（localhost:8080）
- NeteaseCloudMusicApi（localhost:3000）
- Hugo Blog（localhost:1313）
- Cloudflare Tunnel（cloudflared.exe 进程）

验证结果汇总（OK/FAIL 计数）。

### 7.5 聊天室辅助脚本

在 `chat-server/` 目录中：

| 脚本                       | 功能                        |
| ------------------------ | ------------------------- |
| `start.bat`              | 启动聊天室 + Cloudflare Tunnel |
| `start-smart.bat`        | 智能启动                      |
| `start-with-monitor.bat` | 带监控启动                     |
| `launch-tunnel.ps1`      | 启动 Cloudflare Tunnel      |
| `monitor-tunnel.ps1`     | 监控隧道状态                    |
| `auto-update-url.ps1`    | 自动更新隧道 URL                |
| `update-tunnel-url.bat`  | 更新隧道 URL                  |
| `tunnel.bat`             | 隧道启动快捷方式                  |

---

## 8. 项目文件结构全览

```
个人博客/
├── hugo.toml                    # Hugo 主配置
├── package.json                 # Node.js 依赖（TinaCMS）
├── tsconfig.json                # TypeScript 配置（TinaCMS）
├── .gitignore
├── start.bat                    # 一键启动脚本
├── start-tina.bat               # TinaCMS 启动脚本
├── start-tina.ps1               # TinaCMS 启动 PowerShell 脚本
├── deploy-server.ps1            # 服务器部署脚本
│
├── archetypes/
│   └── default.md               # Hugo 新文章模板
│
├── content/                     # 内容（Markdown）
│   ├── posts/                   # 文章
│   │   ├── hello-world.md
│   │   ├── go-concurrency.md
│   │   ├── ai-agent-intro.md
│   │   └── vue3-reactivity.md
│   ├── about/_index.md          # 关于
│   ├── chat/_index.md           # 聊天室
│   ├── links/_index.md          # 友链
│   ├── music/_index.md          # 音乐
│   └── space/_index.md          # 个人空间
│
├── themes/
│   └── terminal-blog/           # 自定义主题
│       ├── theme.toml
│       ├── layouts/
│       │   ├── index.html       # 首页
│       │   ├── _default/
│       │   │   ├── baseof.html  # 基础模板
│       │   │   └── single.html  # 文章详情
│       │   ├── about/list.html
│       │   ├── chat/
│       │   │   ├── baseof.html  # 聊天室独立基础模板
│       │   │   └── list.html
│       │   ├── links/list.html
│       │   ├── music/list.html  # 音乐页（含 APlayer 集成）
│       │   ├── space/list.html
│       │   └── partials/
│       │       ├── head.html    # <head> 部分
│       │       ├── nav.html     # 导航栏
│       │       ├── footer.html  # 页脚
│       │       ├── neofetch.html # Neofetch 终端窗口
│       │       ├── post-card.html # 文章卡片
│       │       ├── quick-links.html # 快捷入口
│       │       └── mini-player.html # 迷你播放器
│       └── static/
│           ├── css/
│           │   ├── tokens.css      # 设计令牌
│           │   ├── base.css        # 基础样式
│           │   ├── layout.css      # 布局
│           │   ├── components.css  # 组件
│           │   ├── animations.css  # 动画（含 neofetch）
│           │   └── mini-player.css # 迷你播放器
│           ├── js/
│           │   ├── typewriter.js   # 打字机效果
│           │   ├── toc.js          # 目录高亮
│           │   ├── copy-code.js    # 代码复制
│           │   └── mini-player.js  # 迷你播放器控制
│           └── fonts/             # （空，使用 Google Fonts）
│
├── data/
│   ├── profile.yaml             # 作者资料
│   └── playlists.yaml           # 歌单配置
│
├── static/
│   └── admin/                   # TinaCMS 管理界面
│       ├── index.html
│       └── .gitignore
│
├── tina/
│   ├── config.ts                # TinaCMS 配置
│   ├── tina-lock.json           # TinaCMS 锁文件
│   └── __generated__/           # 自动生成
│
├── public/                      # Hugo 构建输出
│   └── (index.html, css/, js/, posts/, ...)
│
├── chat-server/                 # GIn 聊天服务器
│   ├── go.mod / go.sum
│   ├── Makefile
│   ├── .env.example
│   ├── README.md / README-隧道配置.md
│   ├── start.bat / start-smart.bat / start-with-monitor.bat
│   ├── launch-tunnel.ps1 / monitor-tunnel.ps1
│   ├── auto-update-url.ps1 / update-tunnel-url.bat / tunnel.bat
│   ├── api.exe                  # 编译后的二进制
│   ├── cmd/
│   │   ├── api/
│   │   │   ├── main.go         # API 入口 + 路由
│   │   │   └── chat_html.go    # 内嵌聊天 UI
│   │   ├── grpc/server.go      # gRPC 服务器
│   │   └── ws/server.go        # 独立 WebSocket 服务器
│   ├── internal/
│   │   ├── config/config.go
│   │   ├── database/database.go
│   │   ├── handler/
│   │   │   ├── auth_handler.go
│   │   │   ├── chat_handler.go
│   │   │   └── admin_handler.go
│   │   ├── logger/logger.go
│   │   ├── middleware/
│   │   │   ├── auth.go
│   │   │   ├── admin.go
│   │   │   ├── rate_limit.go
│   │   │   ├── logging.go
│   │   │   └── otel.go
│   │   ├── repository/
│   │   │   ├── user_repository.go
│   │   │   └── chat_repository.go
│   │   ├── service/greeter.go
│   │   └── tunnel/tunnel.go
│   ├── pkg/
│   │   ├── jwt/jwt.go
│   │   ├── limiter/limiter.go
│   │   ├── otel/otel.go
│   │   ├── redisbus/bus.go
│   │   └── ws/ws.go            # WebSocket Hub 架构
│   ├── proto/
│   │   ├── service.proto
│   │   ├── service.pb.go
│   │   └── service_grpc.pb.go
│   └── tools/
│       ├── benchmark/benchmark.go
│       └── hotreload/hotreload.go
│
├── netease-api/                 # 网易云音乐 API 代理
│   ├── package.json
│   ├── server.js
│   └── node_modules/
│
├── netease-music-api/           # （空目录）
├── resources/_gen/              # Hugo 缓存
├── node_modules/                # Node 依赖
└── docs/superpowers/
    ├── plans/
    └── specs/
```

---

## 9. 数据流与交互

### 9.1 用户浏览博客

```
用户 → https://laojiang666.cn
         ↓
   Cloudflare DNS
         ↓
   Hugo 静态文件（public/）
         ↓
   返回 HTML + CSS + JS
```

### 9.2 音乐播放流程

```
用户点击歌单卡片
         ↓
  检查 localStorage 缓存（24h TTL）
         ↓
  缓存命中？ → 是 → 立即播放
         ↓ 否
  请求 NeteaseCloudMusicAPI
  GET /playlist/detail?id=2745637464
         ↓
  获取歌单歌曲列表
         ↓
  请求第一首歌 URL（立即播放）
  GET /song/url?id=xxx
         ↓
  后台加载剩余歌曲 URL（批量，每批 100 首）
         ↓
  所有歌曲就绪 → 更新 APlayer 播放列表
         ↓
  缓存到 localStorage
```

### 9.3 聊天室交互

```
用户打开 /chat/
         ↓
   iframe 嵌入 https://chat.laojiang666.cn
         ↓
  加载单页聊天 UI（内嵌在 Go 二进制中）
         ↓
  WebSocket 连接 ws://chat.laojiang666.cn/api/ws
         ↓
  发送 auth 消息（JWT Token）
         ↓
  认证成功 → 加入频道 → 收发消息
```

### 9.4 迷你播放器接力

```
音乐页面播放歌曲
  → 每 3 秒同步状态到 localStorage + sessionStorage
  → 页面关闭前保存状态

其他页面加载
  → head.html 内联脚本从 sessionStorage 恢复 Audio（30 秒内）
  → mini-player.js 初始化迷你播放器
  → 继续播放同一首歌
```

### 9.5 GitHub 数据集成

```
构建时（Hugo）：
  resources.GetRemote("https://api.github.com/users/jianghuaqi85-sys")
  → 渲染到 HTML（repos, stars, followers, joined）

运行时（浏览器）：
  fetch("https://api.github.com/users/jianghuaqi85-sys")
  → 更新页面显示 + 缓存到 localStorage（1h TTL）
```

---

## 10. 安全与性能

### 10.1 安全措施

| 层面         | 措施                                                                                |
| ---------- | --------------------------------------------------------------------------------- |
| **聊天室**    | JWT 认证、bcrypt 密码哈希、消息长度限制（200 字符）、WebSocket Origin 检查、Redis 滑动窗口限流、IP 脱敏日志、三级角色权限 |
| **音乐 API** | Cookie 认证（硬编码 Token，需定期更换）                                                        |
| **博客**     | Hugo 静态文件（无后端动态执行）、Google Fonts 镜像（loli.net）                                      |
| **网络**     | Cloudflare 代理（DDoS 防护、SSL 终止）                                                     |

### 10.2 性能优化

| 优化               | 说明                             |
| ---------------- | ------------------------------ |
| WebSocket 256 分桶 | 降低锁竞争，支持大量并发连接                 |
| 64 分片频道锁         | 频道操作细粒度并发控制                    |
| Write-behind 持久化 | 先广播再异步写库，减少延迟                  |
| Worker 池         | CPU 核数个 goroutine 异步写库         |
| Gzip 压缩          | Gin 中间件响应压缩                    |
| 数据库连接池           | 50 空闲 / 200 最大 / 1 小时生命周期      |
| Redis Lua 脚本     | 原子化滑动窗口限流                      |
| sync.Pool        | 复用日志字段 Map，减少 GC 压力            |
| 歌单缓存             | localStorage 24 小时缓存           |
| 分步加载             | 音乐页面先播第一首，后台加载剩余               |
| 迷你播放器状态同步        | 3 秒间隔同步，避免频繁写入                 |
| 指数退避重连           | WebSocket 断线后渐进式重连，降级为 HTTP 轮询 |

### 10.3 可观测性

- **OpenTelemetry**：分布式链路追踪（OTLP HTTP / stdout）
- **Logrus**：结构化 JSON 日志（含请求元数据）
- **健康检查**：`/api/public/health`
- **管理统计面板**：实时在线人数、消息数等

---

## 附：快速参考

### 常用命令

```bash
# 启动博客（普通模式）
start.bat

# 启动博客（TinaCMS 编辑模式）
start-tina.bat

# 本地构建
hugo

# 构建并压缩
hugo --minify

# 启动聊天室（开发模式）
cd chat-server && go run ./cmd/api

# 构建聊天室
cd chat-server && make build

# 运行测试
cd chat-server && go test ./... -v
```

### 关键配置位置

| 配置           | 位置                                           |
| ------------ | -------------------------------------------- |
| Hugo 配置      | `hugo.toml`                                  |
| 作者信息         | `data/profile.yaml`                          |
| 歌单配置         | `data/playlists.yaml`                        |
| 导航菜单         | `hugo.toml` 中的 `[menu]`                      |
| TinaCMS 内容模型 | `tina/config.ts`                             |
| 聊天服务器配置      | `chat-server/.env`                           |
| 聊天服务器依赖      | `chat-server/go.mod`                         |
| 主题设计令牌       | `themes/terminal-blog/static/css/tokens.css` |
| 部署脚本         | `deploy-server.ps1`                          |

### 端口占用

| 端口   | 服务                  |
| ---- | ------------------- |
| 1313 | Hugo 博客             |
| 4002 | TinaCMS 管理 UI       |
| 9001 | TinaCMS 数据层         |
| 3000 | 网易云音乐 API           |
| 8080 | 聊天服务器               |
| 9090 | gRPC 服务器（独立模式）      |
| 8081 | WebSocket 服务器（独立模式） |
