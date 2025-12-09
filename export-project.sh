#!/bin/bash

# 프로젝트를 base64로 인코딩하는 스크립트
# 사용법: ./export-project.sh [project-directory] [output-file]
# 예: ./export-project.sh . project.b64
# 예: ./export-project.sh /path/to/project project.b64
# 예: ./export-project.sh  # 현재 디렉토리를 기본값으로 사용

set -e

# --help 옵션 처리
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "프로젝트 Export 스크립트"
    echo ""
    echo "사용법:"
    echo "  ./export-project.sh [project-directory] [output-file]"
    echo "  ./export-project.sh [옵션]"
    echo ""
    echo "파라미터:"
    echo "  project-directory   내보낼 프로젝트 디렉토리 경로 (기본값: 현재 디렉토리)"
    echo "  output-file         출력 파일명 (기본값: project.b64)"
    echo ""
    echo "옵션:"
    echo "  -h, --help          이 도움말을 표시하고 종료"
    echo ""
    echo "사용 예시:"
    echo "  ./export-project.sh                                    # 현재 디렉토리를 기본값으로 사용"
    echo "  ./export-project.sh . project.b64                      # 현재 디렉토리를 사용하고 출력 파일명 지정"
    echo "  ./export-project.sh /path/to/project                   # 특정 프로젝트 디렉토리 지정"
    echo "  ./export-project.sh /path/to/project custom.b64        # 프로젝트 디렉토리와 출력 파일명 모두 지정"
    echo ""
    echo "참고:"
    echo "  - 출력 파일은 스크립트를 실행한 현재 디렉토리에 생성됩니다."
    echo "  - .git, target, *.bak, *.tmp 등의 파일은 자동으로 제외됩니다."
    exit 0
fi

# 스크립트를 실행한 현재 디렉토리 저장 (출력 파일 생성 위치)
CURRENT_DIR="$(pwd)"

# 프로젝트 디렉토리 경로 (첫 번째 파라미터, 없으면 현재 디렉토리)
PROJECT_DIR="${1:-.}"
# 출력 파일 (두 번째 파라미터, 없으면 project.b64)
OUTPUT_FILE_NAME="${2:-project.b64}"

# 출력 파일 경로를 현재 디렉토리 기준으로 설정
# 사용자가 지정한 파일명/경로를 현재 디렉토리 기준으로 해석
if [[ "$OUTPUT_FILE_NAME" == /* ]]; then
    # 절대 경로인 경우, 파일명만 추출하여 현재 디렉토리에 생성
    OUTPUT_FILE="$CURRENT_DIR/$(basename "$OUTPUT_FILE_NAME")"
else
    # 상대 경로 또는 파일명만 있는 경우, 현재 디렉토리 기준으로 생성
    OUTPUT_FILE="$CURRENT_DIR/$OUTPUT_FILE_NAME"
fi

# 프로젝트 디렉토리 경로를 절대 경로로 변환
PROJECT_ROOT="$(cd "$PROJECT_DIR" && pwd)"

cd "$PROJECT_ROOT"

echo "=========================================="
echo "프로젝트 Export 스크립트"
echo "=========================================="
echo "출력 파일: $OUTPUT_FILE"
echo ""

# 임시 디렉토리 생성
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# .git을 제외한 모든 파일을 tar로 압축
echo "[1/3] 파일 수집 중..."
# macOS 확장 속성 제외를 위한 환경 변수 설정
export COPYFILE_DISABLE=1
tar --exclude='.git' \
    --exclude='target' \
    --exclude='*.bak' \
    --exclude='*.tmp' \
    --exclude='export-project.sh' \
    --exclude='export.md' \
    --exclude='import-project.sh' \
    --exclude='._*' \
    --exclude='.DS_Store' \
    --no-xattrs \
    -czf "$TEMP_DIR/project.tar.gz" \
    -C "$PROJECT_ROOT" \
    .

# tar 파일을 base64로 인코딩
echo "[2/3] Base64 인코딩 중..."
base64 -i "$TEMP_DIR/project.tar.gz" -o "$OUTPUT_FILE" 2>/dev/null || base64 < "$TEMP_DIR/project.tar.gz" > "$OUTPUT_FILE"

# 파일 크기 확인
FILE_SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
echo "[3/3] 인코딩 완료"
echo ""
echo "=========================================="
echo "Export 완료!"
echo "=========================================="
echo "출력 파일: $OUTPUT_FILE"
echo "파일 크기: $FILE_SIZE bytes ($(numfmt --to=iec-i --suffix=B $FILE_SIZE 2>/dev/null || echo "$(($FILE_SIZE / 1024))KB"))"
echo ""
echo "프로젝트 복원 방법:"
echo "  ./import-project.sh $OUTPUT_FILE"

