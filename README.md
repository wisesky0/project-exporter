# Project Exporter

프로젝트를 base64로 인코딩하여 단일 파일로 내보내고, 다시 복원할 수 있는 도구입니다.

## 기능

- 프로젝트 디렉토리를 base64로 인코딩된 단일 파일로 내보내기
- base64로 인코딩된 파일에서 프로젝트 복원하기
- .git, 빌드 산출물 등 불필요한 파일 자동 제외

## 사용법

### 프로젝트 내보내기 (Export)

```bash
./export-project.sh [project-directory] [output-file]
```

**파라미터:**
- `project-directory`: 내보낼 프로젝트 디렉토리 경로 (기본값: 현재 디렉토리 `.`)
- `output-file`: 출력 파일명 (기본값: `project.b64`)

**사용 예시:**
```bash
# 현재 디렉토리를 프로젝트로 사용 (기본값)
./export-project.sh

# 현재 디렉토리를 사용하고 출력 파일명 지정
./export-project.sh . project.b64

# 특정 프로젝트 디렉토리 지정
./export-project.sh /path/to/project

# 프로젝트 디렉토리와 출력 파일명 모두 지정
./export-project.sh /path/to/project custom.b64
```

### 프로젝트 복원하기 (Import)

```bash
./import-project.sh [input-file] [output-directory]
```

**파라미터:**
- `input-file`: 복원할 base64 인코딩 파일 (기본값: `project.b64`)
- `output-directory`: 복원할 디렉토리 경로 (기본값: `./restored-project`)

**사용 예시:**
```bash
# 기본값으로 복원
./import-project.sh

# 입력 파일과 출력 디렉토리 지정
./import-project.sh project.b64 /path/to/restore
```

## 제외되는 파일/디렉토리

다음 항목들은 자동으로 제외됩니다:
- `.git` - Git 저장소
- `target` - 빌드 산출물 디렉토리
- `*.bak`, `*.tmp` - 임시 파일
- `export-project.sh`, `import-project.sh` - 스크립트 파일 자체
- `._*`, `.DS_Store` - macOS 시스템 파일

## 주의사항

- 출력 디렉토리가 이미 존재하는 경우, 덮어쓰기 여부를 확인합니다.
- 프로젝트 디렉토리 경로는 절대 경로로 변환되어 사용됩니다.
