---
name: sd-prompt-library
version: "1.1.0"
last_updated: "2026-07-15"
author: "Takis/安梓豪"
description: Seedance 精选案例库 — 8大类风格提示词模板，带视频效果参考。由 awesome-seedance 主 skill 调用。
repository: https://github.com/oijhl852/agent-skill-sync
---

# sd-prompt-library — 案例库

> 作者：Takis/安梓豪 | 仓库：[agent-skill-sync](https://github.com/oijhl852/agent-skill-sync)

按风格分类的精选 Seedance 2.0 提示词案例，供参考和复用。

（来源：ZeroLu/awesome-seedance，CC BY 4.0）

本 skill 是参考库，不直接替用户选择风格。使用时先说明用户目标，再挑一个最接近的结构，不能整段照抄与原项目无关的角色、品牌或剧情。

## 1. 电影级风格

- 好莱坞赛车片（Le Mans雨夜）
- Denis Villeneuve 沙漠史诗（IMAX 70mm）
- 王家卫风格（雨夜电话亭）
- Replicate 大片包（空间站碰撞/峡谷追逐/航母起飞等）
- 时间戳分镜序列（武士落日/火星着陆/东京雨夜）

## 2. 广告商业风

- 产品特写/360旋转/爆炸分解
- 3D渲染特效展示
- 品牌落版与slogan

## 3. 社交媒体风

- 短视频爆款模板
- 快节奏卡点

## 4. UGC 风格

- 第一人称Vlog
- 纪录片质感

## 5. 动漫/动画风

- 宫崎骏风格
- 梵高油画风格
- 日漫赛璐璐
- 国漫3D渲染

## 6. 短剧风

- 春晚小品风（甄嬛+胡飞）
- 霸总短剧（撕合同反杀）
- 情感暴雨夜戏

## 7. VFX 特效风

- 超现实天空拉链
- 图片流体变形
- 轨道碰撞物理模拟

## 8. 资源

- 全部视频效果见：https://github.com/ZeroLu/awesome-seedance
- 在线画廊：https://youmind.com/zh-CN/seedance-2-0-prompts
- 商业案例参考：`references/zerolu-commercial-use-cases.md`
- 提示词框架摘要：`references/songguoxs-prompt-framework-notes.md`
- 剧本到分镜方法摘要：`references/storyboard-workflow-notes.md`
- 来源与读取说明：`references/README.md`

按需读取与当前任务相关的一个参考文件，不要把两个大文件同时加载进上下文。

## 快速套用案例

### 电影叙事：雨夜追车

```text
15秒，9:16竖屏，电影级写实；雨夜城市高架，黑色轿车高速变道，湿地反光；
0-3秒远景建立城市与车流，3-7秒车内近景切驾驶者后视镜，7-12秒低机位跟拍急转弯，
12-15秒刹车灯映在积水上并停在画面右侧；冷蓝主色、红色尾灯点缀；无字幕、无BGM。
```

### 商业广告：产品旋转

```text
8秒，1:1，纯色无缝背景；产品置中缓慢360度旋转，镜头从中景推进到细节特写，
金属边缘出现柔和高光，最后定格在品牌正面；背景干净，无多余文字和手部遮挡。
```

### 社交短视频：第一人称开箱

```text
10秒，9:16，手持第一人称；0-2秒快速打开包装，2-6秒展示核心部件，
6-9秒实际使用，9-10秒回到产品全貌；自然室内光，轻微手持抖动，保留环境音，不加BGM。
```

案例输出时同时说明：适用场景、可替换字段、容易失败的地方。

## 🔄 更新

仓库：https://github.com/oijhl852/agent-skill-sync
