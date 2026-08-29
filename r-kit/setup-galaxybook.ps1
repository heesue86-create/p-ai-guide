# ai_in_life - 갤럭시북(Windows) 딸깍 세팅
#
# 실행: PowerShell 에서 아래 한 줄
#   irm https://raw.githubusercontent.com/heesue86-create/p-ai-guide/main/r-kit/setup-galaxybook.ps1 | iex
#
# 하는 일: Git / GitHub CLI / R / Rtools / RStudio / Node / Claude Code 설치
#          -> 리포 clone -> RStudio 초보 세팅 -> 바탕화면 바로가기
#          -> GitHub 로그인 -> 자동 백업 설치
# 안 하는 일: 3노드 git 정체성 / Tailscale / claude-home / 0갭 자산 (이 PC 는 노드가 아님)
#
# 주의: 이 파일은 irm | iex 로 실행되므로 UTF-8 BOM 을 넣지 않는다.
#       BOM 이 있으면 선두에 \uFEFF 가 남아 첫 토큰이 명령어로 파싱되고 스크립트가 통째로 깨진다.
#       (반대로 _ops/*.ps1 은 파일로 직접 실행되므로 BOM 이 필수다. 실행 경로별로 요구가 정반대다.)
#       선두를 블록주석 <# 이 아니라 한 줄 주석으로 둔 것도 같은 이유다 - 사고가 나도 1행만 다친다.

$ErrorActionPreference = 'Continue'
$REPO   = 'https://github.com/yok1016/ai_in_life.git'
$NAME   = 'ai_in_life'
$report = [System.Collections.ArrayList]::new()
function Log($step, $state, $note='') { [void]$report.Add([pscustomobject]@{ 단계=$step; 결과=$state; 비고=$note }) }
function Head($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

# PATH 를 이번 세션에 다시 읽어들인다 (방금 설치한 프로그램을 바로 쓰려고)
function Sync-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
              [Environment]::GetEnvironmentVariable('Path','User')
  $npmGlobal = Join-Path $env:APPDATA 'npm'
  if ($env:Path -notlike "*$npmGlobal*") { $env:Path = "$env:Path;$npmGlobal" }
}

# 설치 여부 판정 - PATH 만 보면 놓친다.
# 실측(2026-08-29): R 은 설치돼 있어도 PATH 에 안 잡히는 게 기본이다.
function Test-Installed($cmd, $globs) {
  if ($cmd -and (Get-Command $cmd -ErrorAction SilentlyContinue)) { return $true }
  foreach ($g in $globs) { if (Get-Item $g -ErrorAction SilentlyContinue) { return $true } }
  return $false
}

Write-Host @"

  ai_in_life · 갤럭시북 세팅
  ---------------------------------
  이 창을 닫지 마세요. 15~30분 걸립니다.
  중간에 설치 창이 뜨면 그대로 두시면 됩니다.

"@ -ForegroundColor White

# -- 0. 사전 점검 ---------------------------------------------
Head '0. 사전 점검'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "winget 이 없습니다. Microsoft Store 에서 '앱 설치 관리자'를 먼저 설치하세요." -ForegroundColor Red
  Log '사전점검' '중단' 'winget 없음'
  $report | Format-List; return
}
Log '사전점검' 'OK' "winget $((winget --version) 2>$null)"

# 관리자 권한 - 지금 창을 다시 열지 말지 여기서 판정한다.
# 핵심: "무조건 관리자로 실행" 은 정답이 아니다.
#  · 이 계정이 관리자 그룹이면  -> 관리자로 다시 여는 게 낫다 (허용 창 1번으로 끝)
#  · 이 계정이 일반 사용자면    -> 관리자로 열면 '다른 계정' 으로 갈아타게 되고,
#    리포·GitHub 로그인·백업 스케줄이 전부 그 계정 아래 깔린다.
#    엄마는 자기 계정으로 로그인하므로 설치는 성공한 척 끝나고 자동 백업만 조용히 안 돈다.
$id      = [Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = ([Security.Principal.WindowsPrincipal]$id).IsInRole(
             [Security.Principal.WindowsBuiltInRole]::Administrator)
# 관리자 그룹 소속 여부 (승격 안 된 상태에서도 SID 로 보인다 - 'deny only' 로 들어 있음)
$ADMIN_SID = 'S-1-5-32-544'
$inAdminGroup = $false
foreach ($g in $id.Groups) {
  try { if ($g.Translate([Security.Principal.SecurityIdentifier]).Value -eq $ADMIN_SID) { $inAdminGroup = $true } } catch { }
}

if ($isAdmin) {
  Log '관리자권한' '승격됨' '허용 창 없이 진행'
} elseif ($inAdminGroup) {
  Write-Host ""
  Write-Host "  이 계정은 관리자입니다. 지금 창을 닫고 다시 여는 걸 권합니다." -ForegroundColor Yellow
  Write-Host "  시작 버튼 우클릭 -> [터미널(관리자)] 또는 [Windows PowerShell(관리자)]" -ForegroundColor Yellow
  Write-Host "  -> 허용 창이 1번만 뜨고 끝납니다. 그대로 진행하면 설치할 때마다 뜹니다." -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  그냥 진행해도 됩니다. 매번 [예] 를 누르시면 결과는 같습니다." -ForegroundColor Gray
  Write-Host ""
  Log '관리자권한' '가능-미승격' '관리자로 다시 열면 허용 창 1회. 그냥 진행해도 결과 동일'
} else {
  Write-Host ""
  Write-Host "  이 계정은 일반 사용자입니다. 설치할 때마다 허용 창이 뜹니다." -ForegroundColor Yellow
  Write-Host "  [예] 만 뜨면 누르시면 됩니다." -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  ⚠ 아이디·비밀번호를 입력하라고 나오면 창을 닫고 딸에게 알려주세요." -ForegroundColor Red
  Write-Host "    다른 계정으로 설치되면 자동 백업이 안 돕니다." -ForegroundColor Red
  Write-Host ""
  Log '관리자권한' '일반사용자' '⚠ UAC 가 계정·비밀번호를 물으면 중단 - 다른 계정 설치 = 백업 무력화'
}

# -- 1. 작업 폴더 결정 (OneDrive 회피) ------------------------
Head '1. 작업 폴더'
$docs = [Environment]::GetFolderPath('MyDocuments')
if ($docs -match 'OneDrive') {
  # OneDrive 동기화 폴더 안에 git 리포를 두면 충돌·잠금 사고가 난다.
  $root = Join-Path $env:USERPROFILE $NAME
  Write-Host "문서 폴더가 OneDrive 로 연결돼 있어 다른 위치를 씁니다." -ForegroundColor Yellow
  Log '작업폴더' '대체' "OneDrive 회피 -> $root"
} else {
  $root = Join-Path $docs $NAME
  Log '작업폴더' 'OK' $root
}
Write-Host "-> $root"

# -- 2. 프로그램 설치 -----------------------------------------
Head '2. 프로그램 설치'
$pf   = $env:ProgramFiles
$pf86 = ${env:ProgramFiles(x86)}
$apps = @(
  @{ id='Git.Git';           label='Git';        cmd='git';  globs=@("$pf\Git\cmd\git.exe"); must=$true },
  @{ id='GitHub.cli';        label='GitHub CLI'; cmd='gh';   globs=@("$pf\GitHub CLI\gh.exe"); must=$true },
  @{ id='RProject.R';        label='R';          cmd=$null;  globs=@("$pf\R\R-*\bin\R.exe"); must=$true },
  # RStudio 2022+ 는 실행 파일이 RStudio\bin\ 아래로 옮겨졌다.
  # 8/29 실측: 옛 경로만 보다가 winget 이 코드 0(성공)을 줬는데도 '실패' 로 찍혔다.
  @{ id='Posit.RStudio';     label='RStudio';    cmd=$null;  globs=@(
       "$pf\RStudio\bin\rstudio.exe","$pf\RStudio\rstudio.exe",
       "$pf86\RStudio\bin\rstudio.exe","$pf86\RStudio\rstudio.exe",
       "$env:LOCALAPPDATA\Programs\RStudio\rstudio.exe",
       "$env:LOCALAPPDATA\Programs\RStudio\bin\rstudio.exe"); must=$true },
  @{ id='OpenJS.NodeJS.LTS'; label='Node.js';    cmd='node'; globs=@("$pf\nodejs\node.exe"); must=$true },
  # Rtools 는 소스 패키지를 직접 컴파일할 때만 필요하다.
  # 강의에서 쓰는 패키지는 대개 CRAN 이 미리 만들어 둔 것으로 충분하므로 실패해도 진행한다.
  @{ id='RProject.Rtools';   label='Rtools';     cmd=$null;  globs=@("C:\rtools*\usr\bin\bash.exe"); must=$false }
)
foreach ($a in $apps) {
  if (Test-Installed $a.cmd $a.globs) { Write-Host "  $($a.label) — 이미 있음"; Log $a.label '건너뜀' '이미 설치됨'; continue }
  Write-Host "  $($a.label) 설치 중..."
  winget install --id $a.id --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
  $code = $LASTEXITCODE
  Sync-Path
  if (Test-Installed $a.cmd $a.globs) {
    Log $a.label '설치됨' $a.id
  } elseif ($code -eq 0) {
    # winget 이 성공(0)을 리턴했으면 설치는 된 것이다.
    # 못 찾은 건 이 스크립트의 경로 목록이 낡았다는 뜻이지 설치 실패가 아니다.
    # '실패' 로 찍으면 사람이 멀쩡한 걸 다시 깔러 간다 (8/29 실측 오판).
    Log $a.label '설치됨(경로 미확인)' "winget 성공 · 확인 경로 갱신 필요"
  } elseif ($a.must) {
    Log $a.label '실패' "winget $($a.id) -> 코드 $code"
    Write-Host "    실패 (나중에 수동 설치)" -ForegroundColor Yellow
  } else {
    Log $a.label '선택-보류' "winget $($a.id) -> 코드 $code · 없어도 수업 진행에는 지장 없음"
  }
}
Sync-Path

# -- 3. Claude Code -------------------------------------------
Head '3. Claude Code'
if (Get-Command npm -ErrorAction SilentlyContinue) {
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Host "  이미 있음"; Log 'Claude Code' '건너뜀' '이미 설치됨'
  } else {
    Write-Host "  설치 중..."
    npm install -g @anthropic-ai/claude-code 2>&1 | Out-Null
    Sync-Path
    if (Get-Command claude -ErrorAction SilentlyContinue) { Log 'Claude Code' '설치됨' 'npm -g' }
    else { Log 'Claude Code' '실패' 'npm 설치 실패 - Node 설치 후 재시도' }
  }
} else {
  Log 'Claude Code' '보류' 'npm 없음 - 창을 새로 열고 재실행'
  Write-Host "  npm 을 아직 못 찾습니다. 창을 새로 열고 이 스크립트를 다시 돌리세요." -ForegroundColor Yellow
}

# -- 4. 리포 가져오기 -----------------------------------------
Head '4. 리포 가져오기'
if (Test-Path (Join-Path $root '.git')) {
  Write-Host "  이미 있음 - 최신으로 갱신"
  git -C $root pull --ff-only 2>&1 | Out-Null
  Log '리포' '갱신' $root
} else {
  Write-Host "  가져오는 중... (로그인 창이 뜨면 GitHub 계정으로 로그인하세요)"
  git clone $REPO $root 2>&1 | Out-Null
  if (Test-Path (Join-Path $root '.git')) { Log '리포' 'clone 완료' $root }
  else { Log '리포' '실패' 'GitHub 로그인 또는 권한 확인 필요' }
}

# 이 폴더에서만 쓰는 git 정체성 (전역 설정은 건드리지 않는다)
if (Test-Path (Join-Path $root '.git')) {
  git -C $root config user.name  'yok1016'
  git -C $root config user.email 'yok1016@users.noreply.github.com'
  git -C $root config core.quotepath false   # 한글 경로가 \353\... 로 깨지지 않게
  Log 'git 정체성' 'OK' '이 폴더 한정 (global 미변경)'
}

# -- 5. RStudio 초보 세팅 -------------------------------------
Head '5. RStudio 세팅'
$prefDir  = Join-Path $env:APPDATA 'RStudio'
$prefFile = Join-Path $prefDir 'rstudio-prefs.json'
New-Item -ItemType Directory -Force -Path $prefDir | Out-Null
$prefs = [ordered]@{}
if (Test-Path $prefFile) {
  Copy-Item $prefFile "$prefFile.bak-$(Get-Date -f yyyyMMddHHmm)" -Force   # 기존 설정 백업
  try {
    $raw = Get-Content -LiteralPath $prefFile -Raw -Encoding UTF8
    if ($raw.Trim()) { foreach ($p in ($raw | ConvertFrom-Json).PSObject.Properties) { $prefs[$p.Name] = $p.Value } }
  } catch { }
}
$prefs['save_workspace']          = 'never'         # 종료할 때 작업내용 저장 안 물어봄
$prefs['load_workspace']          = $false          # 시작할 때 예전 것 복원 안 함 (초보 혼란 1위)
$prefs['always_save_history']     = $false
$prefs['default_encoding']        = 'UTF-8'         # 한글 깨짐 방지
$prefs['font_size_points']        = 16              # 글자 크게
$prefs['windows_terminal_shell']  = 'win-git-bash'  # Terminal 탭을 Git Bash 로 (pwd/ls 동작)
$prefs['show_line_numbers']       = $true
$prefs['highlight_selected_line'] = $true
# Windows PowerShell 5.1 의 Set-Content -Encoding UTF8 은 BOM 을 붙여 JSON 파서가 거부할 수 있다
$json = $prefs | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($prefFile, $json, (New-Object System.Text.UTF8Encoding($false)))
Log 'RStudio 설정' 'OK' 'UTF-8 / 16pt / 세션복원 해제 / Terminal=Git Bash'

# -- 6. 바탕화면 바로가기 -------------------------------------
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

# -- 7. GitHub 로그인 (대화형 1회) ----------------------------
# 자동 백업은 사람이 없는 시간에 push 한다. 그때 로그인 창이 뜨면 그대로 멈춘다.
# 그래서 지금 미리 로그인해 자격증명을 OS 에 심어 둔다. 이 계획의 단일 실패점이다.
Head '7. GitHub 로그인'
if (Get-Command gh -ErrorAction SilentlyContinue) {
  gh auth status 2>&1 | Out-Null
  if ($LASTEXITCODE -eq 0) {
    Log 'GitHub 로그인' '이미 됨' ''
  } else {
    Write-Host "  브라우저가 열립니다. GitHub 계정으로 로그인하세요." -ForegroundColor Yellow
    Write-Host "  (선택지가 나오면: GitHub.com -> HTTPS -> Y -> Login with a web browser)" -ForegroundColor Yellow
    gh auth login
    gh auth status 2>&1 | Out-Null
    Log 'GitHub 로그인' $(if ($LASTEXITCODE -eq 0) { 'OK' } else { '미완료' }) '자동 백업 push 에 필요'
  }
} else {
  Log 'GitHub 로그인' '보류' 'gh 없음'
}

# -- 8. 자동 백업 설치 ----------------------------------------
Head '8. 자동 백업 설치'
$installer = Join-Path $root '_ops\install.ps1'
if (Test-Path $installer) {
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer
  Log '자동 백업' '실행함' '_ops/install.ps1 결과를 위에서 확인'
} else {
  Log '자동 백업' '보류' '_ops/install.ps1 없음 (리포 clone 실패)'
}

# -- 9. 결과 --------------------------------------------------
Head '9. 결과'
$report | Format-List

Write-Host "`n설치된 버전" -ForegroundColor Cyan
foreach ($c in 'git','gh','node','npm','claude') {
  $v = try { (& $c --version 2>$null | Select-Object -First 1) } catch { $null }
  Write-Host ("  {0,-8} {1}" -f $c, $(if ($v) { $v } else { '없음' }))
}
$rexe = Get-Item "$pf\R\R-*\bin\R.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
Write-Host ("  {0,-8} {1}" -f 'R', $(if ($rexe) { $rexe.FullName } else { '없음' }))
$rs = Get-ChildItem "$pf\RStudio" -Recurse -Filter rstudio.exe -ErrorAction SilentlyContinue | Select-Object -First 1
Write-Host ("  {0,-8} {1}" -f 'RStudio', $(if ($rs) { $rs.FullName } else { '없음' }))

# 계정 정합 - 설치 위치와 실행 계정이 갈리면 자동 백업이 조용히 죽는다
$pathUser = if ($root -match '(?i)^[A-Z]:\\Users\\([^\\]+)') { $Matches[1] } else { $null }
if ($pathUser -and $pathUser -ne $env:USERNAME) {
  Write-Host ""
  Write-Host "  ⚠ 계정이 갈렸습니다" -ForegroundColor Red
  Write-Host "     지금 실행 계정 : $env:USERNAME" -ForegroundColor Red
  Write-Host "     설치된 폴더    : $root" -ForegroundColor Red
  Write-Host "     이대로 두면 엄마가 로그인했을 때 자동 백업이 돌지 않습니다." -ForegroundColor Red
  Write-Host "     이 화면을 캡처해서 딸에게 보내세요." -ForegroundColor Red
  Write-Host ""
}

$fail = $report | Where-Object { $_.결과 -in '실패','중단','미완료' }
if ($fail) {
  Write-Host "`n실패한 항목이 있습니다. 위 목록을 그대로 캡처해서 전달하세요." -ForegroundColor Yellow
} else {
  Write-Host @"

  끝났습니다.

  다음: 바탕화면 [R 논문 작업] 아이콘 -> RStudio 가 열립니다
        Console 에 아래를 붙여넣고 엔터 (패키지 설치, 한 번만)

    source("10-논문/02-분석코드/00-setup.R")

"@ -ForegroundColor Green
}
