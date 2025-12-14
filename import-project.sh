#!/bin/bash

# Base64로 인코딩된 프로젝트를 복원하는 스크립트
# 사용법: ./import-project.sh [input-file] [output-directory]
# 예: ./import-project.sh project.b64 /path/to/restore
# 예: ./import-project.sh project.b64  # 입력 파일명(확장자 제외)으로 디렉토리 생성

set -e

INPUT_FILE="${1:-project.b64}"

# 출력 디렉토리 결정
# 두 번째 파라미터가 있으면 사용, 없으면 입력 파일명(확장자 제외) 사용
if [ -n "$2" ]; then
    OUTPUT_DIR="$2"
else
    # 입력 파일명에서 확장자 제거하여 디렉토리명으로 사용
    INPUT_BASENAME="$(basename "$INPUT_FILE")"
    OUTPUT_DIR_NAME="${INPUT_BASENAME%.*}"
    OUTPUT_DIR="./$OUTPUT_DIR_NAME"
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "오류: 입력 파일을 찾을 수 없습니다: $INPUT_FILE"
    exit 1
fi

echo "=========================================="
echo "프로젝트 Import 스크립트"
echo "=========================================="
echo "입력 파일: $INPUT_FILE"
echo "출력 디렉토리: $OUTPUT_DIR"
echo ""

# 출력 디렉토리가 이미 존재하는지 확인
if [ -d "$OUTPUT_DIR" ]; then
    echo "경고: 출력 디렉토리가 이미 존재합니다: $OUTPUT_DIR"
    read -p "덮어쓰시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "취소되었습니다."
        exit 1
    fi
    rm -rf "$OUTPUT_DIR"
fi

# 임시 디렉토리 생성
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Base64 디코딩
echo "[1/3] Base64 디코딩 중..."
# 먼저 압축된 파일로 시도
base64 -D -i "$INPUT_FILE" -o "$TEMP_DIR/project.tar.gz" 2>/dev/null || base64 -d < "$INPUT_FILE" > "$TEMP_DIR/project.tar.gz"

# 압축 여부 확인 (gzip 헤더 확인)
if file "$TEMP_DIR/project.tar.gz" | grep -q "gzip"; then
    # 압축된 파일
    USE_COMPRESSION=true
    TAR_FILE="$TEMP_DIR/project.tar.gz"
    echo "압축된 파일로 감지됨"
else
    # 압축하지 않은 파일 (tar 파일로 다시 디코딩)
    base64 -D -i "$INPUT_FILE" -o "$TEMP_DIR/project.tar" 2>/dev/null || base64 -d < "$INPUT_FILE" > "$TEMP_DIR/project.tar"
    USE_COMPRESSION=false
    TAR_FILE="$TEMP_DIR/project.tar"
    echo "압축하지 않은 파일로 감지됨"
fi

# tar 압축 해제
echo "[2/3] 파일 압축 해제 중..."
mkdir -p "$OUTPUT_DIR"
# macOS 확장 속성 무시하고 압축 해제
if [ "$USE_COMPRESSION" = true ]; then
    tar --exclude='._*' --no-xattrs -xzf "$TAR_FILE" -C "$OUTPUT_DIR" 2>/dev/null || tar -xzf "$TAR_FILE" -C "$OUTPUT_DIR"
else
    tar --exclude='._*' --no-xattrs -xf "$TAR_FILE" -C "$OUTPUT_DIR" 2>/dev/null || tar -xf "$TAR_FILE" -C "$OUTPUT_DIR"
fi

# 복원 후 ._ 파일들 정리 (혹시 생성된 경우)
find "$OUTPUT_DIR" -name "._*" -type f -delete 2>/dev/null || true
find "$OUTPUT_DIR" -name ".DS_Store" -type f -delete 2>/dev/null || true

# 파일 수 확인
FILE_COUNT=$(find "$OUTPUT_DIR" -type f | wc -l | tr -d ' ')
echo "[3/3] 복원 완료"
echo ""
echo "=========================================="
echo "Import 완료!"
echo "=========================================="
echo "출력 디렉토리: $OUTPUT_DIR"
echo "복원된 파일 수: $FILE_COUNT"
echo ""
echo "프로젝트 위치:"
echo "  cd $OUTPUT_DIR"

