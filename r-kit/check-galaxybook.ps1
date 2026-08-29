# ai_in_life - 갤럭시북 사전 진단
# 실행: irm https://raw.githubusercontent.com/heesue86-create/p-ai-guide/main/r-kit/check-galaxybook.ps1 | iex
# 아무것도 설치하거나 바꾸지 않습니다. 확인만 하고 결과를 바탕화면에 파일로 남깁니다.
# 주의: 이 파일은 irm|iex 로 실행되므로 UTF-8 BOM 을 넣지 않는다 (BOM = 파싱 파괴)

$ErrorActionPreference = 'Continue'
$rows = [System.Collections.ArrayList]::new()
function Add-Row($k, $v) { [void]$rows.Add([pscustomobject]@{ 항목 = $k; 결과 = "$v" }) }

Write-Host ""
Write-Host "  ai_in_life 사전 진단" -ForegroundColor Cyan
Write-Host "  ----------------------------------------"
Write-Host "  설치하거나 바꾸는 것은 없습니다. 30초면 끝납니다."
Write-Host ""

# 1. 기본 환경 -------------------------------------------------
Add-Row "PowerShell 버전" $PSVersionTable.PSVersion.ToString()
Add-Row "PS 실행 주체"    $(if ($PSVersionTable.PSVersion.Major -le 5) { "Windows PowerShell (BOM 필요)" } else { "PowerShell 7+" })
Add-Row "Windows"        (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
Add-Row "코드페이지"      (chcp 2>$null)

# 2. 스크립트 실행 정책 ----------------------------------------
$ep = @()
foreach ($s in (Get-ExecutionPolicy -List)) { $ep += "$($s.Scope)=$($s.ExecutionPolicy)" }
Add-Row "ExecutionPolicy" ($ep -join " / ")

# 3. winget ----------------------------------------------------
$wg = $null
try { $wg = (winget -v) 2>$null } catch {}
Add-Row "winget" $(if ($wg) { $wg } else { "없음 - 수동 설치 경로 필요" })

# 4. 관리자 여부 ------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] `
  [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator)
Add-Row "관리자 권한" $(if ($isAdmin) { "예" } else { "아니오" })

# 5. ★ 작업 스케줄러 실전 테스트 (그룹 소속이 아니라 실제 등록 가능 여부) ---
#    더미 태스크를 진짜로 만들어 보고 바로 지운다. 이게 유일한 정답.
$probe = "ai_in_life-probe-delete-me"
$mk = schtasks /create /TN $probe /SC ONCE /ST 23:59 /TR "cmd.exe /c exit" /F 2>&1
$made = ($LASTEXITCODE -eq 0)
if ($made) { schtasks /delete /TN $probe /F 2>&1 | Out-Null }
Add-Row "★ 스케줄러 등록" $(if ($made) { "가능 (관리자 없이 OK)" } else { "실패 - " + ($mk | Select-Object -First 1) })

# 6. 이미 깔려 있는 것 ------------------------------------------
foreach ($c in 'git','gh','node','npm','Rscript','claude') {
  $p = (Get-Command $c -ErrorAction SilentlyContinue)
  $where = if ($p) { if ($p.Source) { $p.Source } else { $p.Name + " (경로 미상)" } } else { "없음" }
  Add-Row "설치: $c" $where
}
# R 은 PATH 에 안 잡히는 설치가 흔해 실제 경로로 확인한다
$rPath = @("$env:ProgramFiles\R", "${env:ProgramFiles(x86)}\R") |
         Where-Object { $_ -and (Test-Path $_) } |
         ForEach-Object { Get-ChildItem $_ -Directory -ErrorAction SilentlyContinue } |
         Select-Object -First 1
Add-Row "설치: R" $(if ($rPath) { $rPath.FullName } else { "없음" })
$rstudio = @(
  "$env:ProgramFiles\RStudio\rstudio.exe",
  "$env:LOCALAPPDATA\Programs\RStudio\rstudio.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
Add-Row "설치: RStudio" $(if ($rstudio) { $rstudio } else { "없음" })

# 7. 문서 폴더가 OneDrive 로 리다이렉트됐는지 -------------------
$docs = [Environment]::GetFolderPath('MyDocuments')
Add-Row "문서 폴더" $docs
Add-Row "OneDrive 리다이렉트" $(if ($docs -match 'OneDrive') { "예 - 다른 위치를 써야 함" } else { "아니오" })

# 8. 디스크 여유 ------------------------------------------------
$sysDrive = (Get-PSDrive -Name ($env:SystemDrive.TrimEnd(':')) -ErrorAction SilentlyContinue)
if ($sysDrive) { Add-Row "여유 공간" ("{0:N1} GB" -f ($sysDrive.Free / 1GB)) }

# 결과 ---------------------------------------------------------
$rows | Format-List

$outFile = Join-Path ([Environment]::GetFolderPath('Desktop')) "ai_in_life-진단결과.txt"
$header  = "ai_in_life 사전 진단 / " + (Get-Date -Format "yyyy-MM-dd HH:mm") + " / " + $env:COMPUTERNAME
$body    = $rows | Format-List | Out-String
[System.IO.File]::WriteAllText($outFile, ($header + "`r`n`r`n" + $body),
  (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "  끝났습니다." -ForegroundColor Green
Write-Host "  바탕화면에 [ai_in_life-진단결과.txt] 파일이 생겼습니다."
Write-Host "  그 파일을 딸에게 보내주세요. (카톡에 끌어다 놓으면 됩니다)"
Write-Host ""
