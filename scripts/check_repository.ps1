[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $repo

try {
    $tracked = @(git ls-files)
    if ($LASTEXITCODE -ne 0) {
        throw 'git ls-files failed'
    }
    $errors = [System.Collections.Generic.List[string]]::new()

    $required = @(
        'README.md',
        'governance/CHARACTERISTIC_SELECTION_RULES.md',
        'governance/SALE_CONFIG_v0.1.md',
        'context/current.md',
        'property/facts.md',
        'property/legal-status.md',
        'price/strategy.md',
        'listings/canonical/ru.md',
        'GITHUB_PUSH_CHECKLIST.md'
    )
    foreach ($file in $required) {
        if ($tracked -notcontains $file) {
            $errors.Add('Missing required file: ' + $file)
        }
    }

    $blockedExtensions = @(
        '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.jpg', '.jpeg',
        '.png', '.heic', '.tif', '.tiff', '.bmp', '.gif'
    )
    foreach ($file in $tracked) {
        $path = $file.Replace('\', '/')
        $extension = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
        if ($path -match '^(private|raw|secrets)/') {
            $errors.Add('Private path tracked: ' + $file)
        }
        if ($blockedExtensions -contains $extension) {
            $errors.Add('Blocked file type tracked: ' + $file)
        }
        if ($extension -eq '.webp' -and $path -notmatch '^media/published/') {
            $errors.Add('WebP outside media/published: ' + $file)
        }
    }

    $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
    $textExtensions = @('.md', '.csv', '.yml', '.yaml', '.ps1')
    foreach ($file in $tracked) {
        $extension = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
        if ($textExtensions -notcontains $extension -and $file -ne '.gitignore') {
            continue
        }
        try {
            $content = $utf8.GetString(
                [System.IO.File]::ReadAllBytes((Join-Path $repo $file))
            )
        }
        catch {
            $errors.Add('Invalid UTF-8: ' + $file)
            continue
        }
        if ($extension -eq '.md' -and $content -match '(?m)^\s*(CHR|PRICE|TIME|EFFORT|GUARD)-[A-Z0-9-]+\b') {
            $errors.Add('Internal characteristic code in Markdown: ' + $file)
        }
    }

    if ($errors.Count -gt 0) {
        $errors | ForEach-Object { Write-Host ('ERROR: ' + $_) }
        exit 1
    }
    Write-Host 'Repository checks passed.'
}
finally {
    Pop-Location
}
