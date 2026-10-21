class_name Bag
extends Resource

## Tas item milik player. Isi lewat Inspector: array "slots" isinya BagSlot
## (item + jumlah) -- lihat contoh jadi di res://data/starter_bag.tres,
## atau tambah/kurangi lewat kode pakai add_item()/remove_item() di bawah.
##
## Cara pakai:
##   @export var bag: Bag   # di world.gd, drag starter_bag.tres ke sini
##   bag.add_item(potion_item, 3)
##   if bag.has_item(poke_ball_item):
##       ...

@export var slots: Array[BagSlot] = []


## Tambah "amount" item ke Tas. Kalau item itu sudah ada, jumlahnya ditambah
## di slot yang sama; kalau belum ada, dibuatkan slot baru.
func add_item(item: ItemData, amount: int = 1) -> void:
	if item == null or amount <= 0:
		return
	for slot in slots:
		if slot.item == item:
			slot.quantity += amount
			return
	var new_slot := BagSlot.new()
	new_slot.item = item
	new_slot.quantity = amount
	slots.append(new_slot)


## Kurangi "amount" item dari Tas. Return false kalau item itu tidak ada
## atau jumlahnya kurang dari "amount" (Tas tidak diubah sama sekali).
## Slot otomatis dihapus dari array kalau jumlahnya jadi 0.
func remove_item(item: ItemData, amount: int = 1) -> bool:
	for slot in slots:
		if slot.item == item:
			if slot.quantity < amount:
				return false
			slot.quantity -= amount
			if slot.quantity <= 0:
				slots.erase(slot)
			return true
	return false


func has_item(item: ItemData) -> bool:
	return get_quantity(item) > 0


func get_quantity(item: ItemData) -> int:
	for slot in slots:
		if slot.item == item:
			return slot.quantity
	return 0


## Pakai 1 batu evolusi (ItemData kategori EVO_STONE) dari Tas ke "target".
## Batu cuma berkurang kalau evolusinya beneran terjadi (sama seperti pola
## BattleManager.player_use_item: item tidak hangus kalau efeknya gagal).
## Return pesan-pesan buat ditampilkan ke UI, misal
## ["Pikachu berevolusi jadi Raichu!"] -- array kosong kalau gagal (batu
## tidak ada di Tas, bukan batu evolusi, atau tidak cocok buat target).
func use_stone_on(stone: ItemData, target: PokemonInstance) -> Array[String]:
	var messages: Array[String] = []
	if stone == null or target == null:
		return messages
	if stone.category != ItemData.Category.EVO_STONE:
		return messages
	if not has_item(stone):
		return messages
	if not target.can_evolve_with_stone(stone.evolution_stone_id):
		return messages
	messages = target.evolve_with_stone(stone.evolution_stone_id)
	if not messages.is_empty():
		remove_item(stone, 1)
	return messages


## ---------------------------------------------------------------------
## SAVE / LOAD (dipakai SaveSystem)
## ---------------------------------------------------------------------

## Item disimpan sebagai resource_path (+ item_name sebagai fallback).
func to_dict() -> Dictionary:
	var arr: Array = []
	for slot in slots:
		if slot == null or slot.item == null:
			continue
		arr.append({
			"item_path": slot.item.resource_path,
			"item_name": slot.item.item_name,
			"qty": slot.quantity,
		})
	return {"slots": arr}


static func from_dict(d: Dictionary) -> Bag:
	var bag := Bag.new()
	var arr: Array = d.get("slots", [])
	for entry in arr:
		if not (entry is Dictionary):
			continue
		var item := SaveLookup.item_by_path(str(entry.get("item_path", "")))
		if item == null:
			item = SaveLookup.item_by_name(str(entry.get("item_name", "")))
		if item == null:
			push_warning("SaveSystem: item '%s' tidak dikenal, slot dilewati." % str(entry.get("item_name", "?")))
			continue
		bag.add_item(item, maxi(1, int(entry.get("qty", 1))))
	return bag
