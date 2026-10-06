# Framework Laptop 13 Pro — first-boot hardware checklist (CachyOS)

Run on the real laptop after `./cachyos/install.sh`. Docker/VM cannot
validate any of this; each item needs the physical machine.

Power decisions baked into the bootstrap (see `cachyos/packages.sh`):
- `power-profiles-daemon` manages power (Framework + AMD guidance).
  No TLP (it fights PPD).
- `thermald` is installed but only enabled on Intel CPUs.
- No polling widgets, no duplicate shells/launchers/clipboard daemons.

## 0. Baseline

```bash
uname -r
cat /etc/os-release                      # expect ID=cachyos
dmidecode -s bios-version
pacman -Q linux-firmware sof-firmware
fwupdmgr get-devices
powerprofilesctl get
systemctl status power-profiles-daemon
```

Use the current rolling CachyOS kernel, not `linux-lts` for AMD Ryzen AI
300. Intel Core Ultra Series 3 Panther Lake graphics need a very recent
kernel/firmware (6.17+ was the first broadly supported baseline); check
the exact CPU/GPU and `uname -r` after install. Secure Boot should be
disabled unless CachyOS's boot chain and all required modules have been
signed/enrolled; verify after BIOS updates because firmware settings may
reset.

The bootstrap detects the CPU vendor and installs the matching iGPU stack:
Intel (`linux-firmware-intel`, `intel-media-driver`, Vulkan/oneVPL) or AMD
(`linux-firmware-amdgpu`, Mesa/Vulkan). The 13 Pro can ship with either
vendor; verify the actual GPU before debugging codecs.

Set a BIOS charge limit (60-90%) or Battery Extender in the BIOS first.

## 1. Firmware

```bash
fwupdmgr refresh --force
fwupdmgr get-updates
fwupdmgr update                          # BIOS, fingerprint, webcam, cards
fwupdmgr get-history
```

NOTE: if the 13 Pro BIOS is not on LVFS yet, update via the EFI shell
from Framework's release bundle instead (have a live USB ready; an EFI
update can wipe NVRAM boot entries).

## 2. Suspend / resume / drain

- [ ] `systemctl suspend`, resume via power button: screen, keyboard backlight normal
- [ ] Repeat with lid-close suspend
- [ ] Overnight (or 2h+) lid-closed drain: expect only a few percent
- [ ] No wake-ups in the bag (check `journalctl -b | grep -i wake`)

```bash
cat /sys/power/mem_sleep                  # expect s2idle (default)
cat /proc/acpi/wakeup
journalctl -b -p err | head -30
dmesg | grep -Ei 'suspend|nvme|mt792|iwlwifi|amdgpu|xe |i915|fprint'
```

Intel only: if the keyboard backlight / power button stays lit in suspend
or drain is ~1%/h, add kernel param `acpi_osi="!Windows 2020"`.
If the SSD disconnects on wake (Intel), try `nvme.noacpi=1` (do NOT use on AMD).

## 3. Input / display

- [ ] Touchpad: move, click, two-finger scroll, right-click
- [ ] Gestures: 4-finger horizontal = workspace, 3-finger down = close,
      3-finger up = fullscreen, 3-finger left = float (CachyOS defaults)
- [ ] Brightness keys change backlight (Noctalia OSD appears)
- [ ] Volume/mute/mic-mute/media keys work (Noctalia handles them)
- [ ] Display scaling crisp at 2x for the 2880x1920 panel
      (`hyprctl monitors`; adjust in `~/.config/hypr/config/monitors.lua`)
- [ ] Refresh rate: verify 120Hz available where expected
- [ ] External monitor over USB-C/DP: image + audio (`wpctl status`)
- [ ] Each expansion card in each slot (note: some cards drain more in
      specific slots; rear slots preferred for USB-A on some generations)

## 4. Network / camera / audio

- [ ] Wi-Fi connects, 5/6GHz band used (`iw reg get`, `nmcli dev wifi list`)
- [ ] Bluetooth pairs and reconnects after suspend (`bluetoothctl info`)
- [ ] Webcam shows MJPG image (`v4l2-ctl --list-devices`, test in
      e.g. `mpv tv:// --tv-driver=v4l2` or a browser; force MJPG if slow)
- [ ] Speakers + headphones + microphone (`wpctl status`, record a clip)
- [ ] Screen sharing picker works in a Wayland browser
      (needs `xdg-desktop-portal-hyprland`, in the CachyOS profile)

```bash
rfkill list
lspci -nn | grep -Ei 'vga|wifi|audio|nvme'
lsusb | grep -Ei '27c6|0e8d|8087|32ac'
```

Wi-Fi hardware varies by CPU/configuration. Intel BE211/AX2xx uses `iwlwifi`;
AMD Ryzen AI 300 may use MediaTek MT7925 and the 7040 series MT7922. On
MediaTek, first verify current CachyOS kernel + linux-firmware + BIOS before
considering any driver workaround; performance/suspend behavior varies by
firmware revision.

## 5. Fingerprint (if the configuration has one)

```bash
fprintd-list "$USER"
fprintd-enroll            # unenroll Windows prints first if it hangs
fprintd-verify
```

If the reader vanishes after suspend, restart fprintd
(`systemctl restart fprintd`) and report it; a sleep-hook unit may be needed.

## 6. Graphics acceleration

```bash
vainfo | grep -E 'H264|HEVC|AV1|VP9'
mpv --hwdec=auto <4k-file>     # CPU should stay low; check nvtop/amdgpu_top
```

Intel (Arc/Xe): needs `intel-media-driver`; AMD: Mesa `radeonsi`
(both resolve via the normal CachyOS stack; verify, don't pre-tune).

## 7. Desktop shell (Noctalia)

- [ ] Top bar visible on login
- [ ] Bottom dock absent (and no screen space reserved for it)
- [ ] `SUPER+Space` launcher, notifications, `SUPER+X` control center
- [ ] `SUPER+SHIFT+T` toggles dark/light; auto mode follows 07:00/20:00
- [ ] `noctalia msg color-scheme-set custom OmaBlue` applies the
      optional palette; `builtin <Tab>` lists natives
- [ ] `SUPER+SHIFT+I` focuses/launches Speedy
- [ ] `SUPER+SHIFT+W` focuses/launches Notes (1200x800 floating)
- [ ] `us,ir,de` layouts cycle with Alt+Shift
- [ ] Terminals opaque; blur tasteful, no stutter on battery

## 8. Dev environment

```bash
zsh -ic 'echo shell-ok'
nvim --headless +'lua print(vim.g.active_colorscheme)' +qa
opencode --version && opencode plugin list
mise --version
docker run --rm hello-world
gh auth status
```

OpenCode and GitHub auth are interactive (device flow) — run once:
`opencode auth login`, `gh auth login`.
