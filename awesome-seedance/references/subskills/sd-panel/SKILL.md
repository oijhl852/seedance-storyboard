---
name: sd-panel
version: "1.1.0"
last_updated: "2026-07-15"
author: "Takis/安梓豪"
description: Seedance 浏览器面板连接 — Chrome DevTools MCP 连接、元素定位、工具可用性检测。由 awesome-seedance 主 skill 调用。
repository: https://github.com/oijhl852/agent-skill-sync
---

# sd-panel — 面板连接

> 作者：Takis/安梓豪 | 仓库：[agent-skill-sync](https://github.com/oijhl852/agent-skill-sync)

管理 Seedance 网页面板的浏览器连接和元素定位。

## 前置条件

- Chrome DevTools MCP 已配置
- Chrome 以 `--remote-debugging-port=9222` 运行
- Seedance 面板已打开

缺少任一条件时停止，不要尝试猜测页面地址、选择器或凭证。

## 工作流程

### 1. 连接面板

```javascript
mcp__chrome-devtools__list_pages → 找到 Seedance 面板 URL
mcp__chrome-devtools__select_page → 选中面板
mcp__chrome-devtools__take_snapshot → 读取当前状态
```

### 2. 检测视频状态

| 状态 | 特征 |
|------|------|
| 🟡 生成中 | `div.el-loading-mask` 包含 `task ID` |
| 🟢 已完成 | `<video class="vjs-tech">` 存在 |

### 3. 工具可用性

| 页面状态 | 可用工具 | 不可用工具 |
|---------|---------|-----------|
| 有视频播放 | press_key / type_text / navigate_page / take_snapshot | click / fill / evaluate_script / hover |
| 刚reload | 全部可用（黄金窗口约10秒） |

**有视频时先 reload 再操作。**

不要把“黄金窗口约10秒”当成固定计时。reload 后先重新 snapshot，确认目标元素存在且页面不再加载，再执行下一步。

### 4. 切换集（Episode）

```
1. click 第一个 input[readonly] (value="第X集")
2. click li.el-select-dropdown__item 匹配 "第N集"
3. 页面自动以新 part_no 重新加载
```

### 5. 切换片段（Segment）

```javascript
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
```

⚠️ 使用 `card-order` 文字匹配，不使用图片索引。

### 6. 修改面板参数

所有 `el-select` 下拉参数（画幅/分辨率/时长/模型）：
```
1. click 下拉框 (readonly value="当前值")
2. take_snapshot 看选项
3. click 目标选项
```

分辨率、时长和模型可能影响费用或生成结果。修改前先展示旧值和新值，得到用户确认后再点击。

### 7. 建立新的空白片段

修改已有工程时，默认不点击已有片段进行覆盖。标准流程是：

1. 在面板中点击“+”建立新的空白片段。
2. 重新 snapshot，确认新片段没有已有内容并记录它的序号。
3. 将新提示词和已验证的 chip 注入这个空白片段。
4. 只有用户明确要求覆盖原片段时，才进入覆盖确认流程。

如果面板没有“+”或无法确认新片段为空，停止操作并请用户手动建立空白片段。

## 失败处理

- 找不到目标页面：列出当前页面标题和地址，请用户打开正确面板。
- 找不到选择器：重新 snapshot；仍不存在时停止，不使用相似元素代替。
- 工具超时：按“reload → snapshot → 键盘导航”顺序降级，不能连续重复点击。
- 页面重新渲染后 UID 失效：重新 snapshot 获取新 UID，不复用旧 UID。

## 🔄 更新

仓库：https://github.com/oijhl852/agent-skill-sync
