# Craft App Suite — Ubuntu 20.04 (glibc 2.31) rebuilds

All **12 Craft Apps** rebuilt on a genuine **Ubuntu 20.04.5** environment (glibc 2.31, gcc 9.4.0,
rustup stable 1.99.0) so they run on Ubuntu 20.04 LTS. The official releases are built on
ubuntu-22.04 runners and require **GLIBC_2.35** — these builds reference at most **GLIBC_2.30**.

**Download everything from the [Releases page](https://github.com/PSNarayananmc/craft-apps-ubuntu20.04/releases/tag/ubuntu20.04-2026.10.11).**

Companion project: the ArtCraft Launcher itself, rebuilt for 20.04 →
[artcraft-launcher-ubuntu20.04](https://github.com/PSNarayananmc/artcraft-launcher-ubuntu20.04).

## Verification matrix (all apps)

| App | Tag | GLIBC floor | ldd missing | Headless launch (Xvfb) | AppImage | SHA-256 |
|---|---|---|---|---|---|---|
| PhotoCraft | v0.7.0 | 2.30 | 0 | ✅ alive | 43 MB | `05d67e641d5f84630fb8f8819e7e6ed9ff59ace96e5436c36de51a80c3848ef7` |
| VectorCraft | v0.9.0 | 2.30 | 0 | ✅ alive | 48 MB | `8e01ee6f5fa5b07c8a7f1e402d349703ae948fbb8e80cf80740d4045c40aa837` |
| FilmCraft | v0.6.0 | 2.30 | 0 | ✅ alive | 35 MB | `54154264cda06e66c8a3fc42134bf4adfc7a81c2e1164d3f306085c24f043dcb` |
| LightCraft | v0.6.0 | 2.30 | 0 | ✅ alive (opened its sample library) | 37 MB | `699086895051d163e64edcbb8a6cb5d1a30fae0848a9b8e882328c66103d8c62` |
| PdfCraft | v0.6.0 | 2.30 | 0 | ✅ alive (renderer init logged) | 47 MB | `6bd7674a092b1ff028426789b959ee43e0fce4680b5d0c5482948e2b2331bcf4` |
| EffectCraft | v0.8.0 | 2.30 | 0 | ✅ alive | 53 MB | `52522d0377ba67271e1a8d9005d5d57fb5dc565d6eb909db1e3094a4053f1f78` |
| DesignCraft | v0.6.0 | 2.30 | 0 | ✅ alive | 37 MB | `3932ba602154893bb83c13df148b65ab8fc619d2949cef70d5d7418eecb7cf01` |
| WordCraft | v0.5.0 | 2.30 | 0 | ✅ alive | 30 MB | `8ab719ac134245c2ec73f2c8af5dd06a5f1c27cbfe9bb7a26e12f9df877bb31a` |
| DeckCraft | v0.5.0 | 2.30 | 0 | ✅ alive | 25 MB | `8013b8cfd3c7baa70b39b9b0fdb18458812f07939699f22e017330f9e05dda2f` |
| GridCraft | v0.5.0 | 2.30 | 0 | ✅ alive | 16 MB | `801d0abd36d6d0737446d6c8898aebea67fbcd64025789bb93d4bc7cdd60a99d` |
| CadCraft | v0.5.0 | 2.30 | 0 | ✅ alive | 21 MB | `5e01f86365959e7640973321695a5a461911606f4ad668c68c4426aa3cd6d6b0` |
| SoundCraft | v0.5.0 | 2.30 | 0 | ✅ alive (audio → silent clock fallback) | 15 MB | `4fe0ad0f42953a4f7dcf1e4568c15aab4a8beae6753582092db1560a7b2eabdb` |

Every AppImage contains the GUI binary **and** its `-cli` companion, packaged with each repo's own
`packaging/linux/package.sh` + `appimagetool` (same layout as the official releases). The embedded
`gh-releases-zsync` update-info points at **this repository**, so AppImageUpdate can never replace
a 20.04 build with an official 2.35 build.

## Build environment & method

- Real Ubuntu **20.04.5** rootfs (ubuntu-base from cdimage.ubuntu.com), driven via **proot**
  (user-space chroot, no root needed) — same recipe as the launcher repo's `build.sh`.
- `apt`: build-essential, pkg-config, libssl-dev, X11/Wayland/xkb dev stacks, libasound2-dev,
  libudev-dev, libgtk-3-dev, libdrm/gbm/clang dev, cmake/ninja, xvfb + Mesa (llvmpipe) for tests.
- Rust via rustup stable; every app built with **`cargo build --release --locked`**.
- Verification per app: `objdump` glibc symbol floor, `ldd` (0 "not found" on 20.04),
  12 s `xvfb-run` launch test (exit 124 = event loop alive), then AppImage extract-and-run test.

`build-all.sh` in this repo automates the whole pipeline (clone tag → deps → build → verify →
package → smoke-test) for any of the 12 apps; `REPORT.md` has the full report and caveats.

## Notes & caveats

- **No source changes were required in any of the 12 apps.**
- EffectCraft needed `CARGO_PROFILE_RELEASE_LTO=false` for the final link (thin-LTO link exceeded
  the 10-minute execution window here; glibc floor and optimization level unaffected).
- PhotoCraft/VectorCraft were built with `-j1` after one OOM kill each (2-core/4 GB sandbox).
- Apps that link ALSA (deckcraft/effectcraft/soundcraft/filmcraft) need `libasound2` at runtime —
  installed by default on desktop distros.
- The launcher downloads these apps from the **official** GitHub releases (which need glibc 2.35);
  to stay fully on 20.04, install from **this** repo's release files instead (download the AppImage
  into `~/Applications`, which the launcher also detects).

Upstream: https://github.com/storytold (MIT OR Apache-2.0).
