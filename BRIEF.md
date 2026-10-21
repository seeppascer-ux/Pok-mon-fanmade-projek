# Brief Proyek: Pokémon Fanmade

*Brief resmi proyek menurut pola studio (lihat blueprint studio). Dokumen ini dibaca semua agen sebelum bekerja di proyek ini.*

## 1. Konsep
- **Judul**: Pokémon Fanmade (fanmade, non-komersial)
- **Satu kalimat**: RPG Pokémon 2D bergaya klasik — jelajahi desa, tangkap dan latih Pokémon, bertarung turn-based, dan berevolusi.
- **Genre**: RPG / monster-taming, eksplorasi top-down + battle turn-based
- **Platform**: Godot 4.7 (desktop dulu; mobile menyusul bila owner mau)
- **Suasana/tema**: nostalgia Gen 1, 151 spesies
- **Batasan konten**: fanmade untuk belajar & hobi; bukan untuk penjualan

## 2. Mekanik Inti
- **Yang dilakukan pemain**: berjalan di peta desa/dunia, encounter Pokémon liar, bertarung, naik level, evolusi
- **Kontrol**: keyboard (gerakan grid)
- **Battle**: turn-based; urutan serangan ditentukan **priority move dulu, lalu speed**; ada EXP & level-up
- **Skor & progres**: level Pokémon, garis evolusi, koleksi spesies
- **Fitur yang sudah jadi (per 20 Okt 2026)**:
  - 151 spesies dengan data lengkap (sprite depan 268 file, ikon, tileset — semua terverifikasi bersih di GitHub)
  - Sistem battle + mekanik priority (mis. Quick Attack)
  - EXP bar + animasi naik level di UI battle
  - Garis evolusi tersambung untuk 69/151 spesies (46 evolusi level otomatis)
  - Sistem evolusi batu & trade (sejak 20 Okt 2026): 5 item batu (Api/Air/Petir/Daun/Bulan), 12 spesies batu + 4 trade tertandai, API `evolve_with_stone()`/`evolve_by_trade()` + `Bag.use_stone_on()` — teruji headless 32/32
  - Desa: 1 rumah + area rumput liar (fitur "desa hidup" — 3 NPC, daun jatuh, kupu-kupu, 2 rumah tambahan — **dihapus 21 Okt 2026** atas permintaan owner karena bug; bisa dikembalikan dari history git bila diinginkan)

## 3. Aset
- **Sprite**: `asset/pokemon/front/` (268), `asset/icons/` (235), `asset/icon/` (17 UI), tileset `asset/tile/` (10) — semua PNG valid & byte-identical dengan remote
- **Sumber**: paket aset yang dibagikan owner + perbaikan file rusak lewat jalur push aman studio
- **Aturan**: file biner tidak pernah di-push lewat jalur yang bisa merusaknya; selalu verifikasi remote sesudah push

## 4. Teknis
- **Engine**: Godot 4.7.2, GDScript; data spesies/move sebagai `.tres`
- **Repo**: `seeppascer-ux/Pok-mon-fanmade-projek` (branch `main`)
- **Tes**: import & run headless wajib bersih sebelum lapor selesai

## 5. Pembagian Tugas (pola studio)
- **Produser (karin)**: koordinasi, verifikasi, push, lapor ke owner
- **Programmer**: sistem battle, EXP, evolusi, peta
- **Artist**: sprite, tileset
- **QA**: tes headless (semua spesies termuat, rantai evolusi valid, simulasi battle & level-up)

## 6. Backlog (menunggu keputusan owner / belum dikerjakan)
1. **6 move yatim** (`powder_snow`, `karate_chop`, `lick`, `dragon_rage`, `metal_claw`, `fairy_wind`): file-nya masih draf lokal, belum terhubung ke spesies mana pun. Peta learnset untuk 26 spesies sudah diusulkan ke owner 15 Okt 2026 — menunggu persetujuan.
2. ~~**Sistem evolusi batu & trade**~~ — SELESAI (sistem) 20 Okt 2026: data + logika + tas berfungsi & teruji. Sisa tahap berikutnya: kabel UI (menu party "pakai batu") + pemicu trade di dalam game — belum dikerjakan.
3. **Eevee**: evolusi bercabang 3 belum didukung field `evolves_into` yang hanya satu target.

## 7. Definisi Selesai (tahap saat ini)
- [x] Semua aset valid di GitHub & terverifikasi
- [x] Battle + priority + EXP bar berfungsi & teruji headless
- [x] Garis evolusi level tersambung & teruji end-to-end
- ~~[x] Desa hidup (NPC + ambient + rumah) terpasang & teruji~~ — **dihapus 21 Okt 2026** (bug); desa kembali ke kondisi awal
- [ ] Backlog di atas diputuskan owner satu per satu

---
*Status: disetujui owner — pola studio diterapkan 20 Oktober 2026. Dokumen hidup; ubah lewat karin.*
