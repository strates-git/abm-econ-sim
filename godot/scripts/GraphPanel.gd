extends Control

var history: Array = []
var marker_index: int = 0

var _series_keys: Array = ["employment", "avg_wage", "total_wealth"]
var _labels: Array = ["Total Employment", "Avg Wage", "Total Wealth"]
var _colors: Array = [
	Color(0.3, 0.9, 0.35),
	Color(0.95, 0.8, 0.3),
	Color(0.4, 0.7, 1.0),
]

func set_history(h: Array) -> void:
	history = h
	queue_redraw()

func set_marker(i: int) -> void:
	marker_index = i
	queue_redraw()

func _draw() -> void:
	var font := get_theme_default_font()
	var strips := _series_keys.size()
	var strip_h := size.y / float(strips)
	var pad := 8.0

	for s in range(strips):
		var y0 := s * strip_h
		draw_rect(Rect2(0, y0, size.x, strip_h - 2.0), Color(0, 0, 0, 0.35), true)

		var data: Array = _extract(_series_keys[s])
		if data.size() < 2:
			continue

		var vmin: float = data[0]
		var vmax: float = data[0]
		for v in data:
			vmin = min(vmin, float(v))
			vmax = max(vmax, float(v))
		if vmax - vmin < 1e-9:
			vmax = vmin + 1.0

		var w := size.x - pad * 2.0
		var h := strip_h - pad * 2.0
		var pts := PackedVector2Array()
		for i in range(data.size()):
			var x := pad + w * float(i) / float(data.size() - 1)
			var norm: float = (float(data[i]) - vmin) / (vmax - vmin)
			var y := y0 + pad + h * (1.0 - norm)
			pts.append(Vector2(x, y))

		draw_polyline(pts, _colors[s], 2.0)

		var idx: int = clampi(marker_index, 0, data.size() - 1)
		var mx := pad + w * float(idx) / float(data.size() - 1)
		draw_line(Vector2(mx, y0 + 2.0), Vector2(mx, y0 + strip_h - 2.0), Color(1, 1, 1, 0.5), 1.0)

		var label: String = "%s  %s" % [_labels[s], _fmt(float(data[idx]))]
		draw_string(font, Vector2(pad + 4.0, y0 + 14.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, _colors[s])

func _extract(key: String) -> Array:
	var out: Array = []
	for entry in history:
		out.append(float(entry.get(key, 0.0)))
	return out

func _fmt(value: float) -> String:
	return "%.2f" % value
