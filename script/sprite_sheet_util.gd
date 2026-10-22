class_name SpriteSheetUtil
extends RefCounted

## Helper buat ubah 1 gambar spritesheet grid (banyak frame animasi disusun
## rapi dalam baris & kolom) jadi Texture2D yang bisa langsung dipasang ke
## TextureRect.texture dan otomatis muter animasinya sendiri.
##
## Godot 4 punya class bawaan AnimatedTexture yang tepat buat ini -- dia
## adalah Texture2D biasa (jadi bisa dipasang di TextureRect, Sprite2D, dst)
## tapi isinya beberapa "frame" texture yang dia putar sendiri berdasarkan
## waktu, tanpa kita perlu bikin Timer / _process manual.
##
## Cara pakai singkat:
##   var tex := SpriteSheetUtil.build_from_grid(sheet_texture, 4, 2, 7, 8.0)
##   my_texture_rect.texture = tex
##
## sheet_texture : gambar besar yang isinya banyak frame disusun grid
## columns/rows  : berapa kolom & baris di grid itu (frame dianggap
##                 ukurannya sama rata, sheet_width/columns x sheet_height/rows)
## frame_count   : berapa frame yang BENERAN dipakai, dihitung dari kiri-atas
##                 baris demi baris. Isi 0 supaya otomatis pakai columns*rows
##                 (dipakai kalau grid-nya penuh, tidak ada sisa kotak kosong)
## fps           : kecepatan animasi (frame per detik). 6-10 biasanya pas
##                 buat animasi idle "napas" Pokemon gaya Gen 5.


static func build_from_grid(
	sheet: Texture2D,
	columns: int,
	rows: int,
	frame_count: int = 0,
	fps: float = 6.0
) -> Texture2D:
	if sheet == null:
		return null

	var safe_columns: int = maxi(columns, 1)
	var safe_rows: int = maxi(rows, 1)

	# Grid 1x1 berarti sebenarnya cuma 1 gambar diam -- tidak perlu dibungkus
	# AnimatedTexture, langsung balikin apa adanya saja.
	if safe_columns <= 1 and safe_rows <= 1:
		return sheet

	var total_frames: int = frame_count if frame_count > 0 else safe_columns * safe_rows
	total_frames = clampi(total_frames, 1, 256) # AnimatedTexture max 256 frame

	if total_frames <= 1:
		return sheet

	# PENTING: sengaja TIDAK pakai AtlasTexture (region/"jendela" ke gambar
	# besar yang sama). AtlasTexture berbagi 1 texture asli buat semua frame,
	# dan kalau texture_filter di sprite-nya "Linear", GPU suka "bocor"
	# ngambil pixel dari frame sebelah pas nge-render texel di pinggir
	# region -- apalagi buat spritesheet strip panjang kayak gini (112 frame
	# 50px berjejer). Bocor ini yang bikin sprite kelihatan kayak noise/garis
	# acak. Solusinya: potong beneran jadi Image terpisah per frame (data
	# pixel sendiri-sendiri, tidak nempel ke frame lain sama sekali).
	var sheet_image: Image = sheet.get_image()
	if sheet_image == null:
		push_warning("SpriteSheetUtil: tidak bisa baca pixel dari spritesheet ini (mungkin di-import sebagai format VRAM-compressed). Pakai gambar sheet apa adanya tanpa animasi.")
		return sheet

	var frame_width: int = int(sheet.get_width() / float(safe_columns))
	var frame_height: int = int(sheet.get_height() / float(safe_rows))
	var frame_duration: float = 1.0 / maxf(fps, 0.1)

	var animated := AnimatedTexture.new()
	animated.frames = total_frames

	for i in total_frames:
		var col: int = i % safe_columns
		@warning_ignore("integer_division") # sengaja: butuh indeks baris bulat
		var row: int = i / safe_columns

		var frame_image: Image = sheet_image.get_region(
			Rect2i(col * frame_width, row * frame_height, frame_width, frame_height)
		)
		var frame_texture: ImageTexture = ImageTexture.create_from_image(frame_image)

		animated.set_frame_texture(i, frame_texture)
		animated.set_frame_duration(i, frame_duration)

	return animated
