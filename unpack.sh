#!/bin/bash
set -euo pipefail

# ── 인자 처리 ────────────────────────────────────────────────────────────────
INPUT_FILE="${1:-project.b64}"

if [[ -n "${2-}" ]]; then
    OUTPUT_DIR="$2"
else
    INPUT_BASENAME="$(basename "$INPUT_FILE")"
    OUTPUT_DIR="./${INPUT_BASENAME%.*}"
fi

[[ -f "$INPUT_FILE" ]] || { echo "오류: 파일을 찾을 수 없습니다: $INPUT_FILE"; exit 1; }

# ── 출력 디렉토리 확인 ───────────────────────────────────────────────────────
echo "=========================================="
echo "프로젝트 Unpack"
echo "=========================================="
echo "입력:   $INPUT_FILE"
echo "출력:   $OUTPUT_DIR"
echo ""

if [[ -d "$OUTPUT_DIR" ]]; then
    echo "경고: 출력 디렉토리가 이미 존재합니다: $OUTPUT_DIR"
    read -rp "덮어쓰시겠습니까? (y/N): " -n 1
    echo
    [[ "$REPLY" =~ ^[Yy]$ ]] || { echo "취소되었습니다."; exit 1; }
    rm -rf "$OUTPUT_DIR"
fi

# ── 디코딩 및 압축 해제 ──────────────────────────────────────────────────────
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "[1/3] Base64 디코딩 중..."
DECODED="$TEMP_DIR/project.bin"
# CRLF 제거 후 디코딩 (Windows Git Bash 호환)
tr -d '\r' < "$INPUT_FILE" | base64 -d > "$DECODED" 2>/dev/null \
    || base64 -D -i "$INPUT_FILE" -o "$DECODED"

if file "$DECODED" | grep -q "gzip"; then
    USE_GZ=true
    echo "압축 형식: gzip"
else
    USE_GZ=false
    echo "압축 형식: 없음"
fi

echo "[2/3] 압축 해제 중..."
mkdir -p "$OUTPUT_DIR"
if [[ "$USE_GZ" == true ]]; then
    tar --exclude='._*' --no-xattrs -xzf "$DECODED" -C "$OUTPUT_DIR" 2>/dev/null \
        || tar -xzf "$DECODED" -C "$OUTPUT_DIR"
else
    tar --exclude='._*' --no-xattrs -xf  "$DECODED" -C "$OUTPUT_DIR" 2>/dev/null \
        || tar -xf  "$DECODED" -C "$OUTPUT_DIR"
fi

find "$OUTPUT_DIR" -name "._*"      -type f -delete 2>/dev/null || true
find "$OUTPUT_DIR" -name ".DS_Store" -type f -delete 2>/dev/null || true

FILE_COUNT=$(find "$OUTPUT_DIR" -type f | wc -l | tr -d ' ')
echo "[3/3] 완료"
echo ""
echo "=========================================="
echo "출력 디렉토리: $OUTPUT_DIR"
echo "복원된 파일 수: $FILE_COUNT"
echo ""
echo "  cd $OUTPUT_DIR"
