extends TileMap

var last_clicked_cell: Vector2i = Vector2(3, 2) 
var highlighted_cells: Array[Vector2i] = []

func _input(event):
	var curr_cell = local_to_map(to_local(get_global_mouse_position()))


	if event is InputEventMouseMotion:
		for cell in highlighted_cells:
			set_cell(0, cell, 22, get_cell_atlas_coords(0, cell), 0)
		highlighted_cells = HexHelper.oddr_linedraw(last_clicked_cell, curr_cell)
		for cell in highlighted_cells:
			set_cell(0, cell, 22, get_cell_atlas_coords(0, cell), 3)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print(highlighted_cells)
			print(HexHelper.cube_linedraw(HexHelper.axial_to_cube(HexHelper.oddr_to_axial(last_clicked_cell)), HexHelper.axial_to_cube(HexHelper.oddr_to_axial(curr_cell))))
			print(curr_cell)
			print()
			last_clicked_cell = curr_cell

			
