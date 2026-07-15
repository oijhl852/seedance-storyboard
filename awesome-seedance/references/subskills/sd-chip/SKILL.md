---
name: sd-chip
version: "1.1.0"
last_updated: "2026-07-15"
author: "Takis/安梓豪"
description: 资产 chip 管理 — @mention 触发、chip 数据提取、HTML 构建。由 awesome-seedance 主 skill 调用。
repository: https://github.com/oijhl852/agent-skill-sync
---

# sd-chip — 资产 Chip 管理

> 作者：Takis/安梓豪 | 仓库：[agent-skill-sync](https://github.com/oijhl852/agent-skill-sync)

管理 Seedance 面板中资产引用 chip 的创建和数据提取。

## Chip HTML 结构

```html
<span class="mention-chip" contenteditable="false"
  data-id="role:3195"
  data-name="秦牧-基础形象"
  data-label="秦牧-基础形象"
  data-avatar-bg="linear-gradient(135deg, #9077ff, #5965ff)"
  data-url="https://..."
  data-asset-id="asset-20260427-..."
  data-source-kind="role">
  <span class="mention-chip-avatar">
    <img class="mention-chip-avatar-image" src="..." alt="秦牧-基础形象">
  </span>
  <span class="mention-chip-label">秦牧-基础形象</span>
</span>
```

## 关键属性

| 属性 | 说明 | 示例 |
|------|------|------|
| data-id | 资产ID（必填，不可为0） | `role:3195` |
| data-source-kind | 资产类型 | role / scene / prop / audio |
| data-url | 资产图片URL | https://... |
| data-asset-id | 平台资产ID | asset-20260427-... |

## 提取原生 Chip

```javascript
const chips = document.querySelectorAll('.mention-chip');
for (const c of chips) {
  const label = c.querySelector('.mention-chip-label')?.textContent || '';
  const id = c.dataset.id;
  const url = c.dataset.url;
  const assetId = c.dataset.assetId;
  const kind = c.dataset.sourceKind;
}
```

## 构建 Chip HTML

```javascript
const escapeHtml = (value) => String(value ?? '').replace(/[&<>"']/g, (char) => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
}[char]));

const chipHtml = (asset) => {
  const required = ['dataId', 'sourceId', 'name', 'url', 'sourceKind'];
  const missing = required.filter((key) => !asset?.[key]);
  if (missing.length || /:(0|null|undefined)$/.test(String(asset.dataId))) {
    throw new Error(`资产字段不完整或 ID 无效：${missing.join(',')}`);
  }
  const bg = asset.avatarBg || 'linear-gradient(135deg, #9077ff, #5965ff)';
  const text = (key) => escapeHtml(asset[key]);
  return `<span class="mention-chip" contenteditable="false" data-id="${text('dataId')}" data-source-id="${text('sourceId')}" data-name="${text('name')}" data-desc="${text('desc')}" data-remark="${text('remark')}" data-label="${text('name')}" data-avatar-bg="${escapeHtml(bg)}" data-url="${text('url')}" data-asset-id="${text('assetId')}" data-asset-type="${text('assetType') || 'image'}" data-source-kind="${text('sourceKind')}"><span class="mention-chip-avatar"><img class="mention-chip-avatar-image" src="${text('url')}" alt="${text('name')}"></span><span class="mention-chip-label">${text('name')}</span></span>`;
};
```

标准资产对象至少包含：`dataId`、`sourceId`、`name`、`url`、`sourceKind`。
从页面提取的真实字段优先，不能用 `role:0`、假 URL 或临时名称代替。

## 手动 @mention

```
1. click 编辑器区域
2. type_text "@角色名"（触发 mention 弹窗）
3. click 目标资产选项
4. chip 自动插入编辑器末尾
```

⚠️ 绝不使用占位符 ID（如 `role:0`），会导致 `invalid asset uri` 错误。

## 交接给 sd-inject

输出 `{name, dataId, sourceId, url, assetId, sourceKind}` 映射表，并标记每个资产是否已在页面中验证。未验证的资产不能进入 API 注入。

## 剧本名称对应

注入前把剧本中的场景名、角色名、道具名与面板显示名称逐项对应。优先使用资产清单中的稳定编号，再用面板提取的真实 `data-id`、`data-url` 和 `data-asset-id` 完成映射。

同名但不同状态的资产必须分开记录，例如“林冲-正常状态”和“林冲-受伤状态”不能只保留一个名称。

## 🔄 更新

仓库：https://github.com/oijhl852/agent-skill-sync
