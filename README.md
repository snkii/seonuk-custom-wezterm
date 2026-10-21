# seonuk-custom-wezterm

macOS·Windows·Linux 에서 같은 파일 하나로 쓰는 WezTerm 설정.

## 들어 있는 것

**세션 유지**
- 백그라운드 mux 서버에 붙어서 실행한다 (`unix_domains` + `default_gui_startup_args = { 'connect', 'unix' }`).
- `Cmd+Q` 로 앱을 꺼도 탭·분할·실행 중인 프로그램이 mux 서버에 그대로 남고, 다시 켜면 이어진다.
- 창 닫기 버튼과 `Cmd+W` 는 그 탭을 실제로 끝낸다. 끌 때 확인 창은 띄우지 않는다.

**창 위치·크기 기억 (macOS)**
- `macos_remember_window_frame = true`: 끄기 직전 창의 위치와 크기를 다음에 켤 때 복원한다.
- 공식 WezTerm 에는 아직 없는 옵션이라 포크 빌드가 필요하다 → [wezterm/wezterm#8239](https://github.com/wezterm/wezterm/pull/8239), 포크 [snkii/wezterm](https://github.com/snkii/wezterm/tree/macos-remember-window-frame).
- 공식 빌드에서는 이 줄을 조용히 건너뛰므로 경고 없이 나머지 설정은 그대로 동작한다.

**외관: Gruvbox Glass**
- 글꼴 Sarasa Fixed K snkii 16pt (폴백: Sarasa Fixed K, JetBrainsMono Nerd Font Mono)
- 색 GruvboxDarkHard, 노란 깜빡이는 막대 커서
- 반투명 Gruvbox 그라데이션 배경 + 위쪽 모서리의 파랑·보라 빛. macOS 는 창 뒤를 흐리게(블러 40), Windows 는 Acrylic
- 터미널 안 이미지: iTerm2·Sixel·Kitty 그래픽 프로토콜 모두 켜짐 (`wezterm imgcat 그림.png` 로 확인)
- 크롬 테마 [snkii/seonuk-custom-chrome](https://github.com/snkii/seonuk-custom-chrome) 과 같은 팔레트

**키 (macOS 는 Cmd, Windows·Linux 는 Ctrl+Shift)**

| 키 | 동작 |
|---|---|
| `Cmd+D` / `Cmd+Shift+D` | 옆으로 / 아래로 분할 (Windows·Linux 아래 분할은 `Ctrl+Shift+E`) |
| `Cmd+[` `Cmd+]`, `Cmd+Option+방향키` | 칸 이동 |
| `Cmd+W` | 칸 닫기 |
| `Cmd+K` | 화면과 스크롤 기록 지우기 |
| `Cmd+Backspace` / `Option+Backspace` | 줄 앞 전부 / 앞 단어 지우기 |
| `Cmd+←→` / `Option+←→` | 줄 처음·끝 / 단어 이동 |
| `Cmd+C` (macOS) | 선택이 있을 때만 복사. 화면이 다시 그려져 선택이 지워졌을 때 클립보드를 빈 값으로 덮어쓰지 않음 |
| `Cmd+V` (macOS) | 텍스트는 그대로 붙여넣기, 클립보드에 이미지만 있으면 `Ctrl+V` 를 보내 Claude Code 가 이미지를 붙이게 함. 칸 앞단이 ssh 면 이미지를 그 서버의 `~/.cache/wezterm-paste/` 로 올리고 경로를 붙여넣음 (ssh 키 인증 필요) |

**셸**: macOS `zsh -l`, Linux `fish -l`(없으면 기본 셸), Windows WSL.

## 설치

```bash
git clone https://github.com/snkii/seonuk-custom-wezterm.git ~/github/seonuk-custom-wezterm
mkdir -p ~/.config/wezterm
ln -sf ~/github/seonuk-custom-wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua
```

Windows 는 `wezterm.lua` 를 `C:\Users\<사용자>\.wezterm.lua` 로 복사한다.

글꼴 `Sarasa Fixed K snkii` 는 Sarasa Fixed K 에 Nerd Font 아이콘을 한 칸 크기로 넣어 직접 만든 것이다. 없으면 Sarasa Fixed K → JetBrainsMono Nerd Font Mono 순으로 대신 쓴다.

### 창 위치 기억이 필요하면 (macOS, 포크 빌드)

```bash
scripts/build-fork-macos.sh            # 소스는 ~/github/wezterm 에 받는다
```

Rust(`brew install rustup && rustup default stable`)와 Xcode Command Line Tools 가 필요하다. 빌드는 약 3분.
설치하면서 WezTerm 과 mux 서버를 끄므로 열려 있던 세션은 사라진다. PR 이 합쳐지면 공식 빌드로 돌아가면 된다.

## 조정

- 글자 크기: `config.font_size`
- 투명도: `config.background` 첫 층의 `opacity` (`1.0` 이면 불투명)
- 블러: `config.macos_window_background_blur`
