# SP Football Life 2026 (PES 2021) on Linux

**Play PES 2021 with the SP Football Life 2026 patch on Linux.** One script, no sudo, controller working, both updates applied.

**Read this in other languages:** [Português do Brasil](README.pt-BR.md) · [Español](README.es.md)

Tested on Ubuntu based systems and built so it also works on **Bazzite, SteamOS and the Steam Deck**, where you cannot install anything system wide.

I got SP Football Life 2026 running on Linux and it plays great, so I wrote down everything I did.

If you know this game as PES 2021, eFootball PES 2021 Season Update, or just Football Life, you are in the right place. SP Football Life is the standalone SmokePatch release built on PES 2021, and this guide covers running it on Linux with Proton.

PES 2021 is not sold anymore. The only reason this game is still alive is the SmokePatch team, who keep shipping updated squads, kits and stadiums every season. All the credit for the game and the patches goes to them. This repo is only the Linux part.

If you play on Windows you do not need any of this. Just grab the game from the official page and install it. This is for people on Linux who want to play without fighting Wine for a whole afternoon.

## Does it actually work

Yes. Full 1080p, controller working, Sider loading all the mods, both updates applied and the game reporting version 2.2.0. I played a full match before writing this.

![Main menu](screenshots/main-menu.png)

Here is the machine I tested on:

| | |
|---|---|
| OS | Zorin OS 18.1 (Ubuntu 24.04 base) |
| Kernel | 7.0.0-28-generic |
| Desktop | GNOME on X11 |
| CPU | AMD Ryzen 9 3900X, 24 threads |
| RAM | 62 GB |
| GPU | NVIDIA RTX 4070 Ti, driver 580.173.02 |
| Vulkan | 1.4.312 |
| Proton | GE-Proton11-3 |
| Controller | Xbox controller over USB |

It should work on any distro with a working Vulkan driver. Everything installs inside your home folder, so it also works on immutable systems like Bazzite and SteamOS. No sudo anywhere.

### Wayland

Proton runs the game through XWayland, so it works on a Wayland session. If the window misbehaves or fullscreen breaks, log out and pick the X11 session (`Ubuntu on Xorg`) at the login screen.

Do not reach for the Wine virtual desktop as a workaround, it breaks Vulkan and the game crashes instead of just misbehaving.

## What you need to download

Get everything from the official SmokePatch page. Do not download it from random mirrors:

**https://www.pessmokepatch.com/2025/10/spfl26.html**

You need three things:

1. **The base game** (`SPFL26_setup.exe` plus the `Data` folder and the `.D01` file)
2. **Update 2.0** (`SPFL26_200.exe`)
3. **Update 2.2** (`SPFL26_220.exe`)

The updates matter. The base download is version 1.0 and you are missing a lot of squad and transfer fixes without them. Install 2.0 first, then 2.2. The 2.2 file says "for v2" because it expects 2.0 to already be there.

### Tip: use JDownloader

The download links are spread across file hosts with waiting timers, and the base game is about 29 GB split into parts. JDownloader handles the queue, the timers and the retries by itself. Just copy the links and let it run overnight.

```bash
flatpak install flathub org.jdownloader.JDownloader
```

Keep every part in the same folder. The installer needs the `Data` folder sitting next to `SPFL26_setup.exe`.

### Unpack the parts first

The base game arrives as split `.rar` archives (`SPFL26.part01.rar` and friends). Extract them before running the installer, otherwise there is no `SPFL26_setup.exe` for the script to find.

```bash
unar SPFL26.part01.rar        # or: 7z x SPFL26.part01.rar
```

Extract them into a single folder, so that `SPFL26_setup.exe`, the `Data` folder and the `.D01` file end up side by side.

## Quick install

Clone this repo and point the script at your downloads folder:

```bash
git clone https://github.com/agentkyo/spfl26-pes2021-linux.git
cd spfl26-pes2021-linux
./install.sh --source ~/Downloads
```

Want to see what it would do without touching anything?

```bash
./install.sh --check --source ~/Downloads
```

The script checks your system first and tells you what is missing before it downloads a single byte. It looks at disk space, your Vulkan driver, whether Steam is around, and whether you already have GE-Proton or an old install sitting there.

```
==> Checking your system
  distro : Zorin OS 18.1
  kernel : 7.0.0-28-generic
  session: x11

  [ ok ] running as user, no root needed
  [ ok ] curl, tar, python3 and find are available
  [ ok ] 116 GB free in $HOME
  [ ok ] GPU: NVIDIA Corporation AD104 [GeForce RTX 4070 Ti]
  [ ok ] Vulkan driver: 580.173.02
  [ ok ] i386 multiarch enabled (needed by the 32 bit installers)
  [ ok ] session: x11
  [ ok ] an archive extractor is available
  [ ok ] Steam data found at /home/user/.steam/root
  [ ok ] GE-Proton11-3 already installed
  [ ok ] patch 2.0: /home/user/Downloads/SPFL26_200/SPFL26_200.exe
  [ ok ] patch 2.2: /home/user/Downloads/SPFL26_220/SPFL26_220.exe

  [ ok ] discovery passed
```

Then it downloads GE-Proton11-3, builds the prefix, runs the game setup, applies both updates and drops two shortcuts on your desktop.

Three windows will pop up during the install and you have to click through them. That part cannot be automated, the SmokePatch installers are GUI only.

### The one thing you must get right

Every installer asks where to put the files. All three of them, the base game and both updates, need the **exact same folder**. Which folder is up to you, as long as it is the same one three times.

Two paths work:

```
C:\Games\SPFL26
C:\Program Files (x86)\SP Football Life 2026
```

The second one is what the base installer suggests, so keeping the default is fine. The script checks both places afterwards and links them together, so the launcher finds the game either way.

What breaks the install is mixing them. The updates patch files that are already there, so pointing them at an empty folder gets you nothing and no error either. If an installer offers to create a folder that should already exist, say **No** and fix the path, because that prompt means you are in the wrong place.

Do not use a `Z:\` path. `Z:` maps your whole Linux filesystem and Sider gets weird with it.

### Install order

1. Base game
2. Update 2.0
3. Update 2.2

Check `dataSP/version.txt` inside the game folder after each one. It should read `1.0.0`, then `2.0.0`, then `2.2.0`.

If a window ever says "not responding", click Wait. The installer even says so on screen, it stops answering the window manager while it copies. Give it time. If it sits on the same file and the same percentage for several minutes, then it really is stuck. Close it and run that installer again.

## The shortcut

The script creates one, **SP Football Life 2026**, on your desktop and in your application menu.

It used to create a second one for `Settings.exe`, the app that sets resolution and screen mode. That app does not run under Proton, so the shortcut is gone. See below for the details.

![Shortcuts](screenshots/shortcuts.png)

### Settings.exe does not work, and the game is fine without it

`Settings.exe` is a .NET app that wants .NET Framework 4.8. Proton ships Wine Mono instead, which is close but not close enough here. It loads, then dies with a page fault inside `Settings_b.dll`:

```
mscoree:parse_supported_runtime sku="NETFramework,Version=v4.8" not implemented
wine: Unhandled page fault on read access to 00000004
err:mscoree:expect_no_runtimes Process exited with a Mono runtime loaded
```

Same crash on every machine tried, at the same offsets, so this is not a driver or a hardware thing. There is no second config tool in the game either, just `Settings.exe` and its DLL.

The game runs at a sane default and full matches play through without ever opening it. That is why the shortcut was dropped: a launcher that only ever crashes is worse than no launcher.

The script still writes `~/Games/spfl26-settings.sh` if you want to try. Installing .NET Framework 4.8 into the prefix with winetricks might fix it. That was not tested here, and it is a heavy dependency for a resolution picker, so it is left as an idea rather than a step. If you get it working, a PR would be welcome.

## Controller

This is the part that cost me the most time, so read it.

**Close Steam before you play.** Steam Input takes exclusive control of your gamepad. When it does, the game still sees the controller in the device list but never receives a single button press. It looks like the controller is broken. It is not, Steam is just eating the input.

The launcher warns you if Steam is open. If your controller stops working out of nowhere, that is the first thing to check.

If you want to keep Steam open, go to Settings, Controller, and turn off Xbox controller support there.

## If something breaks

These are the errors I hit and what fixed them.

**The script says `FL_2026.exe not found` while the installer is still copying**

`SPFL26_setup.exe` is a bootstrapper. It unpacks the real installer, starts it, and exits straight away. Anything waiting on that first process thinks the install finished after a few seconds and checks for a game that has not copied a single file yet.

Wait on the prefix instead of the process:

```bash
WINEPREFIX="$PREFIX/pfx" wineserver -w
```

That returns when everything inside the prefix is done, bootstrapper and installer both. The script does this now, so if you see this error you are on an old copy.

**The script picks the wrong GPU on a laptop**

Taking the first display adapter out of `lspci` gives you the integrated chip on any hybrid laptop, because that is the order the bus reports. Filter for a discrete card first and fall back to the first adapter only when there is one card:

```bash
lspci | grep -iE 'vga|3d|display' | grep -iE 'nvidia|amd/ati|radeon' | head -1
```

**`Unable to create interface ISteamUser`**

This is the big one. The game ships its own Steam API emulator, and Proton injects `lsteamclient` to bridge Steam calls to the native Linux client. That bridge grabs the call before the game's emulator can answer it. The fix is to tell Proton to stay out of the way:

```
WINEDLLOVERRIDES="lsteamclient=d"
```

The launcher already sets this. If you run the game some other way, you need it too.

**Black screen, fan spinning, nothing happens**

Same root cause as above, just quieter. On plain Wine there is no error popup, the game just sits at a black window burning 500% CPU forever. If you see this, you are missing the `lsteamclient=d` override.

**`Failed to load System.Private.CoreLib.dll` / error `0x8007046C`**

`FL 2026 start.exe` is a single file .NET app and Wine 8 cannot map its bundled assemblies. Error `0x8007046C` is `ERROR_MAPPED_ALIGNMENT`. Use Wine 10 or newer, or GE-Proton11 like this guide does. Older Proton builds will fail here.

**Game freezes when I use a virtual desktop**

Do not use the Wine virtual desktop to work around fullscreen problems. It breaks Vulkan (`VK_KHR_surface` disappears) and the game crashes instead of just misbehaving.

**A black console window loops forever after an update**

At the end of the updates a script called `OneDrive.bat` runs. On Windows it moves your save between the normal Documents folder and the OneDrive one. There is no OneDrive here, so it asks "file or directory?" over and over and never stops.

Just close that window. The update is already done and your save is fine. If closing it does nothing:

```bash
pkill -x cmd.exe
pkill -x xcopy.exe
```

**An update hangs at the same percentage forever**

Check if it is really stuck before killing it. Watch the file count and the folder size, not the progress bar:

```bash
GAME=~/Games/spfl26/drive_c/Games/SPFL26
find "$GAME" -type f | wc -l && du -sh "$GAME"
```

Run that twice, thirty seconds apart. If both numbers move, it is working and you just have to wait. If neither moves for a few minutes, it is stuck. Close it and run that update again.

Do not check with `find -newermt`. The installers keep the original timestamps on the files they write, so a time based check shows nothing even while it is copying. That one fooled me for a while.

Also do not point an update at a symlinked folder. I tried linking `C:\Program Files (x86)\SP Football Life 2026` to the real game folder so I could skip typing the path, and update 2.0 hung at 38 percent every time. Pointing it at the real folder finished with no problem.

The script links both paths together so the launcher works either way, which means one of them is a symlink on your machine too. That is why it prints the real folder on screen before each update window opens. Type the path it prints, not the other one.

## Where everything goes

```
~/Games/
├── spfl26-proton/                 prefix and Proton compat data
├── spfl26-play.sh                 game launcher
└── spfl26-settings.sh             settings launcher, see the note above
```

Nothing is written outside your home folder. To uninstall, delete `~/Games/spfl26*` and the `.desktop` file.

## Credits

**[SmokePatch](https://www.pessmokepatch.com/)** made SP Football Life and every update. They do this for free, season after season, for a game the publisher walked away from. Go say thanks on their site.

**Sider** by juce is what loads all the mods into the game.

**[GloriousEggroll](https://github.com/GloriousEggroll/proton-ge-custom)** for GE-Proton.

I only figured out the Linux side and wrote it down. Buy the SmokePatch team a coffee, not me.

## Contributing

Got it running on another distro? Open an issue and tell me your specs and what you had to change. Bazzite and SteamOS reports are especially welcome.
