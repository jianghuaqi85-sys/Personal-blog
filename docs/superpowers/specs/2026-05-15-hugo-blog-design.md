# Hugo 个人博客设计规格

> 暗黑终端风格的个人门户博客，以博客为核心，串联多个子空间。

## 1. 项目概述

**目标**：构建一个独特的个人博客网站，Hugo 静态站点生成器驱动，暗黑终端绿风格，以博客为主页，下辖聊天室、音乐、个人空间等子页面。

**技术栈**：
- 静态站点生成器：Hugo（从零构建自定义主题）
- 样式：原生 CSS（CSS Custom Properties 设计令牌）
- 字体：JetBrains Mono + Fira Code + Noto Sans SC
- 部署：本地服务器 + 阿里云域名
- 已有：聊天室子页面（现有网站）

## 2. 站点结构

```
域名.com/
├── /                    ← 博客首页（neofetch 终端区 + 卡片瀑布流）
├── /posts/              ← 文章列表（按标签/分类筛选）
├── /posts/xxx/          ← 单篇文章页（TOC + 正文 + 代码块）
├── /chat/               ← 聊天室（嵌入已有聊天室，全屏 iframe）
├── /music/              ← 音乐歌单页
├── /space/              ← 个人空间（时间线动态）
├── /about/              ← 关于我（技能树 + GitHub + 社交链接）
└── /links/              ← 友链 / 外部入口集合
```

### 导航栏

- 顶部固定，左侧 Logo/名字，右侧导航链接
- 链接项：首页、关于、音乐、空间、聊天室
- 终端风格 hover 效果（绿色下划线或光标闪烁）

## 3. 视觉设计系统

### 配色方案

| 用途 | 色值 | 说明 |
|------|------|------|
| 背景主色 | `#0a0a0a` | 近黑色底 |
| 背景次级 | `#111111` | 卡片/区块底色 |
| 终端绿 | `#00ff41` | 主强调色、链接、光标 |
| 终端绿暗 | `#00cc33` | hover 状态 |
| 文字主色 | `#e0e0e0` | 正文文字 |
| 文字次级 | `#888888` | 日期、摘要等 |
| 边框/分割线 | `#1a1a1a` | 微妙的层次感 |

### 字体

| 用途 | 字体 | 回退 |
|------|------|------|
| 英文正文 / 代码 | JetBrains Mono | Fira Code, monospace |
| 中文正文 | Noto Sans SC | "PingFang SC", "Microsoft YaHei", sans-serif |
| 标题 | Fira Code | JetBrains Mono, monospace |

### CSS 自定义属性（设计令牌）

```css
:root {
  --bg-primary: #0a0a0a;
  --bg-secondary: #111111;
  --bg-card: #111111;
  --color-terminal: #00ff41;
  --color-terminal-dim: #00cc33;
  --color-text: #e0e0e0;
  --color-text-muted: #888888;
  --color-border: #1a1a1a;
  --font-mono: 'JetBrains Mono', 'Fira Code', monospace;
  --font-sans: 'Noto Sans SC', 'PingFang SC', 'Microsoft YaHei', sans-serif;
  --font-heading: 'Fira Code', 'JetBrains Mono', monospace;
}
```

## 4. 页面设计

### 4.1 首页

**区域一：Neofetch 终端自我介绍**

```
┌─────────────────────────────────────┐
│  ██████   [你的名字]@blog            │
│  ██   ██  ─────────────────────      │
│  ██████   OS: [你的系统]              │
│  ██   ██  Shell: zsh / bash          │
│  ██████   Skills: Java, Go, Vue...   │
│  ██   ██  Projects: XX 个            │
│  ██████   Blog: XX 篇文章            │
│            Uptime: XX 天             │
│            ─────────────────────      │
│            ██████████████████████     │
└─────────────────────────────────────┘
```

- ASCII art 可自定义（名字或图案）
- 数据从 Hugo 数据文件 (`data/`) 读取
- 打字机效果逐行显示
- 底部 16 色色块展示终端配色

**区域二：文章卡片瀑布流**

- 2-3 列响应式网格
- 每张卡片：封面图（可选）+ 标题 + 摘要 + 日期 + 标签
- 卡片样式：深灰底 `#111` + 细微绿色边框光晕
- hover 效果：边框变亮 `#00ff41`，轻微上浮 + 阴影扩散
- 左上角终端风格日期：`2025.05.15 >`
- 标签：`#00ff41` 文字 + 半透明绿底

**区域三：快速入口卡片**

- 卡片网格（聊天室、音乐、GitHub 等）
- 终端命令风格：`> chat`、`> music`、`> github`
- hover 终端绿光晕

### 4.2 单篇文章页

- 顶部：标题（大字、终端绿高亮关键词）+ 日期 + 标签
- 左侧：文章目录（TOC），固定悬浮，随滚动高亮当前章节
- 正文：等宽字体代码块 + 深色语法高亮，中文用思源黑体
- 代码块：右上角复制按钮，终端风格 `$` 提示符
- 底部：上一篇/下一篇导航

### 4.3 子页面

| 页面 | 路径 | 设计要点 |
|------|------|----------|
| 聊天室 | `/chat/` | 全屏嵌入已有聊天室（iframe），保持暗黑主题一致 |
| 音乐歌单 | `/music/` | 卡片式歌单展示，可嵌入网易云/Spotify 播放器 |
| 个人空间 | `/space/` | 时间线形式展示动态、照片、心情，类 QQ 空间 |
| 关于 | `/about/` | 技能树可视化 + GitHub 贡献图 + 社交链接 |
| 友链 | `/links/` | 友情链接和外部资源入口，卡片式展示 |
| 快速入口 | 首页底部 | 终端命令风格卡片网格 |

## 5. 动画效果

- **打字机效果**：neofetch 区域逐行显示，模拟终端输入
- **光标闪烁**：`█` 光标持续闪烁
- **卡片 hover**：边框光晕 + 上浮 + 阴影扩散（CSS transition）
- **页面切换**：淡入效果（可选，不阻塞导航）

## 6. 响应式断点

| 断点 | 宽度 | 卡片列数 |
|------|------|----------|
| 移动端 | < 768px | 1 列 |
| 平板 | 768px - 1024px | 2 列 |
| 桌面 | > 1024px | 3 列 |

## 7. Hugo 主题结构

```
themes/terminal-blog/
├── layouts/
│   ├── _default/
│   │   ├── baseof.html      ← 基础模板（导航 + footer）
│   │   ├── list.html         ← 文章列表页
│   │   └── single.html       ← 单篇文章页
│   ├── index.html            ← 首页模板
│   ├── chat/
│   │   └── list.html         ← 聊天室页
│   ├── music/
│   │   └── list.html         ← 音乐页
│   ├── space/
│   │   └── list.html         ← 个人空间页
│   └── about/
│       └── list.html         ← 关于页
├── static/
│   ├── css/
│   │   ├── tokens.css        ← 设计令牌
│   │   ├── layout.css        ← 布局
│   │   ├── components.css    ← 组件样式
│   │   └── animations.css    ← 动画
│   ├── js/
│   │   ├── typewriter.js     ← 打字机效果
│   │   └── toc.js            ← TOC 交互
│   └── fonts/                ← 自托管字体
├── data/
│   └── profile.yaml          ← 个人信息（neofetch 数据源）
└── theme.toml
```

## 8. 数据文件

`data/profile.yaml` — neofetch 终端区的数据源：

```yaml
name: "你的名字"
ascii_art: |
  ██████
  ██   ██
  ██████
  ██   ██
  ██████
info:
  OS: "Windows 11 / Arch Linux"
  Shell: "bash / zsh"
  Skills: "Java, Go, Vue, React, Hugo"
  Projects: 15
  Blog: 0
  Uptime: "XX days"
colors:
  - "#0a0a0a"
  - "#ff0000"
  - "#00ff41"
  - "#ffff00"
  - "#00ffff"
  - "#ff00ff"
  - "#00ffff"
  - "#e0e0e0"
```

## 9. 部署

- Hugo 构建静态文件到 `public/`
- 通过本地 Nginx/Apache 服务 `public/` 目录
- 阿里云域名解析到本地服务器 IP
- 聊天室子页面通过 iframe 或反向代理嵌入
