<#
.SYNOPSIS
  Pushes the TowerLog source to GitHub and tags a release (which starts the
  TestFlight build workflow).

.DESCRIPTION
  1. Uses the extracted towerlog-v1.0.0\towerlog folder as the source of truth.
  2. Clones MikeGyver-SME/mikegyver-towerlog if needed (else pulls main).
  3. Copies the source in, commits, pushes.
  4. Creates and pushes the version tag -> the "Build and upload TowerLog to
     TestFlight" workflow starts automatically on the tag push.

.PARAMETER SourceDir
  The extracted source folder. Defaults to ~\Downloads\towerlog-v1.0.0\towerlog.

.PARAMETER RepoDir
  Local clone location. Defaults to source\repos\mikegyver-towerlog under your
  user profile.

.PARAMETER Tag
  Version tag to create and push, e.g. v1.0.0. The workflow runs on tags
  matching v*.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\push-towerlog.ps1
  # uses defaults, tags v1.0.0

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\push-towerlog.ps1 -Tag v1.0.1
#>
param(
    [string]$SourceDir = (Join-Path $env:USERPROFILE 'Downloads\towerlog-v1.0.0\towerlog'),
    [string]$RepoDir   = (Join-Path $env:USERPROFILE 'source\repos\mikegyver-towerlog'),
    [string]$Tag       = 'v1.0.0'
)

$ErrorActionPreference = 'Stop'
$RepoSlug = 'MikeGyver-SME/mikegyver-towerlog'

if (-not (Test-Path $SourceDir)) {
    throw "Source folder not found: $SourceDir`nExtract towerlog-v1.0.0.zip first."
}

# --- 1. Clone or update ------------------------------------------------------
if (-not (Test-Path (Join-Path $RepoDir '.git'))) {
    Write-Host "Cloning $RepoSlug ..." -ForegroundColor Cyan
    git clone "https://github.com/$RepoSlug.git" $RepoDir
}
Set-Location $RepoDir
git checkout --quiet main 2>$null
git pull --ff-only

# --- 2. Copy source in (excluding .git) --------------------------------------
Write-Host "Copying source from $SourceDir ..." -ForegroundColor Cyan
Get-ChildItem -Path $RepoDir -Force -Exclude '.git' | Remove-Item -Recurse -Force
Copy-Item -Path (Join-Path $SourceDir '*') -Destination $RepoDir -Recurse -Force

# --- 3. Commit + push (tag push starts the Actions run) ----------------------
git add -A
$status = git status --porcelain
if ($status) {
    git commit -m "TowerLog $Tag"
    Write-Host "Pushing to main ..." -ForegroundColor Cyan
    git push origin main
} else {
    Write-Host "No changes to commit." -ForegroundColor Yellow
}

if (git rev-parse --verify "refs/tags/$Tag" 2>$null) {
    Write-Host "Tag $Tag already exists locally." -ForegroundColor Yellow
} else {
    git tag $Tag
}
Write-Host "Pushing tag $Tag (this starts the TestFlight build) ..." -ForegroundColor Cyan
git push origin $Tag

Write-Host ""
Write-Host "Done. Watch the build at:" -ForegroundColor Green
Write-Host "  https://github.com/$RepoSlug/actions"
Write-Host "When it finishes, the build lands in App Store Connect -> TestFlight."
