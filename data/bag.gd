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
