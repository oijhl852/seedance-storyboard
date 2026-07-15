# 本地社区提示词语料

本目录保存4776条完整CSV语料，以及上游仓库打包的106条Markdown快速预览，供 Agent 对比、归纳和评估。

## 使用方式

1. 优先使用 `scripts/search-community-corpus.ps1` 搜索完整CSV。
2. 也可以先读 `index.md`，从106条快速预览中找案例。
3. 选取 3-5 条相关案例，使用 `quality-rubric.md` 分别评分。
4. 归纳有效结构和失败模式，再生成新的提示词；不要直接拼接或整段照抄。

完整CSV包含4776条提示词，106条Markdown用于无需解析CSV时快速预览。

重新拉取上游仓库后，可运行：

```powershell
& "D:\素材\神奇妙妙工具\agent-skill-sync\scripts\build-community-corpus.ps1"
```
