# Project Pack/Unpack

프로젝트를 base64 단일 파일로 내보내고 복원하는 도구입니다.

## Convection 규칙

* [Tool Management](~/.dotfiles/docs/tool-management-conventions.md)
* [Environment Management](~/.dotfiles/docs/environment-management-conventions.md)

### 이 프로젝트의 배포 구조

| 경로 | 역할 |
|---|---|
| `~/codespace/tools/pack/` | 소스 코드 (Source of Truth) |
| `~/.local/opt/pack/` | 배포된 실행 파일 |
| `~/.local/bin/pack` | 심볼릭 링크 → `pack.sh` |
| `~/.local/bin/unpack` | 심볼릭 링크 → `unpack.sh` |

소스를 수정한 후 `./deploy.sh`를 실행해야 변경 사항이 시스템에 반영됩니다.

## 기능

- 프로젝트 디렉토리를 base64 단일 파일로 내보내기
- base64 파일에서 프로젝트 복원
- `.git`, 빌드 산출물 등 불필요한 파일 자동 제외
- `.gitignore` 파일 기반 제외 (루트 및 서브디렉토리 포함)
- gzip 압축 옵션 지원

## 사용법

### 내보내기 (pack)

```bash
./pack.sh [옵션] [project-dir] [output-file]
```

| 옵션 | 설명 |
|---|---|
| `-h, --help` | 도움말 표시 |
| `-l, --list` | 전체 파일 목록 표시 (기본: 최대 50개) |
| `-e, --exclude PATTERN` | 추가 제외 패턴 (여러 번 사용 가능) |
| `-c, --compression LEVEL` | 압축 레벨: `none` (기본값) \| `normal` \| `max` |

- `project-dir`: 내보낼 디렉토리 (기본값: 현재 디렉토리)
- `output-file`: 출력 파일명 (기본값: `디렉토리명.b64`)

```bash
./pack.sh                                   # 현재 디렉토리 → 디렉토리명.b64
./pack.sh /path/to/project                  # 특정 디렉토리
./pack.sh /path/to/project custom.b64       # 출력 파일명 지정
./pack.sh -e 'logs' -c max /path/to/project # 추가 제외 + 최대 압축
```

### 복원하기 (unpack)

```bash
./unpack.sh [input-file] [output-directory]
```

- `input-file`: 복원할 b64 파일 (기본값: `project.b64`)
- `output-directory`: 복원 경로 (기본값: `입력파일명` 에서 확장자 제거)

```bash
./unpack.sh                                 # project.b64 → ./project/
./unpack.sh custom.b64                      # custom.b64  → ./custom/
./unpack.sh custom.b64 /path/to/restore     # 출력 디렉토리 지정
```

## 자동 제외 항목

| 항목 | 설명 |
|---|---|
| `.git`, `.gitmodules` | Git 저장소 및 서브모듈 설정 |
| `.?*` | 기타 숨김 디렉토리/파일 |
| `target`, `build`, `dist`, `out` | 빌드 산출물 |
| `node_modules`, `.gradle` | 패키지/빌드 캐시 |
| `*.bak`, `*.tmp`, `*.log` | 임시 파일 |
| `*.class`, `*.pyc`, `__pycache__` | 컴파일 산출물 |
| `._*`, `.DS_Store` | macOS 시스템 파일 |
| `.gitignore` 패턴 | 프로젝트 내 모든 `.gitignore` 적용 |
