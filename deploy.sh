#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPT_DIR="$HOME/.local/opt/pack"
BIN_DIR="$HOME/.local/bin"

echo "=========================================="
echo "Pack 도구 배포"
echo "=========================================="
echo "소스:   $SCRIPT_DIR"
echo "대상:   $OPT_DIR"
echo "링크:   $BIN_DIR"
echo ""

echo "[1/3] 디렉토리 준비 중..."
mkdir -p "$OPT_DIR" "$BIN_DIR"

echo "[2/3] 파일 복사 및 권한 설정 중..."
cp "$SCRIPT_DIR/pack.sh"   "$OPT_DIR/pack.sh"
cp "$SCRIPT_DIR/unpack.sh" "$OPT_DIR/unpack.sh"
chmod +x "$OPT_DIR/pack.sh" "$OPT_DIR/unpack.sh"

echo "[3/3] 심볼릭 링크 생성 중..."
ln -sf "$OPT_DIR/pack.sh"   "$BIN_DIR/pack"
ln -sf "$OPT_DIR/unpack.sh" "$BIN_DIR/unpack"

echo ""
echo "=========================================="
echo "배포 완료"
echo ""
echo "  pack   → $BIN_DIR/pack"
echo "  unpack → $BIN_DIR/unpack"
echo ""
echo "PATH에 $BIN_DIR 이 포함되어 있는지 확인:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
