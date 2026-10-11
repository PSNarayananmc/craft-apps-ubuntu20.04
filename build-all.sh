#!/bin/bash
# app-pipeline.sh -- per-Craft-App build pipeline stages (run inside/outside proot as noted).
# Usage: app-pipeline.sh <stage> <args...>
#   tag <app>                 -- outside: latest stable tag of storytold/<app>
#   clone <app> <tag>         -- outside: shallow clone at tag into work/<app>
#   sys <app>                 -- outside: list -sys crates + build scripts needing C libs
#   build <app> <pkg>         -- inside : one 530s cargo chunk; prints DONE/BUILDING/FAILED
#   verify <app> <pkg>        -- inside : glibc floor, ldd missing count, 12s xvfb smoke
#   package <app> <pkg>       -- inside : repo package.sh --formats appimage (GITHUB_REPOSITORY=ours)
#   smokeapp <file.AppImage>  -- inside : extract-and-run the AppImage 12s under xvfb
#   clean <app>               -- outside: rm -rf work/<app>
set -uo pipefail
BASE=/home/z/my-project/work
STAGE="$1"; shift

case "$STAGE" in
  tag)
    app="$1"
    git ls-remote --tags "https://github.com/storytold/$app.git" 2>/dev/null \
      | awk '{print $2}' | sed 's|refs/tags/||' \
      | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1
    ;;
  clone)
    app="$1"; tag="$2"
    [ -d "$BASE/$app/.git" ] || git clone -q --depth 1 --branch "$tag" "https://github.com/storytold/$app.git" "$BASE/$app"
    git -C "$BASE/$app" describe --tags 2>/dev/null
    ;;
  sys)
    app="$1"
    grep -oE 'name = "[a-z0-9_-]+-sys[a-z0-9_-]*"' "$BASE/$app/Cargo.lock" | sort -u | sed 's/name = //;s/"//g'
    echo "-- build.rs files:"; find "$BASE/$app" -name build.rs -not -path "*/target/*" | head -5
    ;;
  build)
    app="$1"; pkg="$2"
    export CARGO_PROFILE_RELEASE_STRIP=debuginfo
    cd "$BASE/$app" || exit 9
    timeout 530 cargo build --release --locked -j "${JOBS:-2}" -p "$pkg" -p "$pkg-cli" > /tmp/build-$app.log 2>&1
    ec=$?
    if [ $ec -eq 0 ]; then echo "BUILD_DONE"
    elif [ $ec -eq 124 ]; then
      tail -1 /tmp/build-$app.log; echo "BUILDING(still in progress)"
    else echo "BUILD_FAILED($ec)"; tail -6 /tmp/build-$app.log; fi
    ;;
  verify)
    app="$1"; pkg="$2"
    bin="$BASE/$app/target/release/$pkg"
    [ -x "$bin" ] || { echo "NO_BINARY"; exit 9; }
    echo "-- GLIBC floor:"; objdump -T "$bin" | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1
    echo "-- ldd missing:"; ldd "$bin" 2>/dev/null | grep -c "not found"
    echo "-- NEEDED:"; objdump -p "$bin" | grep NEEDED | awk '{print $2}' | tr '\n' ' '; echo
    echo "-- xvfb smoke (12s):"
    ( cd "$BASE/$app" && timeout 12 xvfb-run -a -s "-screen 0 1280x800x24" "./target/release/$pkg" > /tmp/smoke-$app.log 2>&1; echo "exit=$?" )
    tail -3 /tmp/smoke-$app.log
    ;;
  package)
    app="$1"; pkg="$2"
    cd "$BASE/$app" || exit 9
    export GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-PSNarayananmc/craft-apps-ubuntu20.04}"
    timeout 400 bash packaging/linux/package.sh --skip-build --formats appimage > /tmp/pkg-$app.log 2>&1
    ec=$?
    echo "PKG_EXIT=$ec"; tail -4 /tmp/pkg-$app.log
    mkdir -p /home/z/my-project/download/apps
    cp -v dist/release/*.AppImage dist/release/*.AppImage.zsync /home/z/my-project/download/apps/ 2>/dev/null
    ( cd /home/z/my-project/download/apps && sha256sum *.AppImage | tail -20 )
    ;;
  smokeapp)
    f="$1"
    d=$(mktemp -d); cd "$d"
    APPIMAGE_EXTRACT_AND_RUN=1 "$f" --appimage-extract > /dev/null 2>&1
    bin=$(find squashfs-root -type f -executable | grep -vE 'AppRun|\.so' | head -1)
    echo "-- inner bin: $bin"; objdump -T "$bin" | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1
    ldd "$bin" 2>/dev/null | grep -c "not found"
    ( APPIMAGE_EXTRACT_AND_RUN=1 timeout 12 xvfb-run -a -s "-screen 0 1280x800x24" "$f" > /tmp/smokeai.log 2>&1; echo "exit=$?" )
    tail -2 /tmp/smokeai.log; cd /; rm -rf "$d"
    ;;
  clean)
    rm -rf "$BASE/$1"
    echo "cleaned $1"; df -h /home/z | tail -1
    ;;
esac
