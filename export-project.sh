#!/bin/bash

# 프로젝트를 base64로 인코딩하는 스크립트
# 사용법: ./export-project.sh [project-directory] [output-file]
# 예: ./export-project.sh . custom.b64
# 예: ./export-project.sh /path/to/project custom.b64
# 예: ./export-project.sh  # 현재 디렉토리를 기본값으로 사용 (출력: 현재디렉토리명.b64)

set -e

# 옵션 변수 초기화
SHOW_FULL_LIST=false
ADDITIONAL_EXCLUDES=()
COMPRESSION_LEVEL="none"  # 기본값: 압축하지 않음

# 옵션 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "프로젝트 Export 스크립트"
            echo ""
            echo "사용법:"
            echo "  ./export-project.sh [옵션] [project-directory] [output-file]"
            echo ""
            echo "파라미터:"
            echo "  project-directory   내보낼 프로젝트 디렉토리 경로 (기본값: 현재 디렉토리)"
            echo "  output-file         출력 파일명 (기본값: 프로젝트 디렉토리 이름.b64)"
            echo ""
            echo "옵션:"
            echo "  -h, --help          이 도움말을 표시하고 종료"
            echo "  -l, --list          압축된 전체 파일 목록 표시 (기본값: 최대 50개만 표시)"
            echo "  -e, --exclude PATTERN   추가로 제외할 파일/디렉토리 패턴 (여러 번 사용 가능)"
            echo "  -c, --compression LEVEL   압축 레벨 선택: 'none' (압축하지 않음, 기본값), 'normal' (gzip 기본), 또는 'max' (gzip -9)"
            echo ""
            echo "사용 예시:"
            echo "  ./export-project.sh                                    # 현재 디렉토리를 기본값으로 사용 (출력: 현재디렉토리명.b64)"
            echo "  ./export-project.sh . custom.b64                       # 현재 디렉토리를 사용하고 출력 파일명 지정"
            echo "  ./export-project.sh /path/to/project                   # 특정 프로젝트 디렉토리 지정 (출력: project.b64)"
            echo "  ./export-project.sh /path/to/project custom.b64        # 프로젝트 디렉토리와 출력 파일명 모두 지정"
            echo "  ./export-project.sh --list                             # 전체 파일 목록 표시"
            echo "  ./export-project.sh -l /path/to/project                # 옵션과 함께 사용"
            echo "  ./export-project.sh -e 'node_modules' -e '*.log'        # 추가 exclude 패턴 지정"
            echo "  ./export-project.sh --exclude 'dist' /path/to/project  # exclude 옵션과 함께 사용"
            echo "  ./export-project.sh --compression none                 # 압축하지 않음 (기본값)"
            echo "  ./export-project.sh --compression normal               # 일반 압축 레벨 사용 (빠름)"
            echo "  ./export-project.sh -c max /path/to/project            # 최대 압축 레벨 사용 (작은 파일)"
            echo ""
            echo "참고:"
            echo "  - 출력 파일은 스크립트를 실행한 현재 디렉토리에 생성됩니다."
            echo "  - .git, target, *.bak, *.tmp 등의 파일은 자동으로 제외됩니다."
            echo "  - --exclude 옵션은 여러 번 사용하여 여러 패턴을 지정할 수 있습니다."
            exit 0
            ;;
        -l|--list)
            SHOW_FULL_LIST=true
            shift
            ;;
        -e|--exclude)
            if [ -z "$2" ]; then
                echo "오류: --exclude 옵션에는 패턴이 필요합니다."
                exit 1
            fi
            ADDITIONAL_EXCLUDES+=("$2")
            shift 2
            ;;
        -c|--compression)
            if [ -z "$2" ]; then
                echo "오류: --compression 옵션에는 레벨이 필요합니다 (max 또는 normal)."
                exit 1
            fi
            if [[ "$2" != "none" && "$2" != "normal" && "$2" != "max" ]]; then
                echo "오류: 압축 레벨은 'none', 'normal', 또는 'max'만 가능합니다."
                exit 1
            fi
            COMPRESSION_LEVEL="$2"
            shift 2
            ;;
        *)
            # 옵션이 아닌 경우 파라미터로 처리
            break
            ;;
    esac
done

# 스크립트를 실행한 현재 디렉토리 저장 (출력 파일 생성 위치)
CURRENT_DIR="$(pwd)"

# 프로젝트 디렉토리 경로 (옵션 처리 후 첫 번째 파라미터, 없으면 현재 디렉토리)
PROJECT_DIR="${1:-.}"

# 프로젝트 디렉토리 경로를 절대 경로로 변환
PROJECT_ROOT="$(cd "$PROJECT_DIR" && pwd)"

# 출력 파일명 결정
# 옵션 처리 후 두 번째 파라미터가 있으면 사용, 없으면 프로젝트 디렉토리 이름 사용
if [ -n "$2" ]; then
    OUTPUT_FILE_NAME="$2"
else
    # 프로젝트 디렉토리 이름을 가져와서 .b64 확장자 추가
    PROJECT_DIR_NAME="$(basename "$PROJECT_ROOT")"
    OUTPUT_FILE_NAME="${PROJECT_DIR_NAME}.b64"
fi

# 출력 파일 경로를 현재 디렉토리 기준으로 설정
# 사용자가 지정한 파일명/경로를 현재 디렉토리 기준으로 해석
if [[ "$OUTPUT_FILE_NAME" == /* ]]; then
    # 절대 경로인 경우, 파일명만 추출하여 현재 디렉토리에 생성
    OUTPUT_FILE="$CURRENT_DIR/$(basename "$OUTPUT_FILE_NAME")"
else
    # 상대 경로 또는 파일명만 있는 경우, 현재 디렉토리 기준으로 생성
    OUTPUT_FILE="$CURRENT_DIR/$OUTPUT_FILE_NAME"
fi

cd "$PROJECT_ROOT"

echo "=========================================="
echo "프로젝트 Export 스크립트"
echo "=========================================="
echo "출력 파일: $OUTPUT_FILE"
if [ ${#ADDITIONAL_EXCLUDES[@]} -gt 0 ]; then
    echo "추가 제외 패턴: ${ADDITIONAL_EXCLUDES[*]}"
fi
echo ""

# 임시 디렉토리 생성
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# .git을 제외한 모든 파일을 tar로 압축
echo "[1/3] 파일 수집 중..."
# macOS 확장 속성 제외를 위한 환경 변수 설정
export COPYFILE_DISABLE=1
# 압축 레벨 설정
if [ "$COMPRESSION_LEVEL" = "none" ]; then
    # 압축하지 않음
    echo "압축 레벨: 압축하지 않음"
    USE_COMPRESSION=false
elif [ "$COMPRESSION_LEVEL" = "max" ]; then
    # gzip 최대 압축 레벨 (레벨 9)
    export GZIP=-9
    echo "압축 레벨: 최대 (gzip -9)"
    USE_COMPRESSION=true
else
    # gzip 기본 압축 레벨 (레벨 6)
    export GZIP=-6
    echo "압축 레벨: 일반 (gzip 기본)"
    USE_COMPRESSION=true
fi

# 기본 exclude 패턴 배열
# 파일 크기를 줄이기 위해 불필요한 파일/디렉토리 제외
TAR_EXCLUDES=(
    '--exclude=./.?*'
    '--exclude=target'
    '--exclude=build'
    '--exclude=dist'
    '--exclude=out'
    '--exclude=node_modules'
    '--exclude=.gradle'
    '--exclude=.idea'
    '--exclude=.vscode'
    '--exclude=.settings'
    '--exclude=.classpath'
    '--exclude=.project'
    '--exclude=*.bak'
    '--exclude=*.tmp'
    '--exclude=*.log'
    '--exclude=*.class'
    '--exclude=*.pyc'
    '--exclude=__pycache__'
    '--exclude=.pytest_cache'
    '--exclude=.mypy_cache'
    '--exclude=export-project.sh'
    '--exclude=export.md'
    '--exclude=import-project.sh'
    '--exclude=._*'
    '--exclude=.DS_Store'
    '--exclude=allure*/'
    '--exclude=.allure'
)

# 사용자가 추가한 exclude 패턴 추가
for exclude_pattern in "${ADDITIONAL_EXCLUDES[@]}"; do
    TAR_EXCLUDES+=("--exclude=$exclude_pattern")
done

# tar 명령어 실행 (압축 여부에 따라 다르게 처리)
if [ "$USE_COMPRESSION" = true ]; then
    # 압축 사용 (gzip)
    tar "${TAR_EXCLUDES[@]}" \
        --no-xattrs \
        -czf "$TEMP_DIR/project.tar.gz" \
        -C "$PROJECT_ROOT" \
        .
else
    # 압축하지 않음
    tar "${TAR_EXCLUDES[@]}" \
        --no-xattrs \
        -cf "$TEMP_DIR/project.tar" \
        -C "$PROJECT_ROOT" \
        .
fi

# 압축된 파일 목록 표시
echo ""
echo "파일 목록:"
echo "----------------------------------------"
if [ "$USE_COMPRESSION" = true ]; then
    FILE_COUNT=$(tar -tzf "$TEMP_DIR/project.tar.gz" | wc -l | tr -d ' ')
else
    FILE_COUNT=$(tar -tf "$TEMP_DIR/project.tar" | wc -l | tr -d ' ')
fi
if [ "$USE_COMPRESSION" = true ]; then
    if [ "$SHOW_FULL_LIST" = true ]; then
        # 전체 파일 목록 표시
        tar -tzf "$TEMP_DIR/project.tar.gz"
        echo "(총 $FILE_COUNT 개 파일)"
    else
        # 최대 50개만 표시
        tar -tzf "$TEMP_DIR/project.tar.gz" | head -50
        if [ "$FILE_COUNT" -gt 50 ]; then
            echo "... (총 $FILE_COUNT 개 파일, 상위 50개만 표시)"
            echo "전체 목록을 보려면 --list 옵션을 사용하세요."
        else
            echo "(총 $FILE_COUNT 개 파일)"
        fi
    fi
else
    if [ "$SHOW_FULL_LIST" = true ]; then
        # 전체 파일 목록 표시
        tar -tf "$TEMP_DIR/project.tar"
        echo "(총 $FILE_COUNT 개 파일)"
    else
        # 최대 50개만 표시
        tar -tf "$TEMP_DIR/project.tar" | head -50
        if [ "$FILE_COUNT" -gt 50 ]; then
            echo "... (총 $FILE_COUNT 개 파일, 상위 50개만 표시)"
            echo "전체 목록을 보려면 --list 옵션을 사용하세요."
        else
            echo "(총 $FILE_COUNT 개 파일)"
        fi
    fi
fi
echo "----------------------------------------"
echo ""

# tar 파일을 base64로 인코딩
echo "[2/3] Base64 인코딩 중..."
if [ "$USE_COMPRESSION" = true ]; then
    base64 -i "$TEMP_DIR/project.tar.gz" -o "$OUTPUT_FILE" 2>/dev/null || base64 < "$TEMP_DIR/project.tar.gz" > "$OUTPUT_FILE"
else
    base64 -i "$TEMP_DIR/project.tar" -o "$OUTPUT_FILE" 2>/dev/null || base64 < "$TEMP_DIR/project.tar" > "$OUTPUT_FILE"
fi

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

