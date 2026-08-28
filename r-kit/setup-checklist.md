# 엄마 PC 세팅 체크리스트 (딸 실행용)

전제: 엄마는 웹 브라우저로만 Claude를 씀. 터미널·GitHub Desktop·Claude Code 설치 안 함.
소요: 40~60분.

---

## A. 브라우저 (10분)

- [ ] 크롬(또는 엣지) 기본 브라우저로 지정
- [ ] `claude.ai` 로그인 → **로그인 유지 체크**
- [ ] 북마크바 표시(`Ctrl+Shift+B`) → `claude.ai` 첫 칸에 고정, 이름 `R 공부방`
- [ ] 시작페이지를 `claude.ai`로 지정
- [ ] 브라우저 글자 크기 → 설정에서 **중간(Medium) → 크게(Large)**

## B. Claude Project 생성 (10분)

- [ ] claude.ai → 좌측 `Projects` → 새 프로젝트, 이름 `R 공부방`
- [ ] 프로젝트 지침에 `r-kit/project-instructions.md` 의 `---` 아래 전체 붙여넣기
- [ ] 프로젝트 지식(Knowledge)에 업로드:
      - 강의계획서 PDF
      - 1주차 강의자료
      - (이후 매주 강의자료를 엄마가 여기 올리도록 알려주기)
- [ ] 테스트 대화 1건: "R이랑 RStudio가 뭐가 다른지 알려줘" → 답변 톤 확인
- [ ] 대화창을 **북마크에 따로 고정** — 엄마가 프로젝트를 못 찾는 사고 방지

## C. R + RStudio (15분)

- [ ] R 설치 — `cran.r-project.org` → Download R for Windows → base
- [ ] RStudio 설치 — `posit.co/download/rstudio-desktop`
- [ ] RStudio 실행 후 `Tools → Global Options`
      - [ ] `Code → Saving → Default text encoding` = **UTF-8** (한글 깨짐 방지)
      - [ ] `Appearance → Editor font size` = **16pt 이상**, Zoom 110~125%
      - [ ] `General → Restore .RData on startup` **해제** (초보 혼란 원인)
- [ ] 콘솔에 `install.packages("tidyverse")` 1회 실행해서 설치 경로 문제 미리 확인

## D. 폴더 + .Rproj (10분) ← 여기가 제일 중요

- [ ] `문서\부동산논문\` 아래 4칸 생성
      - `01-원본데이터`
      - `02-분석코드`
      - `03-결과`
      - `04-논문`
- [ ] RStudio → `File → New Project → Existing Directory` → `부동산논문` 선택
      → `부동산논문.Rproj` 생성됨
- [ ] 바탕화면에 **`부동산논문.Rproj` 바로가기** (R이나 RStudio 아이콘 말고 이것)
- [ ] 엄마한테 한 문장으로: **"R 할 때는 무조건 이 아이콘으로 시작"**

> 왜: 초보 R 에러 1위가 "파일을 못 찾겠다". `.Rproj`로 열면 작업 폴더가 자동으로
> 맞춰져서 이 계열 에러가 거의 사라짐.

## E. GitHub + Copilot (10분)

- [ ] GitHub 계정 생성 (엄마 이메일)
- [ ] `education.github.com/pack` → **Student Developer Pack** 신청
      - 재학증명서 또는 학교 이메일 필요 / 승인까지 며칠 걸릴 수 있음
      - 승인되면 Copilot Pro 무료 → 강의 환경과 동일해짐
- [ ] 승인 대기 중에는 Copilot 없이 진행해도 무방 (Claude로 커버)
- [ ] 강의에서 말한 "GitHub 설치"가 둘 중 무엇인지 1주차에 확인
      - ① `devtools::install_github("...")` = 패키지 받기, 계정 불필요
      - ② GitHub 계정 만들기 = Copilot용
      → **확인 후 이 줄 갱신할 것**

## F. 마지막 (5분)

- [ ] 엄마 폰·PC 즐겨찾기에 `heesue86-create.github.io/p-ai-guide/r.html` 추가
- [ ] 화면 캡처 방법 1회 시연 (`Win+Shift+S`) — 에러를 그림으로 보내는 법
- [ ] 카톡으로 위 링크 전송

---

## 안 하는 것 (지금은)

| 항목 | 이유 |
|---|---|
| Claude Code (웹/로컬) | GitHub 저장소 연결이 전제. 논문 파일 10개 넘어간 뒤 2단계 |
| git / 커밋 | 지금 얹으면 R 배울 여력이 사라짐 |
| 클라우드 데이터 업로드 | 로컬 RStudio에서 돌리고 결과만 Claude에 붙여넣는 게 빠름 |
| 원격 데스크톱 | 필요해지면 그때 |
