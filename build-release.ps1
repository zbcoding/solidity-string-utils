# Build release script for solidity-stringutils
# Creates .zip and .tar.gz in releases/ folder

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $scriptDir

try {
    # Get version from package.json
    $packageJson = Get-Content "package.json" | ConvertFrom-Json
    $version = $packageJson.version
    $packageName = "solidity-stringutils-v$version"

    Write-Host "Building release: $packageName" -ForegroundColor Cyan

    # Create releases directory
    $releasesDir = "releases"
    if (-not (Test-Path $releasesDir)) {
        New-Item -ItemType Directory -Path $releasesDir | Out-Null
    }

    # Create temp staging directory
    $stagingDir = Join-Path $env:TEMP "solidity-stringutils-build"
    $packageDir = Join-Path $stagingDir $packageName
    if (Test-Path $stagingDir) {
        Remove-Item -Recurse -Force $stagingDir
    }
    New-Item -ItemType Directory -Path $packageDir | Out-Null

    # Files/folders to exclude (from .gitignore + dev tooling)
    $excludes = @(
        "node_modules",
        "cache",
        "abi",
        "out",
        "yarn-error.log",
        ".vscode",
        ".git",
        ".husky",
        ".github",
        "releases",
        "package-lock.json",
        "yarn.lock",
        ".npmrc",
        ".czrc",
        ".commitlintrc",
        "build-release.ps1",
        "build-release.sh"
    )

    # Copy files to staging, excluding unwanted items
    Write-Host "Copying files..." -ForegroundColor Yellow
    $items = Get-ChildItem -Force | Where-Object {
        $name = $_.Name
        -not ($excludes -contains $name)
    }

    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            Copy-Item -Recurse -Path $item.FullName -Destination (Join-Path $packageDir $item.Name)
        } else {
            Copy-Item -Path $item.FullName -Destination $packageDir
        }
    }

    # Get absolute path for releases
    $releasesFullPath = (Resolve-Path $releasesDir).Path

    # Create ZIP
    $zipPath = Join-Path $releasesFullPath "$packageName.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath }
    Write-Host "Creating ZIP..." -ForegroundColor Yellow
    Compress-Archive -Path "$packageDir\*" -DestinationPath $zipPath

    # Create TAR.GZ (use Windows tar.exe explicitly)
    $tarPath = Join-Path $releasesFullPath "$packageName.tar.gz"
    if (Test-Path $tarPath) { Remove-Item $tarPath }
    Write-Host "Creating TAR.GZ..." -ForegroundColor Yellow
    $windowsTar = "$env:SystemRoot\System32\tar.exe"
    if (Test-Path $windowsTar) {
        & $windowsTar -czf $tarPath -C $stagingDir $packageName
    } else {
        # Fallback: create tar then gzip separately
        $tarOnly = Join-Path $releasesFullPath "$packageName.tar"
        & tar -cf $tarOnly -C $stagingDir $packageName
        Compress-Archive -Path $tarOnly -DestinationPath "$tarOnly.gz" -Force
        Remove-Item $tarOnly
        Rename-Item "$tarOnly.gz" $tarPath
    }

    # Cleanup staging
    Remove-Item -Recurse -Force $stagingDir

    Write-Host ""
    Write-Host "Release built successfully!" -ForegroundColor Green
    Write-Host "Output files:" -ForegroundColor White
    Write-Host "  - releases\$packageName.zip" -ForegroundColor Gray
    Write-Host "  - releases\$packageName.tar.gz" -ForegroundColor Gray
}
finally {
    Pop-Location
}
