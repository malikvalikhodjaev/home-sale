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
        'governance/BEGINNER_ERROR_CONTROLS.md',
        'governance/PRIVACY_CONTROL.md',
        'context/current.md',
        'property/facts.md',
        'property/FACT_CONTROL.md',
        'descriptions/legal/status.md',
        'descriptions/legal/LEGAL_QUALIFICATION_GATE.md',
        'descriptions/product-offer/pricing.md',
        'descriptions/product-offer/PRICE_CHANGE_CONTROL.md',
        'market/comparables/README.md',
        'operations/open-decisions.md',
        'operations/status.md',
        'STRUCTURE.md',
        'descriptions/advertising/canonical/ru.md',
        'descriptions/advertising/PRE_PUBLICATION_GATE.md',
        'platforms/README.md',
        'platforms/PUBLICATION_CONSISTENCY_CONTROL.md',
        'portraits/README.md',
        'leads/README.md',
        'leads/QUALIFICATION_CONTROL.md',
        'deals/README.md',
        'deals/SAFETY_GATE.md',
        'goals/README.md',
        'goals/LEVEL_MODEL.md',
        'work/README.md',
        'work/TASK_CONTROL_TEMPLATE.md',
        'methods/README.md',
        'methods/registry.md',
        'roles/README.md',
        'roles/registry.md',
        'roles/AGENT_AUTHORITY_CONTROL.md',
        'localizations/uzbekistan/README.md',
        'localizations/uzbekistan/legal/sale-qualification-v0.1.md',
        'knowledge/README.md',
        'knowledge/learning-path.md',
        'knowledge/problem-map.md',
        'knowledge/beginner-mistakes.md',
        'knowledge/sources.md',
        'GITHUB_PUSH_CHECKLIST.md'
    )
    foreach ($file in $required) {
        if ($tracked -notcontains $file) {
            $errors.Add('Missing required file: ' + $file)
        }
    }

    $blockedExtensions = @(
        '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.jpg', '.jpeg',
        '.png', '.heic', '.tif', '.tiff', '.bmp', '.gif', '.zip',
        '.rar', '.7z', '.env'
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
        if ($content -match 'https?://drive\.google\.com/(drive/folders|file/d)/') {
            $errors.Add('Direct Google Drive link in tracked text: ' + $file)
        }
        if ($content -match '(?<!\d)(?:\+998|998)[\s-]?\d{2}[\s-]?\d{3}[\s-]?\d{2}[\s-]?\d{2}(?!\d)') {
            $errors.Add('Possible Uzbekistan phone number in tracked text: ' + $file)
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
