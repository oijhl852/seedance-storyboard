param(
    [string]$PackageRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$errors = New-Object System.Collections.Generic.List[string]
$expectedChildren = @(
    'sd-read-script', 'sd-segment-split', 'sd-dialogue', 'sd-action',
    'sd-story-adapt', 'sd-asset-guide', 'sd-prompt', 'sd-prompt-library',
    'sd-community', 'sd-quality', 'sd-panel', 'sd-chip', 'sd-inject'
)
$subskillRoot = Join-Path $PackageRoot 'references\subskills'

foreach ($name in $expectedChildren) {
    $path = Join-Path $subskillRoot "$name\SKILL.md"
    if (-not (Test-Path -LiteralPath $path)) {
        $errors.Add("Missing child skill: $name")
    }
}

$skillFiles = @(Get-ChildItem -Path $PackageRoot -Recurse -Filter 'SKILL.md' -File)
$names = @{}

if ($skillFiles.Count -ne ($expectedChildren.Count + 1)) {
    $errors.Add("Unexpected SKILL.md count: $($skillFiles.Count)")
}

$repositoryRoot = Split-Path -Parent $PackageRoot
if (Test-Path -LiteralPath (Join-Path $repositoryRoot '.git')) {
    foreach ($obsolete in @('backup', 'seedance-browser-injector') + $expectedChildren) {
        if (Test-Path -LiteralPath (Join-Path $repositoryRoot $obsolete)) {
            $errors.Add("Obsolete top-level path remains: $obsolete")
        }
    }
}

if (Test-Path -LiteralPath (Join-Path $PackageRoot 'docs')) {
    $errors.Add('Obsolete docs directory remains inside the package.')
}

foreach ($file in $skillFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    $nameMatch = [regex]::Match($text, '(?m)^name:\s*["'']?([^"''\r\n]+)')
    $versionMatch = [regex]::Match($text, '(?m)^\s*version:\s*["'']?([^"''\r\n]+)')
    $dateMatch = [regex]::Match($text, '(?m)^\s*last_updated:\s*["'']?([^"''\r\n]+)')

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

$corpusRoot = Join-Path $subskillRoot 'sd-community\corpus'
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

Write-Output "Skill validation passed: 1 package and $($expectedChildren.Count) subskill modules checked."
