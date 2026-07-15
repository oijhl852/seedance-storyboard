param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$errors = New-Object System.Collections.Generic.List[string]
$expectedChildren = @(
    'sd-read-script', 'sd-segment-split', 'sd-dialogue', 'sd-action',
    'sd-story-adapt', 'sd-asset-guide', 'sd-prompt', 'sd-prompt-library',
    'sd-community', 'sd-quality', 'sd-panel', 'sd-chip', 'sd-inject'
)

foreach ($name in $expectedChildren) {
    $path = Join-Path $Root "$name\SKILL.md"
    if (-not (Test-Path -LiteralPath $path)) {
        $errors.Add("Missing child skill: $name")
    }
}

$skillFiles = Get-ChildItem -Path $Root -Recurse -Filter 'SKILL.md' -File |
    Where-Object {
        $_.FullName -notmatch '\\backup\\' -and
        $_.FullName -notmatch '\\Seedance2-Storyboard-Generator\\' -and
        $_.FullName -notmatch '\\seedance-prompt-skill\\' -and
        $_.FullName -notmatch '\\awesome-seedance-2-prompts\\'
    }
$names = @{}

foreach ($file in $skillFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    $nameMatch = [regex]::Match($text, '(?m)^name:\s*["'']?([^"''\r\n]+)')
    $versionMatch = [regex]::Match($text, '(?m)^version:\s*["'']?([^"''\r\n]+)')
    $dateMatch = [regex]::Match($text, '(?m)^last_updated:\s*["'']?([^"''\r\n]+)')

    if (-not $nameMatch.Success) { $errors.Add("Missing name: $($file.FullName)") }
    if (-not $versionMatch.Success) { $errors.Add("Missing version: $($file.FullName)") }
    if (-not $dateMatch.Success) { $errors.Add("Missing last_updated: $($file.FullName)") }

    if ($nameMatch.Success) {
        $name = $nameMatch.Groups[1].Value.Trim()
        if ($names.ContainsKey($name)) {
            $errors.Add("Duplicate skill name '$name': $($names[$name]) and $($file.FullName)")
        } else {
            $names[$name] = $file.FullName
        }
    }

    if ($text -match 'ticket\s*=\s*[''\"]') {
        $errors.Add("Possible hard-coded ticket: $($file.FullName)")
    }
    if ($text -match 'userId\s*=\s*[''\"]') {
        $errors.Add("Possible hard-coded userId: $($file.FullName)")
    }
    if ($text -match 'web_fetch|git push') {
        $errors.Add("Legacy network/push instruction: $($file.FullName)")
    }
}

$corpusRoot = Join-Path $Root 'sd-community\corpus'
foreach ($required in @('index.md', 'quality-rubric.md', 'SOURCES.md')) {
    if (-not (Test-Path -LiteralPath (Join-Path $corpusRoot $required))) {
        $errors.Add("Missing community corpus file: $required")
    }
}
$fullCorpus = Join-Path $corpusRoot 'community-prompts-4776.csv'
if (-not (Test-Path -LiteralPath $fullCorpus)) {
    $errors.Add('Missing full community CSV corpus.')
} else {
    $fullRows = @(Import-Csv -LiteralPath $fullCorpus)
    if ($fullRows.Count -ne 4776) {
        $errors.Add("Unexpected full community corpus count: $($fullRows.Count)")
    }
    if (@($fullRows | Where-Object { [string]::IsNullOrWhiteSpace($_.id) -or [string]::IsNullOrWhiteSpace($_.content) }).Count -gt 0) {
        $errors.Add('Full community corpus contains missing id or content fields.')
    }
}
$corpusChunks = @(Get-ChildItem -LiteralPath (Join-Path $corpusRoot 'chunks') -Filter 'prompts-*.md' -File -ErrorAction SilentlyContinue)
if ($corpusChunks.Count -lt 1) {
    $errors.Add('No generated community corpus chunks found.')
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "Skill validation passed: $($skillFiles.Count) active SKILL.md files checked."
