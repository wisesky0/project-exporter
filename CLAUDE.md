# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 개요

프로젝트 디렉토리를 base64 단일 파일(`.b64`)로 내보내고 복원하는 bash 도구.

## 주요 스크립트

- `pack.sh` — 프로젝트를 tar → base64 인코딩하여 `.b64` 파일 생성
- `unpack.sh` — `.b64` 파일을 base64 디코딩 → tar 해제하여 복원

## 사용법

```bash
# 내보내기
./pack.sh                                    # 현재 디렉토리 → 디렉토리명.b64
./pack.sh /path/to/project output.b64
./pack.sh -e 'logs' -c max /path/to/project  # 추가 제외 패턴 + 압축

# 복원
./unpack.sh                                  # project.b64 → ./project/
./unpack.sh custom.b64 /path/to/restore
```

## pack.sh 옵션

| 옵션 | 설명 |
|---|---|
| `-l, --list` | 전체 파일 목록 출력 (기본: 최대 50개) |
| `-e, --exclude PATTERN` | 추가 제외 패턴 (반복 사용 가능) |
| `-c, --compression LEVEL` | `none` (기본) \| `normal` \| `max` |

## 아키텍처

### pack.sh 흐름
1. `build_excludes()` — 기본 제외 목록 + `--exclude` 인자 + `.gitignore` 파싱 결합
2. `tar` + 선택적 gzip → 임시 디렉토리에 저장
3. `base64` 인코딩 → 출력 파일

### unpack.sh 흐름
1. `base64` 디코딩 → 임시 파일
2. `file` 명령으로 gzip 여부 감지 후 `tar` 해제
3. macOS 시스템 파일(`._*`, `.DS_Store`) 자동 삭제

### 자동 제외 항목
`.git`, 빌드 산출물(`target`, `build`, `dist`, `out`, `node_modules`), 임시/컴파일 파일, macOS 시스템 파일, 프로젝트 내 모든 `.gitignore` 패턴 적용.
