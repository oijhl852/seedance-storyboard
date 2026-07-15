param(
    [string]$Query,
    [string]$Id,
    [ValidateRange(1, 20)]
    [int]$Limit = 5,
    [ValidateSet('markdown', 'json')]
    [string]$Format = 'markdown',
    [switch]$FullContent,
    [string]$Corpus = (Join-Path $PSScriptRoot '..\references\subskills\sd-community\corpus\community-prompts-4776.csv')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Corpus)) {
    throw "Community corpus not found: $Corpus"
}
if ([string]::IsNullOrWhiteSpace($Query) -and [string]::IsNullOrWhiteSpace($Id)) {
    throw 'Provide -Query or -Id.'
}

$rows = Import-Csv -LiteralPath $Corpus

if (-not [string]::IsNullOrWhiteSpace($Id)) {
    $matches = @($rows | Where-Object { $_.id -eq $Id } | Select-Object -First 1)
} else {
    $queryText = $Query.Trim()
    $terms = @($queryText -split '\s+' | Where-Object { $_.Length -gt 0 } | Select-Object -Unique)
    $scored = foreach ($row in $rows) {
        $title = [string]$row.title
        $description = [string]$row.description
        $content = [string]$row.content
        $score = 0

        if ($title.IndexOf($queryText, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $score += 12 }
        if ($description.IndexOf($queryText, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $score += 5 }
        if ($content.IndexOf($queryText, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $score += 3 }

        foreach ($term in $terms) {
            if ($title.IndexOf($term, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $score += 6 }
            if ($description.IndexOf($term, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $score += 2 }
            if ($content.IndexOf($term, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $score += 1 }
        }

        if ($score -gt 0) {
            [pscustomobject]@{
                score = $score
                id = $row.id
                title = $title
                description = $description
                content = $content
                sourceLink = $row.sourceLink
                author = $row.author
            }
        }
    }
    $matches = @($scored | Sort-Object -Property @{Expression='score';Descending=$true}, @{Expression='id';Descending=$true} | Select-Object -First $Limit)
}

if ($matches.Count -eq 0) {
    Write-Output 'No matching community prompts found.'
    exit 0
}

$result = foreach ($item in $matches) {
    $content = [string]$item.content
    if (-not $FullContent -and $content.Length -gt 1600) {
        $content = $content.Substring(0, 1600) + "`n[内容已截断，使用 -Id $($item.id) -FullContent 查看完整提示词]"
    }
    [pscustomobject]@{
        score = $item.score
        id = $item.id
        title = $item.title
        description = $item.description
        content = $content
        sourceLink = $item.sourceLink
        author = $item.author
    }
}

if ($Format -eq 'json') {
    $result | ConvertTo-Json -Depth 4
    exit 0
}

foreach ($item in $result) {
    Write-Output "## [$($item.id)] $($item.title)"
    if ($null -ne $item.score) { Write-Output "Search score: $($item.score)" }
    if ($item.author) { Write-Output "Author: $($item.author)" }
    if ($item.sourceLink) { Write-Output "Source: $($item.sourceLink)" }
    if ($item.description) {
        Write-Output ''
        Write-Output '### Description'
        Write-Output $item.description
    }
    Write-Output ''
    Write-Output '### Prompt'
    Write-Output $item.content
    Write-Output ''
}
