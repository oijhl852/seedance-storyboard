---
name: seedance-browser-injector
version: "2.0.0"
last_updated: "2026-07-01"
description: >
  Seedance 2.0 网页面板自动化工具。结合 awesome-seedance 提示词生成
  与 Chrome DevTools MCP 浏览器注入。当用户需要从剧本生成 Seedance
  视频提示词、拆分为 15s 片段、并直接注入到 Seedance 网页面板编辑器
  （带 chip 和资产引用）时触发。
  触发关键词：Seedance panel, 注入提示词, 填入工作面板, 片段注入, 分镜注入,
  browser seedance, chrome seedance injection.
agent_created: true
---

# Seedance 浏览器注入器

自动化工作流：剧本 → 提示词生成 → 浏览器注入到 Seedance 网页面板。

## 前置条件

- Chrome DevTools MCP 已在 `reasonix.toml` 中配置
- 用户已在 Chrome 中打开 Seedance 面板，启用了远程调试（`--remote-debugging-port=9222`）
- `awesome-seedance` skill 可用

## 面板元素参考（Panel Element Reference）

Seedance 2.0 网页面板的权威参考。编写选择器或脚本前务必查阅。

### 1. 视频状态检测

| 状态 | HTML 特征 | 含义 |
|------|----------|------|
| 🟡 生成中 | `div.el-loading-mask` 包含 `task ID: NNN...` | 视频正在生成 |
| 🟢 已完成 | `<video class="vjs-tech" src="...mp4">` | 视频已完成，可播放 |

### 2. 集（Episode）切换

| 元素 | 选择器 |
|------|--------|
| 集选择器（关闭状态） | `input[readonly]` value="第X集"（7 个 el-select 输入框中的**第一个**） |
| 下拉列表 | `ul.el-select-dropdown__list` |
| 集选项 | `li.el-select-dropdown__item` 包含 `<span>第N集</span>` |
| 当前选中 | `li.el-select-dropdown__item.selected` |

**⚠️ 7 个 el-select 下拉框共用同一个弹出面板。** 切换集的方法：
1. 点击第一个 `input[readonly]`（value="第X集"）打开正确的下拉框
2. 通过匹配 `textContent === '第N集'` 点击目标 `li.el-select-dropdown__item`
3. 页面将以新的 `part_no` 重新加载

### 3. 片段（Segment）切换

| 元素 | 选择器 | 备注 |
|------|--------|------|
| 时间线节点 | `div.timeline-node` | 每个片段是一个 `.timeline-node` |
| 片段序号 | `div.card-order` | 包含**片段编号**文本（如 "6"）——**这是权威 ID** |
| 片段封面图 | 目标 `.timeline-node` 内 `.card-preview` 下的 `img.img` | **点击此处切换** |
| 空片段 | `<img class="empty" src="/images/bubble-empty...">` | 尚无内容 |
| 活动片段 | `div.video-card.item.active` | 当前选中的片段带 `.active` 类 |

**⚠️ 关键：** 片段编号是每个 `.timeline-node` 内的 `card-order` 文本，**不是**封面图片的索引。DOM 是一个平铺的 `.timeline-node` 列表，按照显示顺序排列。切换到片段 N 的方法：

```javascript
// ✅ 正确：找到 .card-order 文本匹配 N 的 .timeline-node，然后点击其 img
function switchToSegment(n) {
  const nodes = document.querySelectorAll('.timeline-node');
  for (const node of nodes) {
    const orderEl = node.querySelector('.card-order');
    if (orderEl && orderEl.textContent.trim() === String(n)) {
      const img = node.querySelector('img.img');
      if (img) { img.click(); return true; }
    }
  }
  return false;
}
switchToSegment(6); // 切换到片段 6
```

**绝不**使用 `document.querySelectorAll('img.img[src*="segment_cover"]')[N]`——DOM 中图片的索引与片段编号不对应。始终按 `card-order` 文本匹配。

### 4. 资产库（Asset Library）

| 元素 | 选择器 |
|------|--------|
| 容器 | `div.resource-wrap` |
| 分类标签 | `div.capsule-btn`（角色 / 场景 / 道具 / 加白资源） |
| 当前分类 | `div.capsule-btn.active` |
| 搜索框 | `input[placeholder="资源名模糊查询"]` |
| 资产卡片 | `div.item`——包含 `img`（缩略图）+ `span.name-text`（名称） |
| 应用到首帧 | 包含文字"应用到首帧"的 `button` |
| 应用到尾帧 | 包含文字"应用到尾帧"的 `button` |

### 5. 提示词编辑器（Prompt Editor）

| 元素 | 选择器 |
|------|--------|
| 编辑器容器 | `[contenteditable="true"]` |
| 引用 chip | `span.mention-chip` |
| 角色 chip | `data-source-kind="role"` |
| 场景 chip | `data-source-kind="scene"` |
| 道具 chip | `data-source-kind="prop"` |
| 音频 chip | `data-source-kind="audio"` |

**需要提取的 chip data 属性：**
- `data-id`——例如 `"role:9099"`（**必填**——绝不使用占位符 "0"）
- `data-url`——资产图片 URL
- `data-asset-id`——平台资产 ID（例如 `"asset-20260525..."`；某些资产可能为空）
- `data-source-kind`——`"role"` / `"scene"` / `"prop"` / `"audio"`

---

## 工作流（Workflow）

### Phase 1: 连接到 Seedance 面板

1. 加载 `awesome-seedance` skill 获取提示词生成知识
2. 使用 `mcp__chrome-devtools__list_pages` 验证 Seedance 面板 URL 处于活动状态
3. 使用 `mcp__chrome-devtools__take_snapshot` 读取当前面板状态（选中了哪个片段、编辑器里有什么）

#### 1.1 工具可用性速查（MCP Tool Availability）

**⚠️ 视频播放器是性能杀手。** 页面有 video 元素后，多数 MCP 工具会超时。关键规律：

| 工具 | 视频页面 | 干净页面（刚reload） | 原理 | 超时替代方案 |
|------|---------|-------------------|------|------------|
| `press_key` | ✅ 始终可用 | ✅ | 单向发送，不等待回传 | — |
| `type_text` | ✅ 始终可用 | ✅ | 同上 | — |
| `navigate_page` | ✅ 始终可用 | ✅ | 浏览器级操作 | — |
| `take_snapshot` | ✅ 始终可用 | ✅ | 读取DOM快照 | — |
| `click` | ❌ 超时 | ✅ 可用 | 需要CDP回传确认 | `press_key` Tab导航到目标元素 + Enter |
| `fill` | ❌ 超时 | ✅ 可用 | 同上 | `type_text` 逐字输入 |
| `evaluate_script` | ❌ 超时 | ✅ 可用 | 需要序列化返回值 | 异步 `fetch` API 调用（在页面内执行，不经过 CDP 回传通道） |
| `hover` | ❌ 超时 | ✅ 可用 | 同上 | `press_key` Tab 聚焦到目标元素 |

**操作策略**：
- 页面刚 reload 后的 5-10 秒是**黄金窗口**——所有工具正常响应
- 如果页面已经有视频在播放，**先 reload** 再操作
- 不可逆操作（如修改提示词）优先走 API（`segment/update`），不受页面状态影响

#### 1.2 面板参数修改流程（Changing Ratio/Resolution/Duration/Model）

所有下拉参数（画幅/分辨率/时长/模型）都是 `el-select` 组件。标准操作流：

```
1. click 下拉框（textbox readonly value="当前值"）
2. take_snapshot 看弹出的下拉选项
3. click 目标选项
```

下拉选项出现在 `<uid=N_0>` 开始的独立区域中，以 StaticText 列表形式呈现。

**各下拉框的选项值**：

| 参数 | 常见选项 |
|------|---------|
| 画幅 | 9:16、16:9、4:3、1:1、3:4、21:9 |
| 分辨率 | 480p、720p、2K |
| 时长 | 4s、5s…15s（1s步进） |
| 模型 | 即梦 测试模型a 等 |

**价格联动**：分辨率↑和时长↑都会增加生成费用。

#### 1.3 手动 @ 触发资产 Chip（Triggering @mention for Native Chips）

`type_text` 工具可以直接在编辑器中输入 `@角色名` 触发平台的资产 mention 弹窗，然后点击选项插入原生的资产 chip。这是**唯一能保证资产正确绑定的 chip 创建方式**——比 execCommand 注入 chip HTML 可靠。

```
1. click 编辑器区域（generic value="..."）
2. type_text "@沈"（输入@加筛选关键词）
3. take_snapshot 看 mention 弹窗
4. click 目标资产选项
5. chip 自动插入编辑器末尾
```

弹窗结构：独立区域包含搜索框（`textbox "输入内容进行筛选"`）、类型筛选（`textbox "请选择筛选类型"`）、资产列表（image + name + description）。

### Phase 2: 提取资产数据与 API 凭证

注入任何提示词之前，先从面板提取 chip 数据和 API 凭证：

#### 2.0 提取 API 凭证

凭证因项目而异。始终从 localStorage 提取，不从 URL 参数：

```javascript
const ticket = localStorage.getItem('ticket_production')?.replace(/"/g, '');
const userId = JSON.parse(localStorage.getItem('user') || '{}')?.info?.userid;
const projectId = new URL(window.location.href).searchParams.get('project_id');
const partNo = new URL(window.location.href).searchParams.get('part_no');
```

#### 2.1 读取原生 Chip 数据

1. 阅读 `references/chip-format.md` 了解正确的 chip HTML 结构
2. 如果编辑器已包含原生 chip（用户通过 `@` 创建的），用 `evaluate_script` 读取其 `data-id`、`data-url` 和 `data-asset-id`
3. 对于尚未在编辑器中的新资产，先要求用户手动 `@` 创建原生 chip，再提取数据
4. 将所有 chip 数据存为键值对：`{name: {type, id, url, assetId}}`

**关键规则：** 绝不使用占位符 ID 注入 chip，如 `data-id="role:0"`。这会导致 `invalid asset uri` 错误。只使用从平台提取的已验证真实资产 ID。

### Phase 3: 从剧本生成提示词

**提示词生成委托给 `awesome-seedance` skill。** 本 skill 只负责注入——分镜拆分、标签模板、台词保真、节奏控制全部由 awesome-seedance 处理。

基本流程：
1. 调用 `awesome-seedance` skill，传入剧本原文，生成分镜提示词
2. 每段提示词需包含完整的 11 标签（风格/画幅/镜头/环境/布光/光影/色调/特效/运镜/构图/表演/角色）
3. 默认参数：竖屏 9:16, UE5 电影级渲染, 720p, 15s

注入前以表格形式呈现分段方案，用户确认后再注入。

### Phase 4: 通过 API 注入面板

**⚠️ 关键：DOM 操作不持久。** 在 contenteditable 编辑器上设置 `innerHTML` 或使用 `execCommand` 在 tab 切换时**不会保留**——Vue 面板从 `segment/list` API 数据重新渲染，丢弃所有纯 DOM 修改。**唯一可靠的注入方法是直接调用平台的 `segment/update` API。**

**🔴 致命：绝不删除片段。** 调用 `segment/del` 会永久销毁片段记录，并切断该片段已生成视频文件的链接。用户已生成的视频无法恢复。

**唯一安全的操作：**
- `POST segment/update`——修改已有片段的内容
- 在 UI 中点击"+"——追加一个新的空片段
- **绝不**调用 `segment/del`，除非用户明确要求
- **绝不**用"先删后建"的方式重排片段顺序

#### 4.1 获取片段列表（拿 ID）

```javascript
const ticket = 'd48cf42cff39f96f313e6f784d9e12b2'; // 从 URL 参数
const userId = '17512815021488966';                // 从 URL 参数
const resp = await fetch(
  `https://service.fujunhn.cn/api/v1/aigc/segment/list?ticket=${ticket}&user_id=${userId}&project_id=${projectId}&part_no=${partNo}&_t=${Date.now()}`
);
const segments = (await resp.json()).data.segments;
// 返回：[{id, seq, name, content, ...}, ...]
// 按 seq 号匹配：seq=1 → 片段1，seq=2 → 片段2，依此类推
```

#### 4.2 构建 Chip HTML（API 格式）

API 要求 `<span class="mention-chip">` 元素包含全部 data 属性。chip 函数签名：

```javascript
const chipHtml = (dataId, sourceId, name, desc, remark, url, assetId, assetType, sourceKind, avatarBg) => {
  const bg = avatarBg || 'linear-gradient(135deg, #9077ff, #5965ff)';
  return `<span class="mention-chip" contenteditable="false" data-id="${dataId}" data-source-id="${sourceId}" data-name="${name}" data-desc="${desc||''}" data-remark="${remark||''}" data-label="${name}" data-avatar-bg="${bg}" data-url="${url}" data-asset-id="${assetId||''}" data-asset-type="${assetType}" data-source-kind="${sourceKind}"><span class="mention-chip-avatar"><img class="mention-chip-avatar-image" src="${url}" alt="${name}"></span><span class="mention-chip-label">${name}</span></span>`;
};

// 便捷包装器：
const roleChip = (id, name, desc, url, assetId) =>
  chipHtml(`role:${id}`, `${id}`, name, desc, desc, url, assetId, 'image', 'role');

const sceneChip = (id, name, desc, url) =>
  chipHtml(`scene:${id}`, `${id}`, name, desc, desc, url, '', 'image', 'scene');

const audioChip = (id, name, url) =>
  chipHtml(`audio:${id}`, `${id}`, name, '', '', url, '', 'audio', 'audio', 'linear-gradient(135deg, #ff6b9d, #c7445e)');
```

**data-id 格式**：`type:number`（例如 `role:22912`，`scene:15484`，`audio:16029`）。  
**data-source-id 格式**：仅数字（例如 `22912`），不带类型前缀。  
**音频 chip**：使用 `data-asset-type="audio"`，粉色头像背景 `linear-gradient(135deg, #ff6b9d, #c7445e)`。

#### 4.3 构建完整内容 HTML

以 HTML 形式构建完整提示词，chip span 内联嵌入。用 `<br>` 换行：

```javascript
const br = '<br>';
const content =
`【风格】3D写实CG渲染...${br}` +
`【镜头】UE5电影级虚拟摄影机...${br}` +
`【环境】${sceneChip(15484, '大湾村-海滩-日-外', '日-外', beachUrl)}${br}` +
`【布光】...${br}` +
`【角色】${roleChip(22912, '沈清雪-职场西装干练套装', '职场西装干练套装', sqxUrl, 'asset-...')} ${roleChip(22915, '李村长-旧衬衫布鞋渔村装扮', '旧衬衫布鞋渔村装扮', lczUrl, 'asset-...')}${br}` +
`${br}` +
`【标题】${br}` +
`镜头1：近景，${roleChip(...)}面向李村长...${audioChip(16029, '音频-沈清雪', sqxUrl)}声音沉稳：「二叔，你觉得我为什么要回来？」${br}` +
`...`;
```

#### 4.4 调用 segment/update API

```javascript
const resp = await fetch(
  `https://service.fujunhn.cn/api/v1/aigc/segment/update?ticket=${ticket}&user_id=${userId}&_t=${Date.now()}`,
  {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
      id: segmentId,        // 从 segment/list 获取（例如 82571）
      project_id: projectId, // 从 URL 参数
      part_no: partNo,      // 从 URL 参数
      content: contentHtml  // 完整的 HTML 字符串
    })
  }
);
const result = await resp.json();
// result.data.success === true → 注入成功
```

#### 4.5 刷新页面

更新后重新加载页面，让 Vue 加载新数据：

```javascript
// 通过 mcp__chrome-devtools__navigate_page，type="reload"
```

#### 4.6 完整注入脚本

```javascript
async function injectSegment(segmentId, projectId, partNo, contentHtml) {
  const params = new URLSearchParams(window.location.search);
  const ticket = params.get('ticket') || 'd48cf42cff39f96f313e6f784d9e12b2';
  const userId = params.get('user_id') || '17512815021488966';
  const resp = await fetch(
    `https://service.fujunhn.cn/api/v1/aigc/segment/update?ticket=${ticket}&user_id=${userId}&_t=${Date.now()}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ id: segmentId, project_id: projectId, part_no: partNo, content: contentHtml })
    }
  );
  return (await resp.json()).data?.success === true;
}
```

#### 4.7 验证注入结果

1. 刷新页面（reload）
2. 点击片段 tab 选择该片段（或用 `switchToSegment(n)`）
3. 用 `evaluate_script` 检查 chip 数量：`document.querySelectorAll('[contenteditable] img.mention-chip-avatar-image').length`
4. 拍 snapshot 目视确认所有 chip 正确渲染

### Phase 5: 注入后提醒

每次注入后提醒用户：
- 将片段时长设为 15s（默认通常是 4s）
- 在浏览器中目视检查 chip 渲染（图片 chip vs 纯文本）
- 提醒用户：仅在收到指令时才注入下一个片段
- ⚠️ **绝不删除任何片段**——详见 Phase 4 致命警告

## 故障排除（Troubleshooting）

| 错误/现象 | 原因 | 修复方法 |
|----------|------|---------|
| `invalid asset uri` | data-id 用了占位符 `role:0` | 先从原生 chip 提取真实 ID |
| 切换 tab 后内容丢失 | DOM 注入（innerHTML/execCommand）不持久——Vue 从 API 数据重新渲染 | 改用 `POST segment/update`；之后 reload 页面 |
| 删除片段导致已生成视频丢失 | 调用了 `segment/del`——不可逆地销毁片段并切断视频链接，无法恢复 | **绝不删除。** 只 UPDATE 已有片段或通过"+"追加新段。任何删除操作必须问用户。 |
| 切回片段后 chip 消失 | innerHTML 改动被 Vue 从 `segment/list` 重新加载时丢弃 | 通过 API 注入，不操作 DOM |
| execCommand 注入的 chip 不被平台识别 | 平台资产绑定只在手动 `@` 时触发，DOM 注入不会触发 | 删除注入的 chip，手动 `@` 同名资产，再通过 API 重新注入 |
| 编辑器显示纯文字 chip | chip 没有注册到 Vue 数据模型 | 用户需先手动 `@` 原生 chip 获取真实 ID，再通过 API 注入 |
| `content[6].image_url.url` | 某个资产的 URI 无效 | 检查所有 data-id 为真实值；先用单个 chip 测试 |
| 注入覆盖了原生 chip | innerHTML 全量替换 | 先提取原生 chip HTML，在此基础上构建 |
| 切片段时触发了删除 | 点了序号按钮而非封面图 | 使用 `switchToSegment(n)`——按 `.card-order` 文字匹配，不按图片索引 |
| 同一角色连续出现 3+ 镜 | 没有穿插反应镜头 | 在长独白之间插入 1-2s 其他角色的无台词反应镜头 |
| 台词在句中被打断 | 拆分点选错了 | 只在自然停顿处拆分（。！？）或在不同语义段落之间 |
| snapshot 太短看不到内容 | DOM 树太大被截断 | 用 `evaluate_script` 直接读 `[contenteditable].textContent` |
| 资产"未通过审核" | chip 引用的资产不在本项目资产库里 | 去掉 chip HTML 改用纯文字描述；告诉用户缺失了哪个资产 |
| evaluate_script 在视频多的页面超时 | 页面多个 `<video>` 播放器消耗浏览器资源 | 改用异步 `fetch` API 调用代替 DOM 查询；脚本尽量精简 |
| click/fill 返回 "element no longer exists" | 视频播放时页面反复重渲染，UID 快速过期 | **先 reload** 获得干净页面的"黄金窗口"（约10秒），snapshot 后立刻 click |
| 不同项目 API 凭证不同 | `ticket` 和 `user_id` 存在 localStorage（`ticket_production`、`user`），不在 URL 参数里 | 始终从 `localStorage.getItem('ticket_production')` + `JSON.parse(localStorage.getItem('user')).info.userid` 提取 |

## 完整注入检查清单（Complete Injection Checklist）

**生成提示词前：**
- [ ] 所有资产 data-id 已验证（无占位符 "0"）
- [ ] 原剧本在旁边逐句对照验证

**提示词质量：**
- [ ] 每句原剧本台词出现且仅出现一次（无遗漏、无重复）
- [ ] 每段 5-6 镜（不超过此密度）
- [ ] 主角合计占 ~80% 屏幕时间；配角每段最多 1 镜
- [ ] 11 个技术标签齐全：风格/画幅/镜头/环境/布光/光影/色调/特效/运镜/构图/表演
- [ ] 反向约束齐全：禁止越轴、不生成多个相同角色、眨眼动作、不生成文字
- [ ] 尾帧画面描述与下一段首帧一致

**注入前：**
- [ ] Chrome DevTools MCP 已连接
- [ ] Seedance 面板页面已激活
- [ ] 已通过 `segment/list` API 获取片段 ID
- [ ] 所有 chip data-id 已验证（无占位符 "0"）
- [ ] 用户已确认分镜表

**注入后：**
- [ ] `segment/update` API 返回 `success: true`
- [ ] 页面已刷新，Vue 加载了新数据
- [ ] snapshot 确认所有 chip 在正确片段上渲染
- [ ] 时长已设为 15s（默认是 4s）
- [ ] 提醒用户：仅收到指令时注入下一段

---

## 🔄 版本与更新（Version & Sync）

**仓库地址**：`https://github.com/oijhl852/agent-skill-sync`

**自动检查规则**：每次本 skill 被调用时，agent 应：
1. `web_fetch` 读取 `https://raw.githubusercontent.com/oijhl852/agent-skill-sync/main/seedance-browser-injector/SKILL.md` 的 frontmatter
2. 对比 `version` 和 `last_updated` 字段
3. 如果仓库版更新 → 提醒用户拉取；如果本地版更新 → 提醒用户推送

**修改后推送规则**：对本 skill 做了优化或新增内容后，agent 应：
1. 递增 `version` 补丁号（如 2.0.0 → 2.0.1），更新 `last_updated` 为当天日期
2. 复制到工作区：`copy "C:\Users\User\.reasonix\skills\seedance-browser-injector\SKILL.md" "F:\AI分镜\"`
3. 提醒用户在 `F:\AI分镜\agent-skill-sync` 仓库中执行：
   ```
   git add seedance-browser-injector/SKILL.md
   git commit -m "v2.0.1: [改动摘要]"
   git push
   ```
