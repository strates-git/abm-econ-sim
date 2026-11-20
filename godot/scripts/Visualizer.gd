extends Node

const STATE_PATH = "../snapshot.json"

const HOUSEHOLD_RADIUS = 1.5
const FIRM_EXTENT = 3.0
const FRAME_DELAY = 0.05  # seconds per frame (~20 fps)
const PICK_RADIUS = 40.0  # pixels

var world: Node3D
var tick_label: Label
var pause_button: Button
var info_panel: Panel
var info_label: Label
var graph_panel

var ticks: Array = []
var current_index: int = 0
var timer: float = 0.0
var playing: bool = false
var selected_node: MeshInstance3D = null

func _ready() -> void:
	world = Node3D.new()
	world.name = "World"
	add_child(world)

	var static_world: Node3D = Node3D.new()
	static_world.name = "Static"
	world.add_child(static_world)
	_build_environment()
	_build_ground(static_world)
	_build_grid(static_world)

	var camera: Camera3D = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(65, 75, 65)
	camera.look_at(Vector3(0, 5, 0))

	var light: DirectionalLight3D = DirectionalLight3D.new()
	add_child(light)
	light.position = Vector3(40, 80, 40)
	light.look_at(Vector3(0, 0, 0))
	light.shadow_enabled = true

	var ui: CanvasLayer = CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	_build_ui(ui)

	_load_snapshot()

func _build_ui(ui: CanvasLayer) -> void:
	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.position = Vector2(10, 10)
	pause_button.size = Vector2(90, 30)
	pause_button.pressed.connect(_toggle_pause)
	ui.add_child(pause_button)

	tick_label = Label.new()
	tick_label.position = Vector2(110, 16)
	tick_label.size = Vector2(200, 30)
	ui.add_child(tick_label)

	info_panel = Panel.new()
	info_panel.anchor_left = 1.0
	info_panel.anchor_right = 1.0
	info_panel.anchor_top = 0.0
	info_panel.anchor_bottom = 0.0
	info_panel.offset_left = -300.0
	info_panel.offset_right = -10.0
	info_panel.offset_top = 50.0
	info_panel.offset_bottom = 280.0
	info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.visible = false
	ui.add_child(info_panel)

	info_label = Label.new()
	info_label.anchor_right = 1.0
	info_label.anchor_bottom = 1.0
	info_label.offset_left = 8.0
	info_label.offset_top = 8.0
	info_label.offset_right = -8.0
	info_label.offset_bottom = -8.0
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_child(info_label)

	var graph_script: GDScript = load("res://scripts/GraphPanel.gd")
	graph_panel = graph_script.new()
	graph_panel.anchor_left = 0.0
	graph_panel.anchor_right = 1.0
	graph_panel.anchor_top = 1.0
	graph_panel.anchor_bottom = 1.0
	graph_panel.offset_left = 10.0
	graph_panel.offset_right = -10.0
	graph_panel.offset_top = -250.0
	graph_panel.offset_bottom = -10.0
	graph_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(graph_panel)

func _toggle_pause() -> void:
	playing = not playing
	pause_button.text = "Play" if not playing else "Pause"

func _build_environment() -> void:
	var env: Environment = Environment.new()
	var sky: Sky = Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _build_ground(parent: Node3D) -> void:
	var ground: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(160, 160)
	ground.mesh = plane
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.36, 0.4)
	ground.material_override = mat
	parent.add_child(ground)

func _build_grid(parent: Node3D) -> void:
	var spacing: float = 20.0
	var extent: float = 80.0
	var count: int = int(extent / spacing)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.55, 0.6)
	for i in range(-count, count + 1):
		var offset: float = float(i) * spacing

		var line_x: MeshInstance3D = MeshInstance3D.new()
		var bx: BoxMesh = BoxMesh.new()
		bx.size = Vector3(0.3, 0.02, extent * 2.0)
		line_x.mesh = bx
		line_x.position = Vector3(offset, 0.03, 0.0)
		line_x.material_override = mat
		parent.add_child(line_x)

		var line_z: MeshInstance3D = MeshInstance3D.new()
		var bz: BoxMesh = BoxMesh.new()
		bz.size = Vector3(extent * 2.0, 0.02, 0.3)
		line_z.mesh = bz
		line_z.position = Vector3(0.0, 0.03, offset)
		line_z.material_override = mat
		parent.add_child(line_z)

func _load_snapshot() -> void:
	if not FileAccess.file_exists(STATE_PATH):
		return

	var file: FileAccess = FileAccess.open(STATE_PATH, FileAccess.READ)
	if file == null:
		return

	var content: String = file.get_as_text()
	file.close()

	var data: Variant = JSON.parse_string(content)
	if data == null or typeof(data) != TYPE_DICTIONARY:
		return

	var ticks_data: Array = data.get("ticks", [])
	if typeof(ticks_data) != TYPE_ARRAY:
		return

	ticks = ticks_data
	if ticks.size() > 0:
		current_index = 0
		playing = true
		graph_panel.set_history(_build_metrics_history())
		_render_tick(current_index)

func _build_metrics_history() -> Array:
	var history: Array = []
	for entry in ticks:
		var m: Dictionary = entry.get("metrics", {})
		history.append({
			"employment": m.get("employment", 0),
			"avg_wage": m.get("avg_wage", 0.0),
			"total_wealth": m.get("total_wealth", 0.0),
		})
	return history

func _process(_delta: float) -> void:
	if not playing or ticks.size() == 0:
		return

	timer += _delta
	if timer >= FRAME_DELAY:
		timer = 0.0
		current_index += 1
		if current_index >= ticks.size():
			current_index = 0
		_render_tick(current_index)

func _render_tick(index: int) -> void:
	if index < 0 or index >= ticks.size():
		return

	var data: Dictionary = ticks[index]
	var tick: int = data.get("tick", 0)
	tick_label.text = "Tick: %d" % [tick]
	graph_panel.set_marker(index)

	selected_node = null
	info_panel.visible = false
	_clear_agents()

	var households: Array = data.get("households", [])
	_render_agents(households, true)

	var firms: Array = data.get("firms", [])
	_render_agents(firms, false)

func _clear_agents() -> void:
	var children: Array = world.get_children()
	for i in range(children.size() - 1, -1, -1):
		var child = children[i]
		if child is MeshInstance3D:
			child.queue_free()

func _render_agents(agents: Array, is_household: bool) -> void:
	for agent in agents:
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.material_override = StandardMaterial3D.new()
		var lift: float = HOUSEHOLD_RADIUS if is_household else FIRM_EXTENT * 0.5

		if is_household:
			var sphere: SphereMesh = SphereMesh.new()
			sphere.radius = HOUSEHOLD_RADIUS
			sphere.height = HOUSEHOLD_RADIUS * 2.0
			instance.mesh = sphere
			var employed: bool = agent.get("employed", false)
			instance.material_override.albedo_color = Color(0.2, 0.8, 0.2) if employed else Color(0.6, 0.6, 0.6)
		else:
			var box: BoxMesh = BoxMesh.new()
			box.size = Vector3(FIRM_EXTENT, FIRM_EXTENT, FIRM_EXTENT)
			instance.mesh = box
			var price: float = agent.get("price", 0.0)
			var t: float = clamp(price, 0.0, 20.0) / 20.0
			instance.material_override.albedo_color = Color(1.0, 0.25, 0.25).lerp(Color(0.2, 0.6, 1.0), t)

		instance.position = Vector3(agent.get("x", 0), agent.get("y", 0) + lift, agent.get("z", 0))
		instance.set_meta("agent", agent)
		instance.set_meta("kind", "household" if is_household else "firm")
		world.add_child(instance)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pick_at(event.position)

func _pick_at(screen_pos: Vector2) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return

	var best: MeshInstance3D = null
	var best_dist: float = PICK_RADIUS

	for child in world.get_children():
		if not (child is MeshInstance3D):
			continue
		var wp: Vector3 = child.global_position
		if camera.is_position_behind(wp):
			continue
		var sp: Vector2 = camera.unproject_position(wp)
		var d: float = sp.distance_to(screen_pos)
		if d < best_dist:
			best_dist = d
			best = child

	if best != null:
		selected_node = best
		_show_info(best)
	else:
		selected_node = null
		info_panel.visible = false

func _show_info(node: MeshInstance3D) -> void:
	var agent: Dictionary = node.get_meta("agent", {})
	var kind: String = node.get_meta("kind", "agent")

	var lines: Array = []
	if kind == "household":
		lines.append("Household #%d" % int(agent.get("id", 0)))
		lines.append("Money: %.2f" % float(agent.get("money", 0.0)))
		lines.append("Employed: %s" % ("yes" if agent.get("employed", false) else "no"))
		var emp_id = agent.get("employer_id", null)
		lines.append("Employer: %s" % ("none" if emp_id == null else str(emp_id)))
		lines.append("Wage: %.2f" % float(agent.get("wage", 0.0)))
		lines.append("Consumption: %.2f" % float(agent.get("consumption", 0.0)))
	else:
		lines.append("Firm #%d" % int(agent.get("id", 0)))
		lines.append("Money: %.2f" % float(agent.get("money", 0.0)))
		lines.append("Price: %.2f" % float(agent.get("price", 0.0)))
		lines.append("Wage offer: %.2f" % float(agent.get("wage_offer", 0.0)))
		lines.append("Inventory: %.2f" % float(agent.get("inventory", 0.0)))
		lines.append("Production: %.2f" % float(agent.get("production", 0.0)))
		lines.append("Sales: %.2f" % float(agent.get("sales", 0.0)))
		var employees: Array = agent.get("employees", [])
		lines.append("Employees: %d" % employees.size())

	lines.append("Pos: (%.1f, %.1f, %.1f)" % [
		float(agent.get("x", 0.0)),
		float(agent.get("y", 0.0)),
		float(agent.get("z", 0.0)),
	])

	info_label.text = "\n".join(PackedStringArray(lines))
	info_panel.visible = true
