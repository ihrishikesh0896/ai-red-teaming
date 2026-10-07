#!/usr/bin/env pwsh
<#
Runs every enabled module in pipeline/ against every enabled target in
pipeline/config.yaml. To change what gets scanned, edit config.yaml (and
pipeline/.env for secrets) -- don't edit this script or the module configs.

Usage:
  ./entrypoint.ps1                   # use pipeline/config.yaml
  ./entrypoint.ps1 -ConfigFile foo.yaml
#>

param(
    [string]$ConfigFile = "config.yaml"
)

$ErrorActionPreference = "Stop"

$PipelineDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $PipelineDir

if (-not (Test-Path $ConfigFile)) {
    Write-Error "config file not found: $ConfigFile"
    exit 1
}

$EnvFile = Join-Path $PipelineDir ".env"
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $key, $value = $line -split "=", 2
            [System.Environment]::SetEnvironmentVariable($key.Trim(), $value.Trim())
        }
    }
}

$python = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python -ErrorAction SilentlyContinue }
if (-not $python) {
    Write-Error "python (or python3) is required"
    exit 1
}

& $python.Source -c "import yaml" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "PyYAML is required (pip install pyyaml)"
    exit 1
}

$resolvedJson = & $python.Source "scripts/resolve_config.py" $ConfigFile
if ($LASTEXITCODE -ne 0) {
    Write-Error "failed to resolve $ConfigFile"
    exit 1
}
$resolved = $resolvedJson | ConvertFrom-Json

if (-not $resolved.targets -or $resolved.targets.Count -eq 0) {
    Write-Error "no enabled targets in $ConfigFile"
    exit 1
}

New-Item -ItemType Directory -Force -Path "results" | Out-Null

$promptfooModule = $resolved.modules.promptfoo
if ($promptfooModule -and $promptfooModule.enabled) {
    $promptfooConfig = $promptfooModule.config
    if (-not $promptfooConfig) { $promptfooConfig = "promptfoo/promptfooconfig.yaml" }
    $extraArgs = @()
    if ($promptfooModule.extra_args) { $extraArgs = $promptfooModule.extra_args }

    foreach ($target in $resolved.targets) {
        $env:TARGET_API_URL = $target.api_url
        $env:TARGET_API_KEY = $target.api_key
        $env:TARGET_MODEL = $target.model

        Write-Host "== promptfoo redteam run :: target=$($target.id) url=$($target.api_url) model=$($target.model) =="
        npx --yes promptfoo@latest redteam run `
            -c $promptfooConfig `
            -d $target.id `
            --tag "target=$($target.id)" `
            @extraArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Error "promptfoo redteam run failed for target $($target.id)"
            exit $LASTEXITCODE
        }
    }
    Write-Host "Promptfoo run(s) complete. View results with: npx promptfoo@latest view"
} else {
    Write-Host "== promptfoo: disabled in $ConfigFile, skipping =="
}

$modelscanModule = $resolved.modules.modelscan
if ($modelscanModule -and $modelscanModule.enabled) {
    $artifactPath = $modelscanModule.artifact_path
    if (-not $artifactPath) {
        Write-Error "modules.modelscan.enabled is true but artifact_path is empty in $ConfigFile"
        exit 1
    }
    $modelscanCmd = Get-Command modelscan -ErrorAction SilentlyContinue
    if (-not $modelscanCmd) {
        Write-Error "modelscan not found. Install with: pip install modelscan"
        exit 1
    }
    Write-Host "== modelscan :: artifact=$artifactPath =="
    & $modelscanCmd.Source scan -p $artifactPath
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "modelscan reported findings -- do not promote this artifact until reviewed."
    }
} else {
    Write-Host "== modelscan: disabled in $ConfigFile, skipping =="
}

$customChecksModule = $resolved.modules.custom_checks
if ($customChecksModule -and $customChecksModule.enabled) {
    Write-Host "== custom_checks: enabled in $ConfigFile, but these are templates, not a runnable suite =="
    Write-Host "   fill in pipeline/custom_checks/*.py against your deployment first -- see custom_checks/README.md"
} else {
    Write-Host "== custom_checks: disabled in $ConfigFile, skipping =="
}
