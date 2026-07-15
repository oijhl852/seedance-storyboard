# awesome-seedance

Seedance 2.0 综合视频脚本与分镜生成主 skill。具体能力由仓库根目录的 `sd-*` 子 skill 提供。

融合四套知识体系：
- [Seedance2-Storyboard-Generator](https://github.com/liangdabiao/Seedance2-Storyboard-Generator) — 专业分镜工作流与剧本系统
- [songguoxs/seedance-prompt-skill](https://github.com/songguoxs/seedance-prompt-skill) — 十大能力框架与提示词工程 (MIT)
- [ZeroLu/awesome-seedance](https://github.com/ZeroLu/awesome-seedance) — 精选案例库 (CC BY 4.0)
- [YouMind-OpenLab/awesome-seedance-2-prompts](https://github.com/YouMind-OpenLab/awesome-seedance-2-prompts) — 社区提示词索引 (CC BY 4.0)

## 项目结构

```
awesome-seedance/
├── SKILL.md                    ← 主编排入口：按输入类型调度子 skill
├── README.md                   ← 本文件
├── references/                 ← 详细参考文档（按需查阅）
│   ├── seedance-manual.md             ← 16模板 + 镜头词汇库 + @引用语法
│   ├── 优化分镜.md                    ← 万能公式 + 防崩关键词速查
│   ├── 好剧本.md                      ← 标准剧本范例（林冲风雪山神庙）
│   └── 故事转视频脚本-转换工具.md     ← 小说→脚本 完整工具箱
├── docs/                       ← 补充资料
│   ├── 剧本和分镜.md                  ← 剧本与分镜概念解析
│   └── structured-prompt.md           ← 结构化提示词完整指南
└── examples/                   ← 完整项目示例
    ├── 林冲-风雪山神庙/          ← 10集水墨武侠（最完整的参考示例）
    ├── 司马光砸缸/               ← 6集历史故事
    └── 武松打虎/                ← 5集经典武侠
```

## 快速开始

### 作为 Skill 使用

安装主 skill 和需要的 `sd-*` 子 skill 后，在支持 skill 的对话环境中调用：

- `awesome-seedance` — 手动调用主编排入口
- 提供剧本/小说/场景描述 — 自动触发（当任务涉及 Seedance 视频生成时）

### 两种使用路径

**路径 A：有故事/剧本 → 走完整分镜流程**

提供小说、剧本或大纲，主 skill 会按需加载：
1. 读取剧本 → 2. 拆分片段 → 3. 按戏型生成分镜 → 4. 组装提示词 → 5. 质量检查

**路径 B：单个镜头/场景 → 直接出提示词**

描述你想要的画面，skill 会用结构化标签或时间轴格式直接出可复制的 Seedance 提示词。

### 参考 material 阅读指引

| 当你需要… | 阅读 |
|-----------|------|
| 查看全部16个视频类型模板 | `references/seedance-manual.md` |
| 排查提示词常见崩坏 | `references/优化分镜.md` |
| 看完整的标准剧本长什么样 | `references/好剧本.md` |
| 学小说→剧本的完整转换方法 | `references/故事转视频脚本-转换工具.md` |
| 学结构化标签提示词怎么写 | `docs/structured-prompt.md` |
| 理解剧本和分镜的区别 | `docs/剧本和分镜.md` |

### 示例项目速览

| 项目 | 集数 | 风格 | 适合学习… |
|------|------|------|----------|
| 林冲-风雪山神庙 | 10集 | 水墨武侠 | 最完整的流程示范：剧本+素材+分镜 |
| 司马光砸缸 | 6集 | 古装写实 | 短篇故事改编，简单叙事结构 |
| 武松打虎 | 5集 | 水墨武侠 | 动作戏重点：战斗镜头节奏 |

## 外部资源

- [Seedance 官网](https://seedance.bytebase.com/)
- [Seedance2-Storyboard-Generator](https://github.com/liangdabiao/Seedance2-Storyboard-Generator)
- [YouMind 提示词画廊](https://youmind.com/zh-CN/seedance-2-0-prompts) — 在线社区提示词画廊

## 许可

本技能基于 MIT + CC BY 4.0 开源协议。
