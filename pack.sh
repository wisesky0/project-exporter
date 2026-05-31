#!/bin/bash
set -euo pipefail

# ── 기본값 ──────────────────────────────────────────────────────────────────
SHOW_FULL_LIST=false
COMPRESSION="none"
EXTRA_EXCLUDES=()

# ── 도움말 ──────────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
사용법: $(basename "$0") [옵션] [project-dir] [output-file]

옵션:
  -h, --help                  도움말 표시
  -l, --list                  전체 파일 목록 표시 (기본: 최대 50개)
  -e, --exclude PATTERN       추가 제외 패턴 (여러 번 사용 가능)
  -c, --compression LEVEL     압축 레벨: none (기본값) | normal | max

예시:
  $(basename "$0")                                  # 현재 디렉토리 → 디렉토리명.b64
  $(basename "$0") /path/to/project out.b64
  $(basename "$0") -e 'logs' -c max /path/to/project
EOF
}

# ── 옵션 파싱 ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)        usage; exit 0 ;;
        -l|--list)        SHOW_FULL_LIST=true; shift ;;
        -e|--exclude)     [[ -z "${2-}" ]] && { echo "오류: --exclude 에 패턴이 필요합니다."; exit 1; }
                          EXTRA_EXCLUDES+=("$2"); shift 2 ;;
        -c|--compression) [[ -z "${2-}" ]] && { echo "오류: --compression 에 레벨이 필요합니다."; exit 1; }
                          [[ "$2" =~ ^(none|normal|max)$ ]] || { echo "오류: none | normal | max 중 하나를 선택하세요."; exit 1; }
                          COMPRESSION="$2"; shift 2 ;;
        *)                break ;;
    esac
done

# ── 경로 결정 ────────────────────────────────────────────────────────────────
CURRENT_DIR="$(pwd)"
PROJECT_ROOT="$(cd "${1:-.}" && pwd)"
OUTPUT_NAME="${2:-$(basename "$PROJECT_ROOT").b64}"
[[ "$OUTPUT_NAME" == /* ]] && OUTPUT_FILE="$CURRENT_DIR/$(basename "$OUTPUT_NAME")" \
                           || OUTPUT_FILE="$CURRENT_DIR/$OUTPUT_NAME"

cd "$PROJECT_ROOT"

# ── exclude 목록 구성 ────────────────────────────────────────────────────────
build_excludes() {
    local -a ex=(--exclude='.git' --exclude='.gitmodules')

    for p in "${EXTRA_EXCLUDES[@]+"${EXTRA_EXCLUDES[@]}"}"; do ex+=(--exclude="$p"); done

    # .gitignore 파일 처리 (루트 + 서브디렉토리)
    while IFS= read -r gitignore; do
        local dir="${gitignore%/.gitignore}"
        local rel="${dir#"$PROJECT_ROOT"}"
        rel="${rel#/}"
        local base_dir="$PROJECT_ROOT${rel:+/$rel}"
        local -a exc_pats=() neg_pats=()

        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" || "$line" == \#* ]] && continue
            line="${line#"${line%%[![:space:]]*}"}"
            line="${line%"${line##*[![:space:]]}"}"
            if [[ "$line" == \!* ]]; then
                neg_pats+=("${line#!}")
            else
                exc_pats+=("$line")
            fi
        done < "$gitignore"

        local prefix="${rel:+$rel/}"
        for pat in "${exc_pats[@]+"${exc_pats[@]}"}"; do
            # negation 패턴 중 이 패턴의 glob 범위에 포함되는 것이 있는지 확인
            local has_overlap=false
            for np in "${neg_pats[@]+"${neg_pats[@]}"}"; do
                [[ "$np" == $pat ]] && has_overlap=true && break
            done

            if [[ "$has_overlap" == true ]]; then
                # glob expand 후 negation 파일 제외
                while IFS= read -r f; do
                    local neg_match=false
                    for np in "${neg_pats[@]+"${neg_pats[@]}"}"; do
                        [[ "$f" == "$np" ]] && neg_match=true && break
                    done
                    [[ "$neg_match" == true ]] && continue
                    ex+=(--exclude="./${prefix}$f")
                done < <(cd "$base_dir" && find . -maxdepth 1 -name "$pat" -not -name '.' | sed 's|^\./||')
            else
                ex+=(--exclude="./${prefix}$pat")
            fi
        done
    done < <(find "$PROJECT_ROOT" -name ".gitignore" -not -path "*/.git/*")

    printf '%s\0' "${ex[@]+"${ex[@]}"}"
}

# ── 압축 설정 ────────────────────────────────────────────────────────────────
case "$COMPRESSION" in
    max)    export GZIP=-9; USE_GZ=true ;;
    normal) export GZIP=-6; USE_GZ=true ;;
    *)      USE_GZ=false ;;
esac

# ── 실행 ─────────────────────────────────────────────────────────────────────
echo "=========================================="
echo "프로젝트 Pack"
echo "=========================================="
echo "소스:   $PROJECT_ROOT"
echo "출력:   $OUTPUT_FILE"
echo "압축:   $COMPRESSION"
[[ ${#EXTRA_EXCLUDES[@]} -gt 0 ]] && echo "추가 제외: ${EXTRA_EXCLUDES[*]}"
echo ""

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

export COPYFILE_DISABLE=1

EXCLUDES=()
while IFS= read -r -d '' item; do
    EXCLUDES+=("$item")
done < <(build_excludes)

echo "[1/3] 파일 수집 중..."
if [[ "$USE_GZ" == true ]]; then
    TAR_FILE="$TEMP_DIR/project.tar.gz"
    tar "${EXCLUDES[@]+"${EXCLUDES[@]}"}" --no-xattrs -czf "$TAR_FILE" -C "$PROJECT_ROOT" .
else
    TAR_FILE="$TEMP_DIR/project.tar"
    tar "${EXCLUDES[@]+"${EXCLUDES[@]}"}" --no-xattrs -cf  "$TAR_FILE" -C "$PROJECT_ROOT" .
fi

# ── 파일 목록 표시 ───────────────────────────────────────────────────────────
list_tar() { [[ "$USE_GZ" == true ]] && tar -tzf "$TAR_FILE" || tar -tf "$TAR_FILE"; }

FILE_COUNT=$(list_tar | wc -l | tr -d ' ')
echo ""
echo "파일 목록:"
echo "----------------------------------------"
if [[ "$SHOW_FULL_LIST" == true ]]; then
    list_tar
    echo "(총 $FILE_COUNT 개)"
else
    list_tar | head -50
    [[ "$FILE_COUNT" -gt 50 ]] \
        && echo "... (총 $FILE_COUNT 개, 상위 50개만 표시 / 전체: --list)" \
        || echo "(총 $FILE_COUNT 개)"
fi
echo "----------------------------------------"
echo ""

echo "[2/3] Base64 인코딩 중..."
base64 -i "$TAR_FILE" -o "$OUTPUT_FILE" 2>/dev/null || base64 < "$TAR_FILE" > "$OUTPUT_FILE"

FILE_SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
echo "[3/3] 완료"
echo ""
echo "=========================================="
echo "출력 파일: $OUTPUT_FILE"
echo "파일 크기: $(numfmt --to=iec-i --suffix=B "$FILE_SIZE" 2>/dev/null || echo "$(( FILE_SIZE / 1024 ))KB")"
echo ""
echo "복원 방법:"
echo "  ./unpack.sh $OUTPUT_FILE"
