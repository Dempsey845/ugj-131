extends StaticBody3D

@onready var multi_meshes: Array[ShelfMultiMesh] = [$ShelfMultiMesh, $ShelfMultiMesh2, $ShelfMultiMesh3]

var shelf_types: Array = [
	{"name": "MilkCarton", "rows": 2, "columns": 6, "column_spacing": 0.5, "row_spacing": 0.5, "uid": "uid://pj41rpnndqq0"},
	{"name": "Can", "rows": 2, "columns": 8, "column_spacing": 0.35 ,"row_spacing": 0.5, "uid": "uid://tryi53dxllik"},
	{"name": "BigBottle", "rows": 2, "columns": 6, "column_spacing": 0.5, "row_spacing": 0.5, "uid": "uid://b7d3gfcp2a0my"},\
	{"name": "Bottle", "rows": 2, "columns": 8, "column_spacing": 0.35, "row_spacing": 0.5, "uid": "uid://d2pdcwv1fct3o"},
	{"name": "Springles", "rows": 2, "columns": 8, "column_spacing": 0.35, "row_spacing": 0.5, "uid": "uid://vl76rjusy0q6"},
	{"name": "CerealBox", "rows": 3, "columns": 5, "column_spacing": 0.6, "row_spacing": 0.3, "uid": "uid://uk5bu5veu7ci"},
	{"name": "Glass", "rows": 2, "columns": 8, "column_spacing": 0.35, "row_spacing": 0.5, "uid": "uid://b0n8m4cdoixvo"},
	{"name": "Tin", "rows": 2, "columns": 5, "column_spacing": 0.6, "row_spacing": 0.5, "uid": "uid://dxs7u02vwd68g"},

]

func _ready() -> void:
	var random_shelf_type = shelf_types.pick_random()

	var shelf_item_mesh = load(random_shelf_type["uid"])
	multi_meshes[0].multimesh.mesh = shelf_item_mesh

	for multi_mesh: ShelfMultiMesh in multi_meshes:
		multi_mesh.rows = random_shelf_type["rows"]
		multi_mesh.columns = random_shelf_type["columns"]
		multi_mesh.column_spacing = random_shelf_type["column_spacing"]
		multi_mesh.row_spacing = random_shelf_type["row_spacing"]
		multi_mesh.populate_shelf()
	
		
