---
name: sd-inject
version: "1.1.0"
last_updated: "2026-07-15"
author: "Takis/安梓豪"
description: API 注入引擎 — 凭证提取、segment/list、segment/update、注入验证。由 awesome-seedance 主 skill 调用。
repository: https://github.com/oijhl852/agent-skill-sync
---

# sd-inject — 注入引擎

> 作者：Takis/安梓豪 | 仓库：[agent-skill-sync](https://github.com/oijhl852/agent-skill-sync)

通过 Seedance 平台 API 将提示词注入面板编辑器。

## 致命警告

🔴 **绝不调用 `segment/del`** — 永久删除片段并切断已生成视频的链接。

🔴 **DOM 操作不持久** — Vue 从 API 数据重新渲染。唯一可靠方法是通过 `segment/update` API。

🔴 **默认只注入新建的空白片段** — 不覆盖、不删除已有片段。先由 `sd-panel` 建立空白片段并确认其序号，再获取新片段 ID。

## 工作流程

### 1. 提取 API 凭证

```javascript
const ticket = localStorage.getItem('ticket_production')?.replace(/"/g, '');
const userId = JSON.parse(localStorage.getItem('user') || '{}')?.info?.userid;
const projectId = new URL(window.location.href).searchParams.get('project_id');
const partNo = new URL(window.location.href).searchParams.get('part_no');

if (!ticket || !userId || !projectId || !partNo) {
  throw new Error('缺少面板凭证或项目参数，停止注入，不要使用占位符继续。');
}
```

 凭证只在当前页面内存中使用。不要把完整请求 URL、`ticket` 或用户信息写入日志、截图、回复或提交到仓库。

为避免参数中的特殊字符破坏请求，使用 `URL` 和 `searchParams` 组装地址，不要直接拼接未经编码的凭证。

```javascript
const apiUrl = (path, params) => {
  const url = new URL(`https://service.fujunhn.cn/api/v1/aigc/${path}`);
  Object.entries(params).forEach(([key, value]) => url.searchParams.set(key, String(value)));
  url.searchParams.set('_t', String(Date.now()));
  return url;
};
```

### 2. 获取片段列表

```javascript
const resp = await fetch(apiUrl('segment/list', {ticket, user_id: userId, project_id: projectId, part_no: partNo}));
if (!resp.ok) throw new Error(`segment/list HTTP ${resp.status}`);
const listResult = await resp.json();
const segments = listResult?.data?.segments;
if (!Array.isArray(segments)) {
  throw new Error('segment/list 返回结构异常，停止注入。');
}

const segmentBySeq = new Map();
for (const segment of segments) {
  const seq = String(segment?.seq ?? '');
  if (!segment?.id || !seq || segmentBySeq.has(seq)) {
    throw new Error('片段列表存在缺失或重复的 seq/id，停止注入。');
  }
  segmentBySeq.set(seq, segment);
}
```

### 3. 注入提示词

注入前确认目标片段是刚建立的空白片段。若 `segment/list` 显示目标片段已有内容，停止并报告，不要直接覆盖。

```javascript
const resp = await fetch(
  apiUrl('segment/update', {ticket, user_id: userId}),
  {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
      id: segmentId,
      project_id: projectId,
      part_no: partNo,
      content: contentHtml
    })
  }
);
if (!resp.ok) throw new Error(`segment/update HTTP ${resp.status}`);
const result = await resp.json();
if (result?.data?.success !== true) {
  throw new Error('segment/update 未确认成功，停止后续片段写入。');
}
```

### 写入前确认

调用 `segment/update` 前，必须先向用户展示：新建片段编号、空白状态、新内容摘要、将使用的资产 chip，以及预计修改的片段数量。只有用户明确回复确认后才能写入；取消、超时、目标片段非空或内容无法匹配时，保持原有片段不变。

只有用户明确要求“覆盖已有片段”时，才允许把目标从空白片段改为已有片段，并再次展示原内容与新内容的差异后确认。

批量注入时按片段顺序逐个更新。任意一个片段失败就停止后续写入，并报告已成功的片段和第一个失败片段，不自动重试整批。

### 4. 验证注入

```
1. 刷新页面 (navigate_page type="reload")
2. switchToSegment(n) 切换到目标片段
3. 检查 chip 数量
```

验证时同时确认：片段 ID 与 `seq` 对应、目标片段原本为空、页面重新加载后内容仍存在、chip 的 `data-id` 和图片 URL 与交接表一致。

## 注入后提醒

- 将片段时长设为15s（默认4s）
- 目视检查 chip 渲染
- 仅收到指令时注入下一段

## 🔄 更新

仓库：https://github.com/oijhl852/agent-skill-sync
