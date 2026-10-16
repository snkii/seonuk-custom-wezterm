-- WezTerm 설정 — macOS·Windows·Linux 공용 (한 파일을 그대로 복사해서 씀)
-- 정본: 볼트 영역/seonuk-agent-brain/env/터미널_환경_세팅.md
--   macOS   : ~/.config/wezterm/wezterm.lua
--   Linux   : ~/.config/wezterm/wezterm.lua
--   Windows : C:\Users\<사용자>\.wezterm.lua
local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

local is_mac = wezterm.target_triple:find 'darwin' ~= nil
local is_windows = wezterm.target_triple:find 'windows' ~= nil

-- 셸: macOS 는 zsh, 그 외는 fish (Windows 는 WSL 의 기본 셸)
if is_mac then
  config.default_prog = { '/bin/zsh', '-l' }
elseif is_windows then
  config.default_prog = { 'wsl.exe', '--cd', '~' }
else
  -- 데스크톱 메뉴로 켜면 ~/.local/bin 이 PATH 에 없을 수 있어 설치 위치를 직접 찾는다
  for _, fish in ipairs { wezterm.home_dir .. '/.local/bin/fish', '/usr/bin/fish', '/usr/local/bin/fish' } do
    if #wezterm.glob(fish) > 0 then
      config.default_prog = { fish, '-l' }
      break
    end
  end
end

-- 세션 유지: 백그라운드 mux 서버에 붙어서 실행 (세 OS 모두 지원)
-- 앱을 꺼도(macOS Cmd+Q) 탭·창·실행 중인 프로그램이 그대로 남고, 다시 켜면 이어짐
-- (창을 닫는 X·빨간 버튼 / 칸 닫기는 그 탭을 실제로 끝냄)
config.unix_domains = { { name = 'unix' } }
config.default_gui_startup_args = { 'connect', 'unix' }

-- 끌 때 "Really Quit WezTerm?" 확인 창 안 띄움 (세션은 mux 에 남으므로 확인이 필요 없음)
config.window_close_confirmation = 'NeverPrompt'

-- 창: 끄기 직전 위치·크기를 기억 (snkii/wezterm 포크 빌드의 macOS 전용 옵션)
-- 공식 빌드에는 없는 키라 config_builder 가 오류를 내므로 pcall 로 감싸 조용히 건너뛴다
if is_mac then
  pcall(function()
    config.macos_remember_window_frame = true
  end)
end

config.hide_tab_bar_if_only_one_tab = true

-- 한글 입력기 사용
config.use_ime = true

-- macOS: 왼쪽 Option 은 Alt 로 (fish 의 Alt 단축키용), 오른쪽 Option 은 특수문자 입력용
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true

-- 단축키: macOS 는 Cmd, Windows·Linux 는 같은 자리에 Ctrl+Shift
-- (Windows·Linux 에서 Ctrl 단독은 셸이 써야 해서 비워 둠. 복사/붙여넣기는 기본값 Ctrl+Shift+C/V)
local MOD = is_mac and 'SUPER' or 'CTRL|SHIFT'
local MOD_ALT = is_mac and 'SUPER|ALT' or 'CTRL|SHIFT|ALT'

config.keys = {
  -- 창 분할·이동 (iTerm2 와 같은 배치)
  { key = 'd', mods = MOD, action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  -- 아래로 분할: macOS Cmd+Shift+D, Windows·Linux Ctrl+Shift+E (Ctrl+Shift 에 Shift 를 더 붙일 수 없어서)
  is_mac and { key = 'd', mods = 'SUPER|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } }
    or { key = 'e', mods = 'CTRL|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'w', mods = MOD, action = act.CloseCurrentPane { confirm = true } },
  { key = '[', mods = MOD, action = act.ActivatePaneDirection 'Prev' },
  { key = ']', mods = MOD, action = act.ActivatePaneDirection 'Next' },
  { key = 'LeftArrow', mods = MOD_ALT, action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = MOD_ALT, action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = MOD_ALT, action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = MOD_ALT, action = act.ActivatePaneDirection 'Down' },
  -- 화면과 스크롤 기록 지우기
  {
    key = 'k',
    mods = MOD,
    action = act.Multiple {
      act.ClearScrollback 'ScrollbackAndViewport',
      act.SendKey { key = 'l', mods = 'CTRL' },
    },
  },
}

-- 줄 편집: 셸이 이해하는 제어 코드를 보내므로 ssh·tmux 너머에서도 동작
local line_editing
if is_mac then
  line_editing = {
    { key = 'Backspace', mods = 'SUPER', action = act.SendString '\x15' }, -- Cmd+Backspace: 줄 앞 전부 (^U)
    { key = 'Backspace', mods = 'ALT', action = act.SendString '\x1b\x7f' }, -- Option+Backspace: 앞 단어
    { key = 'LeftArrow', mods = 'SUPER', action = act.SendString '\x01' }, -- Cmd+←: 줄 처음 (^A)
    { key = 'RightArrow', mods = 'SUPER', action = act.SendString '\x05' }, -- Cmd+→: 줄 끝 (^E)
    { key = 'LeftArrow', mods = 'ALT', action = act.SendString '\x1bb' }, -- Option+←: 앞 단어로
    { key = 'RightArrow', mods = 'ALT', action = act.SendString '\x1bf' }, -- Option+→: 뒤 단어로
    { key = 'z', mods = 'SUPER', action = act.SendString '\x1f' }, -- Cmd+Z: 입력 되돌리기 (fish undo)
    { key = 'z', mods = 'SUPER|SHIFT', action = act.SendString '\x1b/' }, -- Cmd+Shift+Z: 다시 (fish redo)
  }
else
  -- Windows·Linux 관례: Ctrl+Backspace 앞 단어 지우기, Ctrl+←/→ 단어 이동 (Home/End 는 그대로 동작)
  line_editing = {
    { key = 'Backspace', mods = 'CTRL', action = act.SendString '\x1b\x7f' },
    { key = 'LeftArrow', mods = 'CTRL', action = act.SendString '\x1bb' },
    { key = 'RightArrow', mods = 'CTRL', action = act.SendString '\x1bf' },
  }
end
for _, k in ipairs(line_editing) do
  table.insert(config.keys, k)
end

-- 외관: Gruvbox Glass (seon.uk · 크롬 테마 snkii/seonuk-custom-chrome 와 같은 색)
local gruvbox = {
  bg0_h = '#1d2021',
  bg0 = '#282828',
  bg0_s = '#32302f',
  bg1 = '#3c3836',
  bg2 = '#504945',
  fg = '#ebdbb2',
  fg4 = '#a89984',
  gray = '#928374',
  yellow = '#fabd2f',
  orange = '#fe8019',
  blue = '#458588',
  purple = '#b16286',
}

-- 글꼴: 아이콘을 한 칸 크기로 박아 넣은 Sarasa Fixed K snkii (볼트 「글꼴」 참고)
-- Windows 는 사용자 설치 글꼴을 못 찾은 적이 있어 폴더를 직접 지정
if is_windows then
  config.font_dirs = { wezterm.home_dir .. '\\AppData\\Local\\Microsoft\\Windows\\Fonts' }
end
config.font = wezterm.font_with_fallback {
  'Sarasa Fixed K snkii',
  'Sarasa Fixed K',
  'JetBrainsMono Nerd Font Mono',
}
config.font_size = is_mac and 16 or 12.5
config.line_height = 1.08

config.color_scheme = 'GruvboxDarkHard'
config.colors = {
  foreground = gruvbox.fg,
  cursor_bg = gruvbox.yellow,
  cursor_fg = gruvbox.bg0_h,
  cursor_border = gruvbox.yellow,
  selection_bg = gruvbox.bg2,
  selection_fg = gruvbox.fg,
  split = gruvbox.bg2,
  tab_bar = {
    background = gruvbox.bg0_h,
    inactive_tab_edge = gruvbox.bg0_h,
    active_tab = { bg_color = gruvbox.bg1, fg_color = gruvbox.fg },
    inactive_tab = { bg_color = gruvbox.bg0_h, fg_color = gruvbox.gray },
    inactive_tab_hover = { bg_color = gruvbox.bg0_s, fg_color = gruvbox.fg },
    new_tab = { bg_color = gruvbox.bg0_h, fg_color = gruvbox.gray },
    new_tab_hover = { bg_color = gruvbox.bg0_s, fg_color = gruvbox.yellow },
  },
}

-- 배경: 반투명 Gruvbox 그라데이션 + 위쪽 모서리의 은은한 파랑·보라 빛.
-- macOS 는 창 뒤를 흐리게 비추고(유리 효과), Windows 는 Acrylic 으로 같은 느낌을 낸다.
config.background = {
  {
    source = { Gradient = { colors = { gruvbox.bg0_h, gruvbox.bg0 }, orientation = { Linear = { angle = -90.0 } } } },
    width = '100%',
    height = '100%',
    opacity = 0.84,
  },
  {
    source = { Gradient = { colors = { gruvbox.blue, gruvbox.bg0_h }, orientation = { Radial = { cx = 0.1, cy = 0.0, radius = 0.9 } } } },
    width = '100%',
    height = '100%',
    opacity = 0.10,
  },
  {
    source = { Gradient = { colors = { gruvbox.purple, gruvbox.bg0_h }, orientation = { Radial = { cx = 0.95, cy = 0.05, radius = 0.8 } } } },
    width = '100%',
    height = '100%',
    opacity = 0.07,
  },
}
if is_mac then
  config.macos_window_background_blur = 40
elseif is_windows then
  config.win32_system_backdrop = 'Acrylic'
end

-- 창·탭: 여백을 두고, 탭바는 창 색에 녹아들게
config.window_padding = { left = 16, right = 16, top = 12, bottom = 8 }
config.window_frame = {
  font = wezterm.font { family = 'Sarasa Fixed K snkii', weight = 'Bold' },
  font_size = is_mac and 13 or 10.5,
  active_titlebar_bg = gruvbox.bg0_h,
  inactive_titlebar_bg = gruvbox.bg0_h,
}
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 } -- 분할했을 때 안 쓰는 칸은 살짝 어둡게

-- 터미널 안 이미지: iTerm2·Sixel 은 기본 지원, Kitty 그래픽 프로토콜은 켜야 한다 (yazi·timg·일부 AI CLI 가 씀)
config.enable_kitty_graphics = true

-- 커서: 홈페이지 타자기처럼 노란 막대가 깜빡임
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 720
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

return config
