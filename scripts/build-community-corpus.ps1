param(
    [string]$Source = (Join-Path (Split-Path -Parent $PSScriptRoot) 'awesome-seedance-2-prompts\README_zh.md'),
    [string]$Output = (Join-Path (Split-Path -Parent $PSScriptRoot) 'sd-community\corpus'),
    [int]$ChunkSize = 20
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Source)) {
    throw "Community source not found: $Source"
}
if ($ChunkSize -lt 1) {
    throw 'ChunkSize must be greater than zero.'
}

function Get-MarkdownSection {
    param(
        [string[]]$Block,
        [string]$Heading
    )

    $start = -1
    for ($i = 0; $i -lt $Block.Count; $i++) {
        if ($Block[$i] -match "^####\s+$Heading\s*$") {
            $start = $i + 1
            break
        }
    }
    if ($start -lt 0) { return '' }

    $result = New-Object System.Collections.Generic.List[string]
    for ($i = $start; $i -lt $Block.Count; $i++) {
        if ($Block[$i] -match '^####\s+') { break }
        if ($Heading -match '提示词' -and $Block[$i] -match '^(<img|<a\s|\*\*\[🎬|\*\*作者:|---\s*$)') { break }
        $result.Add($Block[$i])
    }

    while ($result.Count -gt 0 -and [string]::IsNullOrWhiteSpace($result[0])) {
        $result.RemoveAt(0)
    }
    while ($result.Count -gt 0 -and [string]::IsNullOrWhiteSpace($result[$result.Count - 1])) {
        $result.RemoveAt($result.Count - 1)
    }
    return ($result -join "`n")
}

$lines = Get-Content -LiteralPath $Source
$prompts = New-Object System.Collections.Generic.List[object]

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -notmatch '^###\s+(.+?)\s*$') { continue }

    $title = $Matches[1] -replace '^No\.\s*\d+:\s*', ''
    $end = $lines.Count
    for ($j = $i + 1; $j -lt $lines.Count; $j++) {
        if ($lines[$j] -match '^##\s+' -or $lines[$j] -match '^###\s+') {
            $end = $j
            break
        }
    }

    $block = @($lines[$i..($end - 1)])
    if (-not ($block -match '^####\s+📝\s+提示词\s*$')) {
        $i = $end - 1
        continue
    }

    $blockText = $block -join "`n"
    $idMatch = [regex]::Match($blockText, 'id=(\d+)')
    $sourceId = if ($idMatch.Success) { $idMatch.Groups[1].Value } else { '' }

    $prompts.Add([pscustomobject]@{
        Number = $prompts.Count + 1
        Title = $title.Trim()
        SourceId = $sourceId
        Description = Get-MarkdownSection -Block $block -Heading '📖\s+描述'
        Prompt = Get-MarkdownSection -Block $block -Heading '📝\s+提示词'
    })

    $i = $end - 1
}

if ($prompts.Count -eq 0) {
    throw 'No prompt blocks were parsed from the source README.'
}

$chunksDir = Join-Path $Output 'chunks'
New-Item -ItemType Directory -Force -Path $chunksDir | Out-Null
$chunkCount = [math]::Ceiling($prompts.Count / $ChunkSize)
$expectedChunkNames = for ($chunk = 1; $chunk -le $chunkCount; $chunk++) {
    'prompts-{0:D3}.md' -f $chunk
}
$unexpected = Get-ChildItem -LiteralPath $chunksDir -Filter 'prompts-*.md' -File |
    Where-Object { $_.Name -notin $expectedChunkNames }
if ($unexpected) {
    throw "Unexpected old corpus chunks found. Review manually: $($unexpected.Name -join ', ')"
}

$index = New-Object System.Collections.Generic.List[string]
$index.Add('# 社区提示词语料索引')
$index.Add('')
$index.Add("本地完整提示词：**$($prompts.Count)** 条。上游 CMS 显示总数为 4776，但克隆仓库只打包了这些正文。")
$index.Add('')
$index.Add('来源：[YouMind-OpenLab/awesome-seedance-2-prompts](https://github.com/YouMind-OpenLab/awesome-seedance-2-prompts)，CC BY 4.0。社区内容只用于分析和学习，复用前必须先评估质量。')
$index.Add('')
$index.Add('| 编号 | 标题 | 来源 ID | 语料块 |')
$index.Add('|---:|---|---:|---|')

for ($chunk = 0; $chunk -lt $chunkCount; $chunk++) {
    $start = $chunk * $ChunkSize
    $end = [math]::Min($start + $ChunkSize - 1, $prompts.Count - 1)
    $items = @($prompts[$start..$end])
    $fileName = 'prompts-{0:D3}.md' -f ($chunk + 1)
    $content = New-Object System.Collections.Generic.List[string]
    $content.Add("# 社区提示词 $($start + 1)-$($end + 1)")
    $content.Add('')
    $content.Add('来源：YouMind-OpenLab/awesome-seedance-2-prompts，CC BY 4.0。社区案例不是自动通过的最佳实践。')
    $content.Add('')

    foreach ($item in $items) {
        $number = '{0:D3}' -f $item.Number
        $content.Add("## $number. $($item.Title)")
        $content.Add('')
        if ($item.SourceId) {
            $content.Add("来源：https://youmind.com/zh-CN/seedance-2-0-prompts?id=$($item.SourceId)")
            $content.Add('')
        }
        if ($item.Description) {
            $content.Add('### 描述')
            $content.Add('')
            $content.Add($item.Description)
            $content.Add('')
        }
        $content.Add('### 提示词')
        $content.Add('')
        $content.Add($item.Prompt)
        $content.Add('')

        $safeTitle = $item.Title.Replace('|', '\|')
        $index.Add("| $($item.Number) | $safeTitle | $($item.SourceId) | [${fileName}](chunks/${fileName}) |")
    }

    while ($content.Count -gt 0 -and [string]::IsNullOrWhiteSpace($content[$content.Count - 1])) {
        $content.RemoveAt($content.Count - 1)
    }

    Set-Content -LiteralPath (Join-Path $chunksDir $fileName) -Value $content -Encoding utf8
}

Set-Content -LiteralPath (Join-Path $Output 'index.md') -Value $index -Encoding utf8
Write-Output "Community corpus built: $($prompts.Count) prompts in $chunkCount chunks."
