#!/bin/bash
# 포크 WezTerm(창 위치 기억 옵션 포함)을 빌드해 /Applications 에 설치한다. macOS 전용.
# upstream PR wezterm/wezterm#8239 가 합쳐지면 이 스크립트 대신 공식 빌드를 쓰면 된다.
#
# 준비: Xcode Command Line Tools, Rust (brew install rustup && rustup default stable)
# 사용: scripts/build-fork-macos.sh [소스 폴더, 기본 ~/github/wezterm]
set -euo pipefail

SRC=${1:-$HOME/github/wezterm}
BRANCH=macos-remember-window-frame

if [ ! -d "$SRC/.git" ]; then
  git clone --filter=blob:none -b "$BRANCH" https://github.com/snkii/wezterm.git "$SRC"
  git -C "$SRC" remote add upstream https://github.com/wezterm/wezterm.git
fi
cd "$SRC"
git fetch origin "$BRANCH"
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"
git submodule update --init --recursive

cargo build --release -p wezterm-gui -p wezterm -p wezterm-mux-server -p strip-ansi-escapes   # 약 3분

D=dist
rm -rf "$D"; mkdir -p "$D"
cp -r assets/macos/WezTerm.app "$D/" && rm -f "$D"/WezTerm.app/*.dylib
mkdir -p "$D"/WezTerm.app/Contents/{MacOS,Resources}
cp -r assets/shell-integration/* assets/shell-completion "$D/WezTerm.app/Contents/Resources"
tic -xe wezterm -o "$D/WezTerm.app/Contents/Resources/terminfo" termwiz/data/wezterm.terminfo
for b in wezterm wezterm-mux-server wezterm-gui strip-ansi-escapes; do
  cp "target/release/$b" "$D/WezTerm.app/Contents/MacOS/"
done
codesign --force --deep --sign - "$D/WezTerm.app"

# 교체: WezTerm 과 옛 mux 서버를 끈다 (버전이 다르면 붙지 못하므로 열려 있던 세션은 사라진다)
osascript -e 'quit app "WezTerm"' || true
pkill -f wezterm-mux-server || true
if [ -d /Applications/WezTerm.app ]; then
  mv /Applications/WezTerm.app "$HOME/.Trash/WezTerm-$(date +%Y%m%d%H%M%S).app"
fi
cp -R "$D/WezTerm.app" /Applications/
echo "설치 완료: $(/Applications/WezTerm.app/Contents/MacOS/wezterm --version)"
