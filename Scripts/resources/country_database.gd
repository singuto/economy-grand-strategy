extends Resource
class_name CountryDatabase

@export var entries: Array[CountryEntry] = []


func get_entry(country_id: int) -> CountryEntry:
	for e in entries:
		if e.id == country_id:
			return e
	return null


func get_display_name(country_id: int) -> String:
	var e := get_entry(country_id)
	return e.display_name if e else ""
