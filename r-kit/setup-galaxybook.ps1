<#
  ai_in_life — 갤럭시북(Windows) 딸깍 세팅
  실행: PowerShell 에서 아래 한 줄
    irm https://raw.githubusercontent.com/heesue86-create/p-ai-guide/main/r-kit/setup-galaxybook.ps1 | iex

  하는 일: Git / R / RStudio / Node / Claude Code 설치 → 리포 clone
           → RStudio 초보 세팅 → 바탕화면 바로가기 → 상태 리포트
  안 하는 일: 3노드 git 정체성 · Tailscale · claude-home · 0갭 자산 (이 PC는 노드 아님)
#>

$ErrorActionPreference = 'Continue'
$REPO   = 'https://github.com/yok1016/ai_in_life.git'
$NAME   = 'ai_in_life'
$report = [System.Collections.ArrayList]::new()
function Log($step, $state, $note='') { [void]$report.Add([pscustomobject]@{ 단계=$step; 결과=$state; 비고=$note }) }
function Head($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

Write-Host @"

  ai_in_life · 갤럭시북 세팅
  ---------------------------------
  이 창을 닫지 마세요. 10~20분 걸립니다.
  중간에 설치 창이 뜨면 그대로 두시면 됩니다.

"@ -ForegroundColor White

# ── 0. 사전 점검 ──────────────────────────────────────────────
Head '0. 사전 점검'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "winget 이 없습니다. Microsoft Store 에서 '앱 설치 관리자'를 먼저 설치하세요." -ForegroundColor Red
  Log '사전점검' '중단' 'winget 없음'
  $report | Format-Table -AutoSize; return
}
Log '사전점검' 'OK' "winget $((winget --version) 2>$null)"

$isAdmin = ([Security.Principal.WindowsPrincipal] `
  [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  Write-Host "관리자 권한이 아닙니다. 설치 중 허용 창이 여러 번 뜹니다." -ForegroundColor Yellow
  Write-Host "매번 [예]를 누르시거나, 창을 닫고 PowerShell 을 '관리자 권한으로 실행' 하세요." -ForegroundColor Yellow
}
Log '관리자권한' $(if ($isAdmin) { 'OK' } else { '아님' }) $(if ($isAdmin) { '' } else { 'UAC 창 반복' })

# ── 1. 작업 폴더 결정 (OneDrive 회피) ─────────────────────────
Head '1. 작업 폴더'
$docs = [Environment]::GetFolderPath('MyDocuments')
if ($docs -match 'OneDrive') {
  # OneDrive 동기화 폴더 안에 git 리포를 두면 충돌·잠금 사고가 납니다.
  $root = Join-Path $env:USERPROFILE $NAME
  Write-Host "문서 폴더가 OneDrive 로 연결돼 있어 다른 위치를 씁니다." -ForegroundColor Yellow
  Log '작업폴더' '대체' "OneDrive 회피 → $root"
} else {
  $root = Join-Path $docs $NAME
  Log '작업폴더' 'OK' $root
}
Write-Host "→ $root"

# ── 2. 프로그램 설치 ──────────────────────────────────────────
Head '2. 프로그램 설치'
$apps = @(
  @{ id='Git.Git';            label='Git';        cmd='git' },
  @{ id='RProject.R';         label='R';          cmd='R' },
  @{ id='Posit.RStudio';      label='RStudio';    cmd=$null },
  @{ id='OpenJS.NodeJS.LTS';  label='Node.js';    cmd='node' }
)
foreach ($a in $apps) {
  $have = $false
  if ($a.cmd) { $have = [bool](Get-Command $a.cmd -ErrorAction SilentlyContinue) }
  if ($have) { Write-Host "  $($a.label) — 이미 있음"; Log $a.label '건너뜀' '이미 설치됨'; continue }

  Write-Host "  $($a.label) 설치 중..."
  winget install --id $a.id --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
  if ($LASTEXITCODE -eq 0) { Log $a.label '설치됨' $a.id }
  else { Log $a.label '실패' "winget $($a.id) → 코드 $LASTEXITCODE"; Write-Host "    실패 (나중에 수동 설치)" -ForegroundColor Yellow }
}

# 이번 세션에서 바로 쓰도록 PATH 갱신
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path','User')
# npm 전역 설치 경로는 이번 세션 PATH 에 아직 없을 수 있어 미리 붙인다
$npmGlobal = Join-Path $env:APPDATA 'npm'
if ($env:Path -notlike "*$npmGlobal*") { $env:Path = "$env:Path;$npmGlobal" }

# ── 3. Claude Code ────────────────────────────────────────────
Head '3. Claude Code'
if (Get-Command npm -ErrorAction SilentlyContinue) {
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Host "  이미 있음"; Log 'Claude Code' '건너뜀' '이미 설치됨'
  } else {
    Write-Host "  설치 중..."
    npm install -g @anthropic-ai/claude-code 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Log 'Claude Code' '설치됨' 'npm -g' }
    else { Log 'Claude Code' '실패' 'npm 설치 실패 — Node 설치 후 재시도' }
  }
} else {
  Log 'Claude Code' '보류' 'npm 없음 — 창을 새로 열고 재실행'
  Write-Host "  npm 을 아직 못 찾습니다. 창을 새로 열고 이 스크립트를 다시 돌리세요." -ForegroundColor Yellow
}

# ── 4. 리포 가져오기 ──────────────────────────────────────────
Head '4. 리포 가져오기'
if (Test-Path (Join-Path $root '.git')) {
  Write-Host "  이미 있음 — 최신으로 갱신"
  git -C $root pull --ff-only 2>&1 | Out-Null
  Log '리포' '갱신' $root
} else {
  Write-Host "  가져오는 중... (로그인 창이 뜨면 GitHub 계정으로 로그인하세요)"
  git clone $REPO $root 2>&1 | Out-Null
  if (Test-Path (Join-Path $root '.git')) { Log '리포' 'clone 완료' $root }
  else { Log '리포' '실패' 'GitHub 로그인 또는 권한 확인 필요' }
}

# 이 폴더에서만 쓰는 git 정체성 (전역 설정은 건드리지 않음)
if (Test-Path (Join-Path $root '.git')) {
  git -C $root config user.name  'yok1016'
  git -C $root config user.email 'yok1016@users.noreply.github.com'
  git -C $root config core.quotepath false
  Log 'git 정체성' 'OK' '이 폴더 한정 (global 미변경)'
}

# ── 5. RStudio 초보 세팅 ──────────────────────────────────────
Head '5. RStudio 세팅'
$prefDir  = Join-Path $env:APPDATA 'RStudio'
$prefFile = Join-Path $prefDir 'rstudio-prefs.json'
New-Item -ItemType Directory -Force -Path $prefDir | Out-Null
if (Test-Path $prefFile) {
  Copy-Item $prefFile "$prefFile.bak-$(Get-Date -f yyyyMMddHHmm)" -Force   # 기존 설정 백업
}
$prefs = [ordered]@{
  save_workspace         = 'never'      # 종료할 때 작업내용 저장 안 물어봄
  load_workspace         = $false       # 시작할 때 예전 것 복원 안 함 (초보 혼란 1위)
  always_save_history    = $false
  default_encoding       = 'UTF-8'      # 한글 깨짐 방지
  font_size_points       = 16           # 글자 크게
  windows_terminal_shell = 'win-git-bash'  # Terminal 탭을 Git Bash 로 (pwd/ls 동작)
  show_line_numbers      = $true
  highlight_selected_line= $true
}
# Windows PowerShell 5.1 의 Set-Content -Encoding UTF8 은 BOM 을 붙여 JSON 파서가 거부할 수 있음
$json = $prefs | ConvertTo-Json
[System.IO.File]::WriteAllText($prefFile, $json, (New-Object System.Text.UTF8Encoding($false)))
Log 'RStudio 설정' 'OK' 'UTF-8 / 16pt / 세션복원 해제 / Terminal=Git Bash'

# ── 6. 바탕화면 바로가기 ──────────────────────────────────────
Head '6. 바탕화면 바로가기'
$rproj = Join-Path $root "$NAME.Rproj"
if (Test-Path $rproj) {
  $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'R 논문 작업.lnk'
  $sc  = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
  $sc.TargetPath       = $rproj
  $sc.WorkingDirectory = $root
  $sc.Description      = 'R 할 때는 항상 이 아이콘으로 시작'
  $sc.Save()
  Log '바로가기' 'OK' 'R 논문 작업'
} else {
  Log '바로가기' '보류' '.Rproj 없음 (리포 clone 실패)'
}

# ── 7. 결과 ───────────────────────────────────────────────────
Head '7. 결과'
$report | Format-Table -AutoSize

Write-Host "`n설치된 버전" -ForegroundColor Cyan
foreach ($c in 'git','node','npm','claude') {
  $v = try { (& $c --version 2>$null | Select-Object -First 1) } catch { $null }
  Write-Host ("  {0,-8} {1}" -f $c, $(if ($v) { $v } else { '없음' }))
}

$fail = $report | Where-Object { $_.결과 -in '실패','중단' }
if ($fail) {
  Write-Host "`n실패한 항목이 있습니다. 위 표를 그대로 캡처해서 전달하세요." -ForegroundColor Yellow
} else {
  Write-Host @"

  끝났습니다.

  다음: 바탕화면 [R 논문 작업] 아이콘 → RStudio 가 열립니다
        Console 에 아래를 붙여넣고 엔터 (패키지 설치, 한 번만)

    source("10-논문/02-분석코드/00-setup.R")

"@ -ForegroundColor Green
}
