# REPORT — Craft App Suite rebuild for Ubuntu 20.04 (glibc 2.31)

Date: 2026-10-11 · Build host: x86_64 sandbox, no Docker/no root · Build env: **Ubuntu 20.04.5**
rootfs via proot (ptrace user-space chroot, `-0` fake-root), gcc 9.4.0, glibc 2.31, rustup stable
1.99.0. Pipeline script: `build-all.sh` (this repo).

## Scope

All 12 Craft Apps published by `storytold`, latest stable tag of each, GUI + CLI binaries each,
packaged as AppImages (+ `.zsync`). Companion: ArtCraft Launcher 0.1.2 rebuild lives in
`PSNarayananmc/artcraft-launcher-ubuntu20.04`.

## Per-app results

| App | Tag | Build | GLIBC floor (objdump, max) | ldd missing | Xvfb launch (12 s) | AppImage extract-and-run | Notes |
|---|---|---|---|---|---|---|---|
| wordcraft | v0.5.0 | ✅ | 2.30 | 0 | exit 124 → alive | ✅ | |
| gridcraft | v0.5.0 | ✅ | 2.30 | 0 | exit 124 → alive | ✅ | |
| deckcraft | v0.5.0 | ✅ | 2.30 | 0 | exit 124 → alive | ✅ | links libasound.so.2 (resolves on 20.04) |
| pdfcraft | v0.6.0 | ✅ | 2.30 | 0 | exit 124 → alive | ✅ | aws-lc-sys built with cmake 3.16 |
| designcraft | v0.6.0 | ✅ | 2.30 | 0 | exit 124 → alive | ✅ | |
| lightcraft | v0.6.0 | ✅ | 2.30 | 0 | exit 124 → alive | ✅ | opened its sample library during test |
| soundcraft | v0.5.0 | ✅ | 2.30 | 0 | exit 124 → alive | ✅ | no audio device → "silent clock" fallback by design |
| vectorcraft | v0.9.0 | ✅ | 2.30 | 0 | exit 124 → alive | ✅ | one OOM kill at `-j2`; finished at `-j1` |
| effectcraft | v0.8.0 | ✅ | 2.30 | 0 | exit 124 → alive | ✅ | thin-LTO link livelocked (>40 min single rustc); built with `CARGO_PROFILE_RELEASE_LTO=false` |
| cadcraft | v0.5.0 | ✅ | 2.30 | 0 | exit 124 → alive | ✅ | |
| photocraft | v0.7.0 | ✅ | 2.30 | 0 | exit 124 → alive | ✅ | one OOM kill at `-j2`; finished at `-j1`; pipewire/drm/gbm deps needed no system libs at build time |
| filmcraft | v0.6.0 | ✅ | 2.30 | 0 | exit 124 → alive | ✅ | ALSA warnings under Xvfb = no sound device in sandbox |

"exit 124" means the 12-second timeout fired while the app was still running its event loop —
i.e. the app started and stayed alive. Typical log lines during the test: wgpu selecting
`llvmpipe (LLVM 12.0.0, 256 bits)` software GL; ALSA "Unknown PCM" warnings only (headless).

## Source changes

**None.** All 12 apps compiled with `cargo build --release --locked` unmodified. No vendoring,
no dependency pinning, no glibc upgrades. System packages used are all from the 20.04 repos.

## Runtime library needs (beyond glibc)

- `libasound.so.2` (ALSA): deckcraft, effectcraft, soundcraft, filmcraft. Package `libasound2` —
  present on every desktop installation; the official AppImages rely on it the same way.
- `libgcc_s.so.1`: all (gcc runtime, present everywhere, backward compatible).
- Nothing else — no bundled non-glibc libraries, matching the official packaging layout.

## SHA-256 of all artifacts

```
05d67e641d5f84630fb8f8819e7e6ed9ff59ace96e5436c36de51a80c3848ef7  photocraft-0.7.0-linux-x86_64.AppImage
8e01ee6f5fa5b07c8a7f1e402d349703ae948fbb8e80cf80740d4045c40aa837  vectorcraft-0.9.0-linux-x86_64.AppImage
54154264cda06e66c8a3fc42134bf4adfc7a81c2e1164d3f306085c24f043dcb  filmcraft-0.6.0-linux-x86_64.AppImage
699086895051d163e64edcbb8a6cb5d1a30fae0848a9b8e882328c66103d8c62  lightcraft-0.6.0-linux-x86_64.AppImage
6bd7674a092b1ff028426789b959ee43e0fce4680b5d0c5482948e2b2331bcf4  pdfcraft-0.6.0-linux-x86_64.AppImage
52522d0377ba67271e1a8d9005d5d57fb5dc565d6eb909db1e3094a4053f1f78  effectcraft-0.8.0-linux-x86_64.AppImage
3932ba602154893bb83c13df148b65ab8fc619d2949cef70d5d7418eecb7cf01  designcraft-0.6.0-linux-x86_64.AppImage
8ab719ac134245c2ec73f2c8af5dd06a5f1c27cbfe9bb7a26e12f9df877bb31a  wordcraft-0.5.0-linux-x86_64.AppImage
8013b8cfd3c7baa70b39b9b0fdb18458812f07939699f22e017330f9e05dda2f  deckcraft-0.5.0-linux-x86_64.AppImage
801d0abd36d6d0737446d6c8898aebea67fbcd64025789bb93d4bc7cdd60a99d  gridcraft-0.5.0-linux-x86_64.AppImage
5e01f86365959e7640973321695a5a461911606f4ad668c68c4426aa3cd6d6b0  cadcraft-0.5.0-linux-x86_64.AppImage
4fe0ad0f42953a4f7dcf1e4568c15aab4a8beae6753582092db1560a7b2eabdb  soundcraft-0.5.0-linux-x86_64.AppImage
```
(Each has a matching `.AppImage.zsync`.)

## How to reproduce

`build-all.sh <app>` — clones `storytold/<app>` at its latest stable tag into a work dir, installs
the 20.04 apt deps inside the proot rootfs, runs `cargo build --release --locked` for the GUI +
CLI packages, verifies (glibc floor / ldd / Xvfb smoke), then packages with the repo's own
`packaging/linux/package.sh --formats appimage` and extract-and-run smoke-tests the result.
The launcher repo's `build.sh` + `Dockerfile` document the same environment from scratch.

## Known limitations

- Sandbox limits: 2 cores / 4 GB RAM / ~10 min per execution — hence `-j1` retries and the
  EffectCraft LTO deviation (the only profile change anywhere; glibc floor unaffected).
- Headless verification only: no real GPU (llvmpipe), no session D-Bus (tray/notifications
  degrade gracefully by design), no audio device. Smoke tests prove startup + event loop, not
  full interactive sessions.
- Each AppImage's `gh-releases-zsync` update-info points at this repository; upstream will keep
  publishing 2.35 builds, so new versions must be rebuilt this way to stay on 20.04.
