extends Node3D
## Aura Farm – Hauptspiel: Welt, Spieler, Tricks, Vapes, Shop, Multiplayer, Oberfläche.

const Smoke := preload("res://scripts/smoke.gd")
const Net := preload("res://scripts/net.gd")
const Sfx := preload("res://scripts/sfx.gd")

const VERSION := "1.0.0"
const SAVE_PATH := "user://save.json"
const DEFAULT_SERVER := "ws://100.126.128.24/auraserver/ws"
const U := "↑"
const D := "↓"
const L := "←"
const R := "→"
const KEYMAP := {KEY_UP: U, KEY_DOWN: D, KEY_LEFT: L, KEY_RIGHT: R}

const TRICKS := [
	{"id": "ghost", "name": "Ghost", "keys": [D, U], "min": 30, "aura": 60, "tier": 0},
	{"id": "orings", "name": "O-Ringe", "keys": [U, U, U], "min": 40, "aura": 90, "tier": 0},
	{"id": "french", "name": "French Inhale", "keys": [D, D, U, U], "min": 50, "aura": 130, "tier": 0},
	{"id": "dragon", "name": "Dragon", "keys": [L, R, L, R], "min": 55, "aura": 170, "tier": 0},
	{"id": "tornado", "name": "Tornado", "keys": [R, D, L, U], "min": 60, "aura": 210, "tier": 0},
	{"id": "jelly", "name": "Jellyfish", "keys": [U, U, D, D, L], "min": 70, "aura": 270, "tier": 0},
	{"id": "bane", "name": "Bane", "keys": [D, L, D, R, D], "min": 78, "aura": 340, "tier": 0},
	{"id": "wall", "name": "Wolkenwand", "keys": [L, L, D, D, R, R], "min": 65, "aura": 420, "tier": 2},
	{"id": "dtornado", "name": "Doppel-Tornado", "keys": [R, D, L, U, R, D, L, U], "min": 70, "aura": 600, "tier": 3},
	{"id": "mushroom", "name": "Pilzwolke", "keys": [D, D, D, U, U, U], "min": 76, "aura": 850, "tier": 4},
	{"id": "fogbank", "name": "Nebelbank", "keys": [L, R, U, D, L, R], "min": 80, "aura": 1200, "tier": 5},
	{"id": "citynebel", "name": "Stadtnebel", "keys": [U, U, D, D, L, R, L, R], "min": 85, "aura": 3000, "tier": 6},
]
const VAPES := [
	{"name": "Starter-Pod", "need": 0, "mult": 1, "cloud": 1.0, "color": Color("8b5cf6"), "accent": Color("22d3ee"), "scale": 1.0, "rate": 30.0, "desc": "Fürs Erste reicht's."},
	{"name": "Einweg-Puff", "need": 1500, "mult": 2, "cloud": 1.5, "color": Color("f472b6"), "accent": Color("fde047"), "scale": 1.05, "rate": 29.0, "desc": "Süß, bunt, mehr Wolke."},
	{"name": "Pod Pro", "need": 10000, "mult": 4, "cloud": 2.2, "color": Color("10b981"), "accent": Color("a7f3d0"), "scale": 1.12, "rate": 28.0, "desc": "Schaltet die Wolkenwand frei."},
	{"name": "Box-Mod 80 W", "need": 60000, "mult": 10, "cloud": 3.2, "color": Color("1f2937"), "accent": Color("ef4444"), "scale": 1.35, "rate": 26.0, "desc": "Jetzt wird's ernst: Doppel-Tornado."},
	{"name": "Dual-Coil 200 W", "need": 400000, "mult": 25, "cloud": 4.5, "color": Color("d4af37"), "accent": Color("ffffff"), "scale": 1.5, "rate": 25.0, "desc": "Gold. Pilzwolke freigeschaltet."},
	{"name": "Nebelmaschine", "need": 2500000, "mult": 60, "cloud": 6.5, "color": Color("0ea5e9"), "accent": Color("e0f2fe"), "scale": 1.7, "rate": 23.0, "desc": "Nebelbank: die Straße verschwindet."},
	{"name": "Wolkenkratzer 9000", "need": 20000000, "mult": 150, "cloud": 10.0, "color": Color("f8fafc"), "accent": Color("a855f7"), "scale": 1.9, "rate": 22.0, "desc": "Endlevel. Stadtnebel hüllt die ganze Stadt ein."},
]
const RANKS := [[-1e15, "Aura-Schulden"], [0, "NPC"], [400, "Normalo"], [1200, "Cloud-Chaser"], [2600, "Trick-Lord"], [5000, "Sigma"], [9000, "Aura-Gott"], [15000, "Unantastbar"], [60000, "Nebelkönig"], [500000, "Wolkenbaron"], [3000000, "Smog-Legende"], [20000000, "Stadtverhüller"]]
const WORLD := 95.0
const EYE := 1.7
const SHIRTS := ["ef4444", "3b82f6", "22c55e", "f59e0b", "a855f7", "ec4899", "14b8a6", "f97316", "64748b", "facc15"]
const NPC_NAMES := ["Kevin", "Jonas", "Lea", "Mo", "Sophie", "Finn", "Aylin", "Ben", "Mia", "Luca", "Emre", "Nele"]
const CHEERS := ["GEHT KLAR", "Aura +1000", "Sheeesh", "W", "Krank", "Wie macht der das", "Sigma"]
const LAUGHS := ["HAHAHA", "Bro hustet", "Aura minus unendlich", "Peinlich", "L", "Was war das", "Reingeschissen"]

# Welt
var colliders: Array = [] # [x, z, r]
var env: Environment
var sun: DirectionalLight3D
var sky_mat: ProceduralSkyMaterial
var cam: Camera3D
var vape_node: Node3D
var vape_body_mat: StandardMaterial3D
var vape_stripe_mat: StandardMaterial3D
var vape_led_mat: StandardMaterial3D
var smoke
var sfx
var net
var npcs: Array = []
var remotes := {}
var clouds: Array = []

# Spieler
var ppos := Vector3(0, 0, 18)
var vy := 0.0
var yaw := PI
var pitch := 0.0
var on_ground := true
var bob := 0.0
var shake := 0.0

# Spielstand
var aura := 0.0
var best := 0.0
var farmed := 0.0
var vape_i := 0
var streak := 0
var tricks_n := 0
var fails := 0
var inhaling := false
var inhale_start := 0
var cooldown_until := 0
var charge := 0.0
var combo: Array = []
var combo_bad := false
var challenge = null
var smog := 0.0
var smog_hold := 0
var time_offset := 0 # nur für Selbsttest

# Ablauf / Netz
var playing := false
var online := false
var my_id := -1
var my_name := "Spieler"
var server_url := DEFAULT_SERVER
var board_top: Array = []
var send_t := 0.0
var selftest := false
var test_server := ""
var ui := {}
var chat_open := false
# Touch-Steuerung (Handy/Tablet)
var touch_mode := false
var touch_move := Vector2.ZERO # x = seitlich, y = vorwärts
var joy_index := -1
var joy_origin := Vector2.ZERO
var look_index := -1
var touch_buttons: Array = []


# ═══════════════════════════ Start ═══════════════════════════
func _ready() -> void:
	randomize()
	for a in OS.get_cmdline_user_args():
		if a == "--selftest":
			selftest = true
		elif a.begins_with("--server="):
			test_server = a.substr(9)
	_load()
	_build_env()
	_build_world()
	_build_player()
	_build_npcs()
	smoke = Smoke.new()
	smoke.cam = cam
	add_child(smoke)
	sfx = Sfx.new()
	add_child(sfx)
	net = Net.new()
	net.opened.connect(_on_net_open)
	net.closed.connect(_on_net_closed)
	net.message.connect(_on_net_message)
	_build_ui()
	touch_mode = not selftest and (OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available())
	if touch_mode:
		_build_touch_ui()
		ui.book.visible = false
	equip(mini(vape_i, VAPES.size() - 1))
	new_challenge()
	render_hud()
	if selftest:
		_run_selftest()
	else:
		show_menu(true)


func now_ms() -> int:
	return Time.get_ticks_msec() + time_offset


func vape() -> Dictionary:
	return VAPES[vape_i]


func unlocked(i: int) -> bool:
	return farmed >= float(VAPES[i]["need"])


func avail() -> Array:
	return TRICKS.filter(func(t): return int(t["tier"]) <= vape_i)


func fmt(v: float) -> String:
	var neg := v < 0
	var s := str(int(abs(round(v))))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if neg else "") + s + out


# ═══════════════════════════ Speichern ═══════════════════════════
func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		aura = float(d.get("aura", 0))
		best = float(d.get("best", 0))
		farmed = float(d.get("farmed", 0))
		vape_i = int(d.get("vape", 0))
		my_name = str(d.get("name", my_name))
		server_url = str(d.get("server", server_url))


func save() -> void:
	if selftest:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"aura": round(aura), "best": round(best), "farmed": round(farmed), "vape": vape_i, "name": my_name, "server": server_url}))


# ═══════════════════════════ Welt ═══════════════════════════
func mat(c: Color, rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func add_mesh(m: Mesh, mt: Material, p: Vector3, parent: Node = self, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mt
	mi.position = p
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _build_env() -> void:
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("3b82f6")
	sky_mat.sky_horizon_color = Color("a5d8ff")
	sky_mat.ground_horizon_color = Color("a5d8ff")
	sky_mat.ground_bottom_color = Color("4d7c3f")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("bcd7f0")
	env.fog_density = 0.006
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.light_energy = 1.4
	sun.light_color = Color("fff1d6")
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	sun.rotation_degrees = Vector3(-50, 35, 0)
	add_child(sun)


func _grass_tex() -> ImageTexture:
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	img.fill(Color("5f9b45"))
	for i in 4000:
		var f := randf_range(0.82, 1.15)
		img.set_pixel(randi() % 128, randi() % 128, Color(0.27 * f, 0.53 * f, 0.22 * f))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _window_tex(base: Color) -> ImageTexture:
	var img := Image.create(64, 128, false, Image.FORMAT_RGB8)
	img.fill(base)
	for yy in range(8, 120, 15):
		for xx in range(6, 58, 14):
			img.fill_rect(Rect2i(xx, yy, 8, 10), Color("fde68a") if randf() < 0.35 else Color("1e3a5f"))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func ring_mesh(r1: float, r2: float, segs: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segs:
		var a0 := float(i) / segs * TAU
		var a1 := float(i + 1) / segs * TAU
		var p00 := Vector3(cos(a0) * r1, 0, sin(a0) * r1)
		var p01 := Vector3(cos(a0) * r2, 0, sin(a0) * r2)
		var p10 := Vector3(cos(a1) * r1, 0, sin(a1) * r1)
		var p11 := Vector3(cos(a1) * r2, 0, sin(a1) * r2)
		for v in [p00, p11, p01, p00, p10, p11]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	return st.commit()


func free_spot(x: float, z: float, r: float) -> bool:
	if abs(x) < 4 or abs(z) < 4 or Vector2(x, z).length() < 9:
		return false
	if Vector2((x + 52) / 1.4, z - 48).length() < 19:
		return false
	if abs(Vector2(x, z).length() - 28.5) < 4:
		return false
	for c in colliders:
		if Vector2(c[0] - x, c[1] - z).length() < c[2] + r + 1.5:
			return false
	return true


func _build_world() -> void:
	# Boden mit Gras-Textur
	var grass := _grass_tex()
	var gm := mat(Color.WHITE, 1.0)
	gm.albedo_texture = grass
	gm.uv1_scale = Vector3(70, 70, 1)
	gm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var gplane := PlaneMesh.new()
	gplane.size = Vector2(WORLD * 2 + 120, WORLD * 2 + 120)
	add_mesh(gplane, gm, Vector3.ZERO, self, false)

	# Wege
	var path_m := mat(Color("c9b48a"), 1.0)
	for rot in [0.0, PI / 2]:
		var pm := PlaneMesh.new()
		pm.size = Vector2(5, WORLD * 2)
		var mi := add_mesh(pm, path_m, Vector3(0, 0.01, 0), self, false)
		mi.rotation.y = rot
	var ring_m := mat(Color("c9b48a"), 1.0)
	ring_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	add_mesh(ring_mesh(26.0, 31.0, 72), ring_m, Vector3(0, 0.012, 0), self, false)

	# Brunnen
	var basin := CylinderMesh.new()
	basin.top_radius = 5.0
	basin.bottom_radius = 5.4
	basin.height = 0.8
	add_mesh(basin, mat(Color("9ca3af"), 0.7), Vector3(0, 0.4, 0))
	var water := CylinderMesh.new()
	water.top_radius = 4.6
	water.bottom_radius = 4.6
	water.height = 0.1
	var wm := mat(Color("38bdf8"), 0.08, 0.2)
	add_mesh(water, wm, Vector3(0, 0.78, 0), self, false)
	var pillar := CylinderMesh.new()
	pillar.top_radius = 0.5
	pillar.bottom_radius = 0.8
	pillar.height = 3.0
	add_mesh(pillar, mat(Color("d1d5db"), 0.6), Vector3(0, 1.9, 0))
	var ball := SphereMesh.new()
	ball.radius = 0.9
	ball.height = 1.8
	add_mesh(ball, mat(Color("e5e7eb"), 0.5), Vector3(0, 3.6, 0))
	colliders.append([0.0, 0.0, 5.6])

	# See
	var lake := CylinderMesh.new()
	lake.top_radius = 16.0
	lake.bottom_radius = 16.0
	lake.height = 0.06
	lake.radial_segments = 48
	var lk := add_mesh(lake, mat(Color("2b8fd6"), 0.05, 0.3), Vector3(-52, 0.02, 48), self, false)
	lk.scale = Vector3(1.4, 1, 1)
	for i in 18:
		var a := float(i) / 18.0 * TAU
		colliders.append([-52.0 + cos(a) * 21.0 * 0.62, 48.0 + sin(a) * 15.0 * 0.62, 6.5])

	# Bäume (MultiMesh)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.22
	trunk.bottom_radius = 0.32
	trunk.height = 2.4
	trunk.radial_segments = 7
	var leaf := SphereMesh.new()
	leaf.radius = 1.6
	leaf.height = 3.0
	leaf.radial_segments = 8
	leaf.rings = 5
	var pine := CylinderMesh.new()
	pine.top_radius = 0.0
	pine.bottom_radius = 1.5
	pine.height = 4.0
	pine.radial_segments = 8
	var trunks: Array = []
	var leaves: Array = []
	var pines: Array = []
	var tries := 0
	while trunks.size() < 170 and tries < 4000:
		tries += 1
		var x := randf_range(-WORLD + 3, WORLD - 3)
		var z := randf_range(-WORLD + 3, WORLD - 3)
		if not free_spot(x, z, 1.2):
			continue
		var s := randf_range(0.8, 1.5)
		var ry := randf() * TAU
		trunks.append(Transform3D(Basis(Vector3.UP, ry).scaled(Vector3(s, s, s)), Vector3(x, 1.2 * s, z)))
		if randf() < 0.6:
			leaves.append([Transform3D(Basis(Vector3.UP, ry).scaled(Vector3(s * randf_range(0.9, 1.25), s * randf_range(0.85, 1.1), s * randf_range(0.9, 1.25))), Vector3(x, 3.3 * s, z)), Color.from_hsv(randf_range(0.24, 0.33), randf_range(0.5, 0.65), randf_range(0.38, 0.52))])
		else:
			pines.append(Transform3D(Basis(Vector3.UP, ry).scaled(Vector3(s, s, s)), Vector3(x, 4.2 * s, z)))
		colliders.append([x, z, 0.45 * s])
	_multimesh(trunk, mat(Color("7c4a2d")), trunks, [])
	var lt: Array = []
	var lc: Array = []
	for e in leaves:
		lt.append(e[0])
		lc.append(e[1])
	var lm := mat(Color.WHITE, 0.85)
	lm.vertex_color_use_as_albedo = true
	_multimesh(leaf, lm, lt, lc)
	_multimesh(pine, mat(Color("2f6b3a"), 0.9), pines, [])

	# Felsen
	for i in 40:
		var x := randf_range(-WORLD, WORLD)
		var z := randf_range(-WORLD, WORLD)
		var s := randf_range(0.5, 1.6)
		if not free_spot(x, z, s):
			continue
		var rock := SphereMesh.new()
		rock.radius = s
		rock.height = s * 1.4
		rock.radial_segments = 6
		rock.rings = 3
		var r := add_mesh(rock, mat(Color("8b8f96"), 0.95), Vector3(x, s * 0.35, z))
		r.rotation = Vector3(randf(), randf() * TAU, 0)
		colliders.append([x, z, s * 0.9])

	# Bänke + Laternen
	for i in 8:
		var a := float(i) / 8.0 * TAU + PI / 8
		var bp := Vector3(cos(a) * 33.5, 0, sin(a) * 33.5)
		var bench := Node3D.new()
		add_child(bench)
		bench.position = bp
		var wood := mat(Color("9a6b3f"))
		var seat := BoxMesh.new()
		seat.size = Vector3(2.4, 0.12, 0.6)
		add_mesh(seat, wood, Vector3(0, 0.5, 0), bench)
		var back := BoxMesh.new()
		back.size = Vector3(2.4, 0.6, 0.1)
		add_mesh(back, wood, Vector3(0, 0.85, 0.28), bench)
		var leg := BoxMesh.new()
		leg.size = Vector3(0.1, 0.5, 0.5)
		add_mesh(leg, mat(Color("222222")), Vector3(-1, 0.25, 0), bench)
		add_mesh(leg, mat(Color("222222")), Vector3(1, 0.25, 0), bench)
		bench.look_at(Vector3(0, 0, 0))
		colliders.append([bp.x, bp.z, 1.3])
		var la := (float(i) + 0.5) / 8.0 * TAU + PI / 8
		var lp := Vector3(cos(la) * 32, 0, sin(la) * 32)
		var pole := CylinderMesh.new()
		pole.top_radius = 0.07
		pole.bottom_radius = 0.1
		pole.height = 4.0
		add_mesh(pole, mat(Color("1f2937"), 0.4, 0.6), lp + Vector3(0, 2, 0))
		var bulb := SphereMesh.new()
		bulb.radius = 0.28
		bulb.height = 0.56
		var bm := mat(Color("fff3c4"))
		bm.emission_enabled = true
		bm.emission = Color("ffd27a")
		bm.emission_energy_multiplier = 2.0
		add_mesh(bulb, bm, lp + Vector3(0, 4.1, 0), self, false)
		colliders.append([lp.x, lp.z, 0.3])

	# Häuser
	var cols := ["e5d3b3", "c7b8a3", "d4a59a", "9fb4c7", "b8c4a8", "e0c1a0"]
	for side in 4:
		for i in range(-4, 5):
			var w := randf_range(9, 13)
			var dpt := randf_range(8, 11)
			var h := randf_range(9, 24)
			var off := i * 21 + randf_range(-2, 2)
			var along := side % 2 == 0
			var x: float = off if along else (1.0 if side == 1 else -1.0) * (WORLD + dpt / 2 + 2)
			var z: float = (1.0 if side == 0 else -1.0) * (WORLD + dpt / 2 + 2) if along else off
			var bm := BoxMesh.new()
			bm.size = Vector3(w if along else dpt, h, dpt if along else w)
			var base := Color(cols[(side * 9 + i + 40) % cols.size()])
			var win := _window_tex(base)
			var wmat := mat(Color.WHITE, 0.85)
			wmat.albedo_texture = win
			wmat.uv1_scale = Vector3(round(w / 4.0), round(h / 8.0), 1)
			add_mesh(bm, wmat, Vector3(x, h / 2, z))
			var roof := BoxMesh.new()
			roof.size = bm.size + Vector3(0.4, -bm.size.y + 0.5, 0.4)
			add_mesh(roof, mat(Color("5b5b66")), Vector3(x, h + 0.25, z))

	# Wolken
	var cm := mat(Color(1, 1, 1), 1.0)
	cm.emission_enabled = true
	cm.emission = Color("99a3b3")
	cm.emission_energy_multiplier = 0.35
	for i in 14:
		var g := Node3D.new()
		add_child(g)
		g.position = Vector3(randf_range(-200, 200), randf_range(55, 80), randf_range(-200, 200))
		for j in 6:
			var sm := SphereMesh.new()
			sm.radius = randf_range(4, 8)
			sm.height = sm.radius * 1.2
			add_mesh(sm, cm, Vector3(randf_range(-10, 10), randf_range(-2, 2), randf_range(-5, 5)), g, false)
		clouds.append(g)


func _multimesh(m: Mesh, mt: Material, xforms: Array, colors: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors.size() > 0
	mm.mesh = m
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if colors.size() > 0:
			mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mt
	add_child(mmi)


func _human(shirt: Color, skin: Color, hair: Color) -> Node3D:
	var g := Node3D.new()
	var legs := CylinderMesh.new()
	legs.top_radius = 0.2
	legs.bottom_radius = 0.18
	legs.height = 0.85
	add_mesh(legs, mat(Color("1f2a44")), Vector3(0, 0.43, 0), g)
	var body := CapsuleMesh.new()
	body.radius = 0.28
	body.height = 1.1
	add_mesh(body, mat(shirt), Vector3(0, 1.18, 0), g)
	var head := SphereMesh.new()
	head.radius = 0.21
	head.height = 0.42
	add_mesh(head, mat(skin, 0.7), Vector3(0, 1.78, 0), g)
	var hr := SphereMesh.new()
	hr.radius = 0.22
	hr.height = 0.3
	hr.is_hemisphere = true
	add_mesh(hr, mat(hair), Vector3(0, 1.82, 0), g)
	var eye := SphereMesh.new()
	eye.radius = 0.03
	eye.height = 0.06
	add_mesh(eye, mat(Color("111111")), Vector3(-0.07, 1.8, -0.19), g, false)
	add_mesh(eye, mat(Color("111111")), Vector3(0.07, 1.8, -0.19), g, false)
	return g


func _label3d(text: String, y: float, size := 64) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = Vector3(0, y, 0)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = size
	l.outline_size = 14
	l.pixel_size = 0.006
	return l


func _build_npcs() -> void:
	var skins := ["f1c27d", "e0ac69", "c68642", "8d5524", "ffdbac"]
	var hairs := ["2b1b0e", "111111", "8b5a2b", "d4a017"]
	for i in 12:
		var x := 0.0
		var z := 0.0
		var tries := 0
		while tries < 200:
			tries += 1
			var a := randf() * TAU
			var r := randf_range(12, 70)
			x = cos(a) * r
			z = sin(a) * r
			if free_spot(x, z, 1):
				break
		var g := _human(Color(SHIRTS[i % SHIRTS.size()]), Color(skins[i % 5]), Color(hairs[i % 4]))
		g.position = Vector3(x, 0, z)
		add_child(g)
		var bubble := _label3d("", 2.5, 56)
		bubble.visible = false
		g.add_child(bubble)
		colliders.append([x, z, 0.5])
		npcs.append({"node": g, "bubble": bubble, "until": 0, "hype": 0.0, "phase": randf() * 6.0})


func say(npc_or_remote: Dictionary, text: String, col: Color) -> void:
	var b: Label3D = npc_or_remote["bubble"]
	b.text = text
	b.modulate = col
	b.visible = true
	npc_or_remote["until"] = Time.get_ticks_msec() + 2200


func _build_player() -> void:
	cam = Camera3D.new()
	cam.fov = 72
	cam.near = 0.05
	cam.far = 600
	cam.rotation_order = EULER_ORDER_YXZ
	add_child(cam)
	vape_node = Node3D.new()
	cam.add_child(vape_node)
	vape_body_mat = mat(Color("8b5cf6"), 0.22, 0.75)
	vape_stripe_mat = mat(Color("22d3ee"), 0.3, 0.5)
	vape_stripe_mat.emission_enabled = true
	vape_led_mat = StandardMaterial3D.new()
	vape_led_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vape_led_mat.albedo_color = Color("22d3ee")
	var body := BoxMesh.new()
	body.size = Vector3(0.045, 0.11, 0.022)
	add_mesh(body, vape_body_mat, Vector3.ZERO, vape_node, false)
	var stripe := BoxMesh.new()
	stripe.size = Vector3(0.047, 0.035, 0.024)
	add_mesh(stripe, vape_stripe_mat, Vector3(0, -0.02, 0), vape_node, false)
	var mouth := BoxMesh.new()
	mouth.size = Vector3(0.025, 0.03, 0.014)
	add_mesh(mouth, mat(Color("1f2937"), 0.35, 0.3), Vector3(0, 0.07, 0), vape_node, false)
	var led := SphereMesh.new()
	led.radius = 0.005
	led.height = 0.01
	add_mesh(led, vape_led_mat, Vector3(0, -0.035, 0.0115), vape_node, false)
	var skin := mat(Color("e0ac69"), 0.7)
	var palm := BoxMesh.new()
	palm.size = Vector3(0.05, 0.06, 0.035)
	add_mesh(palm, skin, Vector3(0.03, -0.045, -0.012), vape_node, false)
	var thumb := CapsuleMesh.new()
	thumb.radius = 0.012
	thumb.height = 0.06
	var th := add_mesh(thumb, skin, Vector3(-0.018, -0.005, 0.02), vape_node, false)
	th.rotation.z = 0.5
	var sleeve := CylinderMesh.new()
	sleeve.top_radius = 0.036
	sleeve.bottom_radius = 0.044
	sleeve.height = 0.28
	var sl := add_mesh(sleeve, mat(Color("111827")), Vector3(0.07, -0.22, -0.02), vape_node, false)
	sl.rotation.z = 0.3
	vape_node.position = Vector3(0.21, -0.2, -0.42)
	vape_node.rotation = Vector3(0.15, -0.35, 0.1)


# ═══════════════════════════ Oberfläche ═══════════════════════════
func _font() -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Segoe UI", "Noto Sans", "DejaVu Sans", "Liberation Sans", "Arial", "Helvetica"])
	var sym := SystemFont.new()
	sym.font_names = PackedStringArray(["Segoe UI Symbol", "DejaVu Sans", "Noto Sans Symbols 2", "Arial Unicode MS"])
	var emo := SystemFont.new()
	emo.font_names = PackedStringArray(["Segoe UI Emoji", "Noto Color Emoji", "Apple Color Emoji"])
	f.fallbacks = [sym, emo]
	return f


func lbl(text: String, size: int, col := Color.WHITE, parent: Node = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("outline_size", 6)
	if parent:
		parent.add_child(l)
	return l


func panel(parent: Node, bg := Color(0.04, 0.03, 0.08, 0.66), border := Color(0.75, 0.52, 0.99, 0.35)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	return p


func btn(text: String, cb: Callable, parent: Node) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 18)
	b.custom_minimum_size = Vector2(0, 42)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new()
	th.default_font = _font()
	root.theme = th
	layer.add_child(root)
	ui.root = root

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	root.add_child(margin)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	# obere Zeile
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	var leftc := VBoxContainer.new()
	leftc.add_theme_constant_override("separation", 10)
	top.add_child(leftc)
	var ap := panel(leftc)
	var av := VBoxContainer.new()
	ap.add_child(av)
	ui.aura = lbl("0", 34, Color("c084fc"), av)
	ui.rank = lbl("NPC", 15, Color.WHITE, av)
	ui.sub = lbl("", 12, Color(1, 1, 1, 0.75), av)
	ui.vape = lbl("", 12, Color("a5f3fc"), av)
	ui.vbar = ProgressBar.new()
	ui.vbar.show_percentage = false
	ui.vbar.custom_minimum_size = Vector2(300, 6)
	av.add_child(ui.vbar)
	ui.book = panel(leftc)
	ui.book_txt = RichTextLabel.new()
	ui.book_txt.bbcode_enabled = true
	ui.book_txt.fit_content = true
	ui.book_txt.custom_minimum_size = Vector2(400, 0)
	ui.book_txt.scroll_active = false
	ui.book_txt.add_theme_font_size_override("normal_font_size", 13)
	ui.book_txt.add_theme_font_size_override("bold_font_size", 13)
	ui.book_txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.book.add_child(ui.book_txt)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	var rightc := VBoxContainer.new()
	rightc.add_theme_constant_override("separation", 10)
	top.add_child(rightc)
	var cp := panel(rightc, Color(0.04, 0.03, 0.08, 0.66), Color(0.98, 0.8, 0.08, 0.45))
	var cv := VBoxContainer.new()
	cp.add_child(cv)
	lbl("AURA-CHALLENGE x2", 11, Color(1, 1, 1, 0.8), cv)
	ui.chal = lbl("-", 18, Color("facc15"), cv)
	ui.net = lbl("Offline", 12, Color(1, 1, 1, 0.7), cv)
	ui.board = panel(rightc)
	ui.board_txt = RichTextLabel.new()
	ui.board_txt.bbcode_enabled = true
	ui.board_txt.fit_content = true
	ui.board_txt.custom_minimum_size = Vector2(280, 0)
	ui.board_txt.scroll_active = false
	ui.board_txt.add_theme_font_size_override("normal_font_size", 14)
	ui.board_txt.add_theme_font_size_override("bold_font_size", 14)
	ui.board.add_child(ui.board_txt)
	ui.board.visible = false

	var vspace := Control.new()
	vspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vspace.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(vspace)

	# untere Zeile: Chat links, Ladebalken Mitte
	var bottom := HBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(bottom)
	var chatc := VBoxContainer.new()
	chatc.custom_minimum_size = Vector2(420, 0)
	chatc.alignment = BoxContainer.ALIGNMENT_END
	chatc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(chatc)
	ui.chatlog = VBoxContainer.new()
	ui.chatlog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chatc.add_child(ui.chatlog)
	ui.chatin = LineEdit.new()
	ui.chatin.placeholder_text = "Nachricht … (Enter senden, Esc abbrechen)"
	ui.chatin.max_length = 120
	ui.chatin.visible = false
	ui.chatin.text_submitted.connect(_send_chat)
	chatc.add_child(ui.chatin)
	var sp1 := Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(sp1)
	var mid := VBoxContainer.new()
	mid.custom_minimum_size = Vector2(520, 0)
	mid.alignment = BoxContainer.ALIGNMENT_END
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(mid)
	ui.combo = lbl("", 30, Color("bef264"), mid)
	ui.combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.bar = ProgressBar.new()
	ui.bar.custom_minimum_size = Vector2(520, 18)
	ui.bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("c084fc")
	fill.set_corner_radius_all(9)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.12)
	bg.set_corner_radius_all(9)
	ui.bar.add_theme_stylebox_override("fill", fill)
	ui.bar.add_theme_stylebox_override("background", bg)
	ui.fill = fill
	mid.add_child(ui.bar)
	ui.hint = lbl("F halten zum Ziehen", 13, Color(1, 1, 1, 0.8), mid)
	ui.hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(sp2)
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(420, 0)
	balance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(balance)

	# Fadenkreuz
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cc)
	var cross := ColorRect.new()
	cross.color = Color(1, 1, 1, 0.8)
	cross.custom_minimum_size = Vector2(5, 5)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(cross)

	# Pop-ups (kein Container, damit Tweens die Position bewegen dürfen)
	ui.pops = Control.new()
	ui.pops.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.pops.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ui.pops)

	# Fail-Blitz
	ui.flash = ColorRect.new()
	ui.flash.color = Color(0.94, 0.27, 0.27, 0)
	ui.flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ui.flash)

	# Shop
	ui.shop_wrap = CenterContainer.new()
	ui.shop_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(ui.shop_wrap)
	ui.shop = panel(ui.shop_wrap, Color(0.08, 0.05, 0.14, 0.96))
	ui.shop.custom_minimum_size = Vector2(740, 0)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 8)
	ui.shop.add_child(sv)
	lbl("Vape-Shop", 30, Color("c084fc"), sv)
	ui.shop_sub = lbl("", 13, Color(1, 1, 1, 0.75), sv)
	ui.shop_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.shop_list = VBoxContainer.new()
	ui.shop_list.add_theme_constant_override("separation", 8)
	sv.add_child(ui.shop_list)
	btn("Zurück ins Spiel (B)", close_shop, sv)
	ui.shop_wrap.visible = false

	# Menü
	ui.menu_wrap = CenterContainer.new()
	ui.menu_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(ui.menu_wrap)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.02, 0.1, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	root.move_child(dim, root.get_child_count() - 2)
	ui.dim = dim
	ui.menu = panel(ui.menu_wrap, Color(0.06, 0.03, 0.12, 0.94))
	ui.menu.custom_minimum_size = Vector2(640, 0)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 10)
	ui.menu.add_child(mv)
	var title := lbl("AURA FARM", 64, Color("c084fc"), mv)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var st := lbl("Lauf durch den Park, zieh an deiner Vape und hit die Tricks. Wer reinscheißt, verliert Aura.", 15, Color(1, 1, 1, 0.85), mv)
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl("Dein Name", 13, Color(1, 1, 1, 0.7), mv)
	ui.name_in = LineEdit.new()
	ui.name_in.text = my_name
	ui.name_in.max_length = 16
	mv.add_child(ui.name_in)
	lbl("Server (für Online)", 13, Color(1, 1, 1, 0.7), mv)
	ui.server_in = LineEdit.new()
	ui.server_in.text = server_url
	mv.add_child(ui.server_in)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	mv.add_child(row)
	var b1 := btn("Online spielen", start_game.bind(true), row)
	b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var b2 := btn("Offline spielen", start_game.bind(false), row)
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui.menu_status = lbl("", 14, Color("fca5a5"), mv)
	ui.menu_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var keys := lbl("WASD + Maus laufen · Shift sprinten · Leertaste springen\nF / rechte Maustaste HALTEN = ziehen · dabei Pfeiltasten = Trick-Kombo · loslassen = ausblasen\nB Vape-Shop · H Trickbuch · Tab Bestenliste · Enter Chat · Esc Menü", 13, Color(1, 1, 1, 0.75), mv)
	keys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var bq := btn("Beenden", get_tree().quit, mv)
	bq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl("v" + VERSION + " · Nur ein Spiel – echtes Dampfen ist nicht gesund.", 11, Color(1, 1, 1, 0.45), mv)


# ═══════════════════════════ Touch (Handy) ═══════════════════════════
func _round_box(col: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	return sb


func _tbtn(text: String, size: Vector2, parent: Control, col := Color(1, 1, 1, 0.16)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", int(size.y * 0.42))
	b.add_theme_stylebox_override("normal", _round_box(col, int(size.y / 2)))
	b.add_theme_stylebox_override("hover", _round_box(col, int(size.y / 2)))
	b.add_theme_stylebox_override("pressed", _round_box(Color(0.75, 0.52, 0.99, 0.55), int(size.y / 2)))
	parent.add_child(b)
	touch_buttons.append(b)
	return b


func _build_touch_ui() -> void:
	var t := Control.new()
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.visible = false
	ui.root.add_child(t)
	ui.touch = t
	# Joystick (wird an der Daumenposition angezeigt)
	ui.joy_base = Panel.new()
	ui.joy_base.size = Vector2(150, 150)
	ui.joy_base.add_theme_stylebox_override("panel", _round_box(Color(1, 1, 1, 0.12), 75))
	ui.joy_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.joy_base.visible = false
	t.add_child(ui.joy_base)
	ui.joy_knob = Panel.new()
	ui.joy_knob.size = Vector2(64, 64)
	ui.joy_knob.add_theme_stylebox_override("panel", _round_box(Color(0.75, 0.52, 0.99, 0.6), 32))
	ui.joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.joy_knob.visible = false
	t.add_child(ui.joy_knob)
	# rechte Seite: Pfeil-Kreuz + ZIEHEN + Springen
	var right := VBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.grow_vertical = Control.GROW_DIRECTION_BEGIN
	right.offset_right = -24
	right.offset_bottom = -24
	right.add_theme_constant_override("separation", 10)
	right.alignment = BoxContainer.ALIGNMENT_END
	t.add_child(right)
	var pad := GridContainer.new()
	pad.columns = 3
	pad.add_theme_constant_override("h_separation", 6)
	pad.add_theme_constant_override("v_separation", 6)
	right.add_child(pad)
	var arrows := ["", U, "", L, "", R, "", D, ""]
	for a in arrows:
		if a == "":
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(64, 64)
			gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pad.add_child(gap)
		else:
			var b := _tbtn(a, Vector2(64, 64), pad)
			b.button_down.connect(push_key.bind(a))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(row)
	var jump := _tbtn("Sprung", Vector2(96, 96), row)
	jump.button_down.connect(_touch_jump)
	var pull := _tbtn("ZIEHEN", Vector2(132, 132), row, Color(0.66, 0.33, 0.97, 0.45))
	pull.button_down.connect(start_inhale)
	pull.button_up.connect(release)
	# oben Mitte: Shop, Trickbuch, Bestenliste, Menü
	var topbar := HBoxContainer.new()
	topbar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	topbar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	topbar.offset_top = 16
	topbar.add_theme_constant_override("separation", 8)
	t.add_child(topbar)
	_tbtn("Shop", Vector2(92, 44), topbar).pressed.connect(open_shop)
	_tbtn("Tricks", Vector2(92, 44), topbar).pressed.connect(func(): ui.book.visible = not ui.book.visible)
	_tbtn("Liste", Vector2(92, 44), topbar).pressed.connect(_toggle_board)
	_tbtn("Menü", Vector2(92, 44), topbar).pressed.connect(show_menu.bind(true))


func _touch_jump() -> void:
	if on_ground and playing:
		vy = 5.2
		on_ground = false


func _toggle_board() -> void:
	render_board()
	ui.board.visible = not ui.board.visible


func _on_touch_button(pos: Vector2) -> bool:
	for b in touch_buttons:
		if b.is_visible_in_tree() and b.get_global_rect().has_point(pos):
			return true
	return false


func _input(event: InputEvent) -> void:
	if not touch_mode or not playing:
		return
	var st := event as InputEventScreenTouch
	if st:
		var half := get_viewport().get_visible_rect().size.x * 0.45
		if st.pressed:
			if _on_touch_button(st.position):
				return
			if st.position.x < half and joy_index == -1:
				joy_index = st.index
				joy_origin = st.position
				ui.joy_base.position = st.position - ui.joy_base.size / 2
				ui.joy_knob.position = st.position - ui.joy_knob.size / 2
				ui.joy_base.visible = true
				ui.joy_knob.visible = true
			elif look_index == -1:
				look_index = st.index
		else:
			if st.index == joy_index:
				joy_index = -1
				touch_move = Vector2.ZERO
				ui.joy_base.visible = false
				ui.joy_knob.visible = false
			elif st.index == look_index:
				look_index = -1
		return
	var sd := event as InputEventScreenDrag
	if sd:
		if sd.index == joy_index:
			var d := (sd.position - joy_origin).limit_length(70.0)
			ui.joy_knob.position = joy_origin + d - ui.joy_knob.size / 2
			touch_move = Vector2(d.x / 70.0, -d.y / 70.0)
		elif sd.index == look_index:
			yaw -= sd.relative.x * 0.005
			pitch = clampf(pitch - sd.relative.y * 0.005, -1.45, 1.45)


func pop(text: String, sub: String, col: Color) -> void:
	var v := VBoxContainer.new()
	v.anchor_left = 0.0
	v.anchor_right = 1.0
	v.anchor_top = 0.3
	v.anchor_bottom = 0.3
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var a := lbl(text, 36, col, v)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if sub != "":
		var b := lbl(sub, 18, col, v)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.pops.add_child(v)
	v.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(v, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(v, "position:y", v.position.y - 20, 0.15)
	tw.tween_interval(1.1)
	tw.tween_property(v, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(v, "position:y", v.position.y - 80, 0.5)
	tw.tween_callback(v.queue_free)


func render_hud() -> void:
	ui.aura.text = "✦ " + fmt(aura)
	var r := "NPC"
	for e in RANKS:
		if aura >= float(e[0]):
			r = e[1]
	ui.rank.text = r
	ui.sub.text = "Streak %dx · Tricks %d · Fails %d · Rekord %s" % [streak, tricks_n, fails, fmt(best)]
	var v := vape()
	var next = null
	for i in range(1, VAPES.size()):
		if not unlocked(i):
			next = VAPES[i]
			break
	ui.vape.text = "%s · Aura x%d · %s · B = Shop" % [v["name"], v["mult"], ("nächste: %s bei %s" % [next["name"], fmt(next["need"])]) if next else "MAX"]
	if next:
		var prev: float = VAPES[VAPES.find(next) - 1]["need"]
		ui.vbar.value = clamp((farmed - prev) / (float(next["need"]) - prev) * 100.0, 0, 100)
	else:
		ui.vbar.value = 100
	ui.chal.text = ("%s  %s" % [challenge["name"], " ".join(challenge["keys"])]) if challenge else "-"


func render_book() -> void:
	var s := "[b]TRICKBUCH · H[/b]\n"
	for t in TRICKS:
		var lock: bool = int(t["tier"]) > vape_i
		var col := "#facc15" if t == challenge else ("#777777" if lock else "#ffffff")
		if lock:
			s += "[color=%s]%s  · · ·  (%s)[/color]\n" % [col, t["name"], VAPES[int(t["tier"])]["name"]]
		else:
			s += "[color=%s]%s[/color]  [color=#a5f3fc]%s[/color]  [color=#999999]ab %d%% · %s[/color]\n" % [col, t["name"], " ".join(t["keys"]), t["min"], fmt(float(t["aura"]) * float(vape()["mult"]))]
	ui.book_txt.text = s


func render_board() -> void:
	var s := "[b]ONLINE[/b]\n"
	var list: Array = [{"name": my_name + " (du)", "aura": aura}]
	for id in remotes:
		list.append({"name": remotes[id]["name"], "aura": remotes[id]["aura"]})
	list.sort_custom(func(a, b): return a["aura"] > b["aura"])
	for e in list:
		s += "%s  [color=#c084fc]✦ %s[/color]\n" % [e["name"], fmt(e["aura"])]
	s += "\n[b]BESTENLISTE[/b]\n"
	var i := 1
	for e in board_top:
		s += "%d. %s  [color=#facc15]✦ %s[/color]\n" % [i, e["name"], fmt(e["aura"])]
		i += 1
	ui.board_txt.text = s


func render_combo() -> void:
	if not inhaling:
		ui.combo.text = ""
		return
	var typed := "".join(combo)
	var match_name := ""
	for t in avail():
		if "".join(t["keys"]) == typed:
			match_name = t["name"]
	ui.combo.text = " ".join(combo) + ("   " + match_name if match_name != "" and not combo_bad else "")
	ui.combo.add_theme_color_override("font_color", Color("f87171") if combo_bad else Color("bef264"))


func _on_equip_pressed(i: int) -> void:
	equip(i)
	sfx.melody([523.0, 784.0, 1046.0], 0.08)
	render_shop()


func render_shop() -> void:
	ui.shop_sub.text = "Insgesamt gefarmt: ✦ %s · freischalten über gefarmte Aura (Fails nehmen dir keine Vape weg)" % fmt(farmed)
	for c in ui.shop_list.get_children():
		c.queue_free()
	for i in VAPES.size():
		var v: Dictionary = VAPES[i]
		var ok := unlocked(i)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var sw := ColorRect.new()
		sw.color = v["color"] if ok else Color(0.3, 0.3, 0.3)
		sw.custom_minimum_size = Vector2(40, 40)
		row.add_child(sw)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var tr: Array = []
		for t in TRICKS:
			if int(t["tier"]) == i and i > 0:
				tr.append(t["name"])
		lbl(("" if ok else "[gesperrt] ") + v["name"], 17, Color.WHITE if ok else Color(1, 1, 1, 0.5), info)
		var d := "Aura x%d · Rauch x%s%s" % [v["mult"], str(v["cloud"]), (" · neuer Trick: " + ", ".join(tr)) if tr.size() else ""]
		lbl(d, 12, Color(1, 1, 1, 0.7), info)
		lbl(v["desc"] if ok else "Freischalten bei ✦ %s gefarmt (noch %s)" % [fmt(v["need"]), fmt(float(v["need"]) - farmed)], 12, Color(1, 1, 1, 0.6), info)
		var b := Button.new()
		b.custom_minimum_size = Vector2(130, 40)
		b.text = "Ausgerüstet" if i == vape_i else ("Ausrüsten" if ok else "Gesperrt")
		b.disabled = not ok or i == vape_i
		b.pressed.connect(_on_equip_pressed.bind(i))
		row.add_child(b)
		ui.shop_list.add_child(row)


# ═══════════════════════════ Menü / Ablauf ═══════════════════════════
func show_menu(on: bool) -> void:
	ui.menu_wrap.visible = on
	ui.dim.visible = on
	if touch_mode and on:
		ui.touch.visible = false
	if on:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		playing = false
		if inhaling:
			inhaling = false
			sfx.inhale_stop()
			render_combo()


func start_game(want_online: bool) -> void:
	my_name = ui.name_in.text.strip_edges()
	if my_name == "":
		my_name = "Spieler"
	server_url = ui.server_in.text.strip_edges()
	save()
	if want_online and not net.is_open():
		ui.menu_status.add_theme_color_override("font_color", Color("fde68a"))
		ui.menu_status.text = "Verbinde mit " + server_url + " …"
		var err: int = net.connect_to(server_url)
		if err != OK:
			ui.menu_status.add_theme_color_override("font_color", Color("fca5a5"))
			ui.menu_status.text = "Ungültige Server-Adresse (Fehler %d)" % err
		return # Spiel startet, sobald "welcome" kommt
	if not want_online and net.is_open():
		net.close()
		_clear_remotes()
		online = false
	_enter_game()


func _enter_game() -> void:
	ui.menu_wrap.visible = false
	ui.dim.visible = false
	ui.menu_status.text = ""
	playing = true
	if touch_mode:
		ui.touch.visible = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	render_hud()


func open_shop() -> void:
	render_shop()
	ui.shop_wrap.visible = true
	if touch_mode:
		ui.touch.visible = false
	playing = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if inhaling:
		inhaling = false
		sfx.inhale_stop()
		render_combo()


func close_shop() -> void:
	ui.shop_wrap.visible = false
	_enter_game()


func equip(i: int) -> void:
	if not unlocked(i):
		return
	vape_i = i
	var v := vape()
	smoke.cloud = v["cloud"]
	vape_body_mat.albedo_color = v["color"]
	vape_stripe_mat.albedo_color = v["accent"]
	vape_stripe_mat.emission = v["accent"] * 0.5
	vape_node.scale = Vector3.ONE * float(v["scale"])
	if challenge and int(challenge["tier"]) > i:
		new_challenge()
	save()
	render_book()
	render_hud()


func new_challenge() -> void:
	var pool := avail().filter(func(t): return t != challenge)
	challenge = pool[randi() % pool.size()]
	render_book()


# ═══════════════════════════ Tricks ═══════════════════════════
func spectators() -> int:
	var c := 0
	for n in npcs:
		if n["node"].position.distance_to(ppos) < 12:
			c += 1
	for id in remotes:
		if remotes[id]["node"].position.distance_to(ppos) < 14:
			c += 2 # echte Mitspieler zählen doppelt
	return c


func add_aura(gain: float) -> void:
	var before := 0
	for i in VAPES.size():
		if unlocked(i):
			before = i
	aura += gain
	farmed += gain
	var after := 0
	for i in VAPES.size():
		if unlocked(i):
			after = i
	if after > before:
		get_tree().create_timer(0.9).timeout.connect(_announce_vape.bind(after))


func _announce_vape(i: int) -> void:
	pop("Neue Vape: " + VAPES[i]["name"] + "!", "Drück B für den Shop", Color("facc15"))
	sfx.melody([523.0, 659.0, 784.0, 1046.0, 1318.0, 1568.0], 0.1)


func start_inhale() -> void:
	if inhaling or now_ms() < cooldown_until or not playing:
		return
	inhaling = true
	charge = 0.0
	inhale_start = now_ms()
	combo = []
	combo_bad = false
	sfx.inhale_start()
	render_combo()
	ui.hint.text = "Kombo mit Pfeiltasten eingeben, dann F loslassen"


func push_key(k: String) -> void:
	if not inhaling:
		return
	combo.append(k)
	var typed := "".join(combo)
	var ok := false
	for t in avail():
		if "".join(t["keys"]).begins_with(typed):
			ok = true
	if not ok:
		combo_bad = true
	sfx.key(ok and not combo_bad)
	render_combo()


func update_charge() -> void:
	if not inhaling:
		return
	charge = float(now_ms() - inhale_start) / 1000.0 * float(vape()["rate"])
	sfx.inhale_update(charge)
	if charge >= 100.0:
		inhaling = false
		sfx.inhale_stop()
		cooldown_until = now_ms() + 1600
		combo = []
		render_combo()
		fail("Zu lange gezogen – Hustenanfall", true)
		ui.hint.text = "F halten zum Ziehen"


func mouth() -> Vector3:
	return cam.global_transform * Vector3(0, -0.09, -0.12)


func release() -> void:
	if not inhaling:
		return
	update_charge()
	if not inhaling:
		return
	inhaling = false
	sfx.inhale_stop()
	var ch := charge
	var st := ch / 100.0
	var v := vape()
	var typed := "".join(combo)
	var trick = null
	for t in avail():
		if "".join(t["keys"]) == typed:
			trick = t
	cooldown_until = now_ms() + 1100
	var fwd := -cam.global_transform.basis.z
	if typed == "":
		effect("plain", st, mouth(), fwd, true)
		sfx.exhale(st)
		smog = minf(1.0, smog + 0.0015 * smoke.cloud * smoke.cloud * st)
		var gain := roundf(ch * 0.15 * float(v["mult"]))
		if gain > 0:
			add_aura(gain)
			pop("+" + fmt(gain) + " ✦", "Wolke", Color("c084fc"))
		_net_trick("plain", st, fwd)
	elif combo_bad or trick == null:
		fail("Kombo verkackt")
	elif ch < float(trick["min"]):
		effect("plain", st * 0.6, mouth(), fwd, true)
		fail("Zu wenig gezogen für %s (%d/%d%%)" % [trick["name"], int(ch), trick["min"]])
	else:
		effect(trick["id"], st, mouth(), fwd, true)
		sfx.exhale(st * 0.7)
		smog = minf(1.0, smog + 0.004 * smoke.cloud * smoke.cloud * st)
		streak += 1
		tricks_n += 1
		var crowd := spectators()
		var mult := (1.0 + minf(2.0, streak * 0.1)) * (1.0 + minf(1.0, crowd * 0.25)) * (2.0 if trick == challenge else 1.0) * (0.8 + st * 0.4) * float(v["mult"])
		var gain := roundf(float(trick["aura"]) * mult)
		add_aura(gain)
		var big: bool = trick == challenge or int(trick["tier"]) > 0 or gain > 400 * float(v["mult"])
		var parts: Array = []
		if trick == challenge:
			parts.append("CHALLENGE x2")
		if streak > 1:
			parts.append("Streak %d" % streak)
		if crowd > 0:
			parts.append("%d Zuschauer" % crowd)
		if int(v["mult"]) > 1:
			parts.append("%s x%d" % [v["name"], v["mult"]])
		pop("%s! +%s ✦" % [trick["name"], fmt(gain)], " · ".join(parts), Color("facc15") if big else Color("c084fc"))
		get_tree().create_timer(0.25).timeout.connect(func(): sfx.win(big))
		for n in npcs:
			var dist: float = n["node"].position.distance_to(ppos)
			if dist < 12 or trick["id"] == "citynebel":
				n["hype"] = 1.4
				say(n, CHEERS[randi() % CHEERS.size()] if trick["id"] != "citynebel" else "WO IST DIE STADT", Color("c4b5fd"))
		if trick == challenge:
			new_challenge()
		_net_trick(trick["id"], st, fwd)
	if aura > best:
		best = aura
	save()
	combo = []
	render_combo()
	render_hud()
	ui.hint.text = "F halten zum Ziehen"


func fail(reason: String, cough := false) -> void:
	var loss := roundf((60.0 + streak * 15.0) * float(vape()["mult"]) + maxf(0.0, aura) * 0.05)
	aura -= loss
	streak = 0
	fails += 1
	if cough:
		effect("cough", 1.0, mouth(), -cam.global_transform.basis.z, true)
		sfx.cough()
	else:
		sfx.exhale(0.2)
	get_tree().create_timer(0.7 if cough else 0.15).timeout.connect(func(): sfx.fail())
	pop("Reingeschissen −" + fmt(loss) + " ✦", reason, Color("f87171"))
	ui.flash.color.a = 0.35
	create_tween().tween_property(ui.flash, "color:a", 0.0, 0.4)
	shake = 0.35
	for n in npcs:
		if n["node"].position.distance_to(ppos) < 12:
			say(n, LAUGHS[randi() % LAUGHS.size()], Color("fca5a5"))
	save()
	render_hud()


## Rauch-Effekte. origin = Mund, fwd = Blickrichtung. Für Mitspieler wird smoke.cloud vorher gesetzt.
func effect(id: String, st: float, m: Vector3, fwd: Vector3, local: bool) -> void:
	fwd = fwd.normalized()
	var r := fwd.cross(Vector3.UP).normalized()
	if r.length() < 0.1:
		r = Vector3.RIGHT
	var u := r.cross(fwd).normalized()
	var s = smoke
	match id:
		"plain":
			for i in s.n(10 + st * 60):
				s.emit(m, fwd * randf_range(1.2, 2.6) * (0.5 + st) + r * randf_range(-0.4, 0.4) + u * randf_range(-0.2, 0.3), {"delay": i * 0.012, "s1": randf_range(0.6, 1.3) * (0.6 + st), "life": randf_range(1.8, 3.0)})
		"cough":
			for k in 3:
				for i in 16:
					s.emit(m, fwd * randf_range(2, 4) + r * randf_range(-1.2, 1.2) + u * randf_range(-0.8, 0.8), {"delay": k * 0.28 + i * 0.006, "s1": randf_range(0.4, 0.9), "life": randf_range(1.0, 1.8), "a": 0.45, "tint": 0.82})
		"ghost":
			var c := m + fwd * 0.35
			for i in 40 + int(st * 30):
				s.emit(c + Vector3(randf_range(-0.05, 0.05), randf_range(-0.05, 0.05), randf_range(-0.05, 0.05)), fwd * randf_range(0.25, 0.6) + Vector3(randf_range(-0.15, 0.15), randf_range(-0.1, 0.15), randf_range(-0.15, 0.15)), {"delay": i * 0.004, "s0": 0.1, "s1": randf_range(0.35, 0.55), "life": 2.4, "a": 0.75, "rise": 0.02, "drag": 2.5, "pull": 1.0, "pull_to": m})
		"orings":
			for k in 3 + int(round(st * 2)):
				for i in 26:
					var a := float(i) / 26.0 * TAU
					var dir := r * cos(a) + u * sin(a)
					s.emit(m + dir * 0.04, fwd * 1.1 + dir * 0.22, {"delay": k * 0.55, "s0": 0.05, "s1": 0.22, "life": 3.4, "a": 0.8, "drag": 0.35, "rise": 0.03})
		"french":
			for i in 70:
				var d := i * 0.02
				s.emit(m + fwd * 0.03, u * -0.5 + fwd * 0.35, {"delay": d, "s0": 0.05, "s1": 0.18, "life": 0.7, "a": 0.7, "drag": 0.5, "rise": 0.0})
				s.emit(m + fwd * 0.12 - u * 0.12, u * 0.9 - fwd * 0.25, {"delay": d + 0.35, "s0": 0.06, "s1": 0.22, "life": 1.1, "a": 0.6, "drag": 0.6, "rise": 0.4})
		"dragon":
			for side: float in [-1.0, 1.0, 0.0]:
				for i in 45:
					s.emit(m + r * side * 0.025, fwd * (1.4 if side != 0.0 else 2.2) + r * side * 1.9 + u * randf_range(-0.1, 0.2), {"delay": i * 0.015, "s0": 0.06, "s1": randf_range(0.4, 0.8), "life": 2.2, "a": 0.6})
		"tornado":
			var c := m + fwd * 1.6
			c.y = maxf(0.2, c.y - 1.0)
			for i in 160:
				s.emit(c, Vector3.ZERO, {"delay": i * 0.012, "s0": 0.12, "s1": 0.4, "life": 2.6, "a": 0.6, "swirl": [c.x, c.y, c.z, 0.35, i * 0.7, 7.0, 0.0, 0.9]})
		"jelly":
			effect("orings", 0.2, m, fwd, local)
			for i in 40:
				s.emit(m, fwd * randf_range(2.2, 2.8) + Vector3(randf_range(-0.05, 0.05), randf_range(-0.05, 0.05), randf_range(-0.05, 0.05)), {"delay": 0.9 + i * 0.01, "s0": 0.05, "s1": 0.35, "life": 2.5, "a": 0.75, "drag": 1.4, "tint": 1.0})
		"bane":
			for i in 180:
				s.emit(m + fwd * 0.05 + r * randf_range(-0.06, 0.06), -u * randf_range(0.6, 1.1) + fwd * randf_range(0.3, 0.7) + r * randf_range(-0.3, 0.3), {"delay": i * 0.011, "s0": 0.1, "s1": randf_range(0.6, 1.2), "life": 3.2, "a": 0.65, "drag": 0.9, "rise": -0.05})
		"wall":
			for i in s.n(160):
				s.emit(m, fwd * randf_range(1.5, 2.5) + r * randf_range(-1, 1) * 2.2 + u * randf_range(-0.3, 0.8), {"delay": i * 0.008, "s1": randf_range(0.8, 1.4), "life": 4.0, "a": 0.6, "drag": 0.9, "rise": 0.05})
		"dtornado":
			for side: float in [-1.0, 1.0]:
				var c := m + fwd * 2.2 + r * side * 1.2
				c.y = maxf(0.2, c.y - 1.2)
				for i in s.n(130):
					s.emit(c, Vector3.ZERO, {"delay": i * 0.012, "s0": 0.15, "s1": 0.5, "life": 3.0, "a": 0.6, "swirl": [c.x, c.y, c.z, 0.5, i * 0.7, 7.0 * side, 0.0, 1.2]})
		"mushroom":
			var c := m + fwd * 3.0
			c.y = 0.1
			for i in s.n(120):
				s.emit(c + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3)), Vector3(randf_range(-0.2, 0.2), randf_range(2.5, 3.2), randf_range(-0.2, 0.2)), {"delay": i * 0.01, "s0": 0.3, "s1": 1.0, "life": 2.2, "a": 0.65, "drag": 0.4, "rise": 0.0})
			for i in s.n(160):
				var a := randf() * TAU
				s.emit(c + Vector3(0, 5, 0), Vector3(cos(a) * randf_range(1.5, 3), randf_range(-0.2, 0.6), sin(a) * randf_range(1.5, 3)), {"delay": 1.0 + i * 0.006, "s0": 0.5, "s1": randf_range(1.6, 2.6), "life": 5.0, "a": 0.6, "drag": 0.6, "rise": 0.02})
			if local:
				smog = minf(1.0, smog + 0.12)
		"fogbank":
			var p0 := Vector3(m.x, 0, m.z)
			for i in s.n(260):
				var a := randf() * TAU
				var dd := randf_range(1, 9)
				s.emit(p0 + Vector3(cos(a) * dd, randf_range(0.2, 1.2), sin(a) * dd), Vector3(cos(a) * randf_range(0.3, 1), randf_range(0, 0.15), sin(a) * randf_range(0.3, 1)), {"delay": i * 0.008, "s0": 0.8, "s1": randf_range(2.5, 4), "life": 7.0, "a": 0.55, "drag": 0.3, "rise": 0.01})
			smog = minf(1.0, smog + (0.35 if local else 0.15))
		"citynebel":
			effect("mushroom", 1.0, m, fwd, local)
			effect("fogbank", 1.0, m, fwd, local)
			smog = 1.0
			smog_hold = Time.get_ticks_msec() + 20000


# ═══════════════════════════ Netzwerk ═══════════════════════════
func _on_net_open() -> void:
	net.send({"t": "hello", "name": my_name, "ver": VERSION})


func _on_net_closed(reason: String) -> void:
	var was := online
	online = false
	_clear_remotes()
	ui.net.text = "Offline"
	if was:
		pop("Verbindung getrennt", reason, Color("f87171"))
	elif ui.menu_wrap.visible:
		ui.menu_status.add_theme_color_override("font_color", Color("fca5a5"))
		ui.menu_status.text = "Keine Verbindung: " + reason
	if selftest:
		print("SELFTEST NETZ: Verbindung beendet: ", reason)


func _on_net_message(m: Dictionary) -> void:
	match str(m.get("t", "")):
		"welcome":
			online = true
			my_id = int(m["id"])
			my_name = str(m["name"])
			board_top = m.get("board", [])
			for p in m.get("players", []):
				_add_remote(p)
			ui.net.text = "Online als %s · %d Spieler" % [my_name, remotes.size() + 1]
			if not selftest:
				_enter_game()
				pop("Online!", "%d andere Spieler im Park" % remotes.size(), Color("67e8f9"))
		"join":
			_add_remote(m)
			chat_line("%s ist beigetreten" % m["name"], Color("67e8f9"))
		"leave":
			var id := int(m["id"])
			if remotes.has(id):
				chat_line("%s ist gegangen" % remotes[id]["name"], Color(1, 1, 1, 0.6))
				remotes[id]["node"].queue_free()
				remotes.erase(id)
		"states":
			for p in m.get("list", []):
				var id := int(p["id"])
				if id == my_id:
					continue
				if not remotes.has(id):
					_add_remote(p)
				var rr: Dictionary = remotes[id]
				rr["target"] = Vector3(p["p"][0], p["p"][1], p["p"][2])
				rr["yaw"] = float(p["yaw"])
				rr["aura"] = float(p["aura"])
				rr["vape"] = int(p["vape"])
				rr["label"].text = "%s\n✦ %s" % [rr["name"], fmt(rr["aura"])]
		"trick":
			var id := int(m.get("from", -1))
			if not remotes.has(id):
				return
			var rr: Dictionary = remotes[id]
			var pp: Array = m.get("p", [0, 0, 0])
			var dd: Array = m.get("dir", [0, 0, -1])
			var own_cloud: float = smoke.cloud
			smoke.cloud = float(VAPES[clampi(int(m.get("vape", 0)), 0, VAPES.size() - 1)]["cloud"])
			effect(str(m["id"]), float(m.get("st", 0.5)), Vector3(pp[0], pp[1], pp[2]), Vector3(dd[0], dd[1], dd[2]), false)
			smoke.cloud = own_cloud
			if rr["node"].position.distance_to(ppos) < 20 and str(m["id"]) != "plain":
				say(rr, "Trick!", Color("facc15"))
		"board":
			board_top = m.get("top", [])
			if ui.board.visible:
				render_board()
		"chat":
			chat_line("%s: %s" % [m["name"], m["msg"]], Color.WHITE)
		"error":
			ui.menu_status.text = str(m.get("msg", "Fehler"))


func _add_remote(p: Dictionary) -> void:
	var id := int(p["id"])
	if id == my_id or remotes.has(id):
		return
	var g := _human(Color(SHIRTS[id % SHIRTS.size()]), Color("e0ac69"), Color("2b1b0e"))
	var pos := Vector3(p["p"][0], p["p"][1], p["p"][2])
	g.position = pos
	add_child(g)
	var label := _label3d("%s\n✦ %s" % [p["name"], fmt(float(p.get("aura", 0)))], 2.35, 48)
	label.modulate = Color("c4b5fd")
	g.add_child(label)
	var bubble := _label3d("", 2.95, 56)
	bubble.visible = false
	g.add_child(bubble)
	remotes[id] = {"node": g, "label": label, "bubble": bubble, "until": 0, "name": str(p["name"]), "aura": float(p.get("aura", 0)), "vape": int(p.get("vape", 0)), "target": pos, "yaw": float(p.get("yaw", 0))}
	ui.net.text = "Online als %s · %d Spieler" % [my_name, remotes.size() + 1]


func _clear_remotes() -> void:
	for id in remotes:
		remotes[id]["node"].queue_free()
	remotes.clear()


func _net_trick(id: String, st: float, fwd: Vector3) -> void:
	if not online:
		return
	var m := mouth()
	net.send({"t": "trick", "id": id, "st": st, "p": [m.x, m.y, m.z], "dir": [fwd.x, fwd.y, fwd.z]})


func chat_line(text: String, col: Color) -> void:
	var l := lbl(text, 15, col, ui.chatlog)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(420, 0)
	while ui.chatlog.get_child_count() > 7:
		ui.chatlog.get_child(0).queue_free()
	var tw := create_tween()
	tw.tween_interval(10.0)
	tw.tween_property(l, "modulate:a", 0.0, 1.0)


func _send_chat(text: String) -> void:
	text = text.strip_edges()
	if text != "" and online:
		net.send({"t": "chat", "msg": text})
	elif text != "":
		chat_line("(offline) " + text, Color(1, 1, 1, 0.6))
	ui.chatin.text = ""
	ui.chatin.visible = false
	chat_open = false
	if not touch_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	playing = true


# ═══════════════════════════ Eingabe ═══════════════════════════
func _unhandled_input(event: InputEvent) -> void:
	var mm := event as InputEventMouseMotion
	if mm and playing and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= mm.relative.x * 0.0022
		pitch = clampf(pitch - mm.relative.y * 0.0022, -1.45, 1.45)
		return
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				start_inhale()
			else:
				release()
		elif mb.pressed and playing and not touch_mode and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	var ke := event as InputEventKey
	if ke == null or ke.echo:
		return
	var k := ke.keycode
	if chat_open:
		if ke.pressed and k == KEY_ESCAPE:
			ui.chatin.visible = false
			chat_open = false
			playing = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if not ke.pressed:
		if k == KEY_F:
			release()
		elif k == KEY_TAB:
			ui.board.visible = false
		return
	if k == KEY_ESCAPE:
		if ui.shop_wrap.visible:
			close_shop()
		elif ui.menu_wrap.visible:
			_enter_game()
		else:
			show_menu(true)
	elif k == KEY_B and (playing or ui.shop_wrap.visible):
		if ui.shop_wrap.visible:
			close_shop()
		else:
			open_shop()
	elif not playing:
		return
	elif k == KEY_F:
		start_inhale()
	elif KEYMAP.has(k):
		push_key(KEYMAP[k])
	elif k == KEY_H:
		ui.book.visible = not ui.book.visible
	elif k == KEY_TAB:
		render_board()
		ui.board.visible = true
	elif k == KEY_ENTER or k == KEY_T:
		chat_open = true
		playing = false
		ui.chatin.visible = true
		ui.chatin.grab_focus()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif k == KEY_SPACE and on_ground:
		vy = 5.2
		on_ground = false


# ═══════════════════════════ Spielschleife ═══════════════════════════
func collide(p: Vector3) -> Vector3:
	for c in colliders:
		var dx: float = p.x - c[0]
		var dz: float = p.z - c[1]
		var d := sqrt(dx * dx + dz * dz)
		var mn: float = c[2] + 0.35
		if d < mn and d > 0.0001:
			p.x = c[0] + dx / d * mn
			p.z = c[1] + dz / d * mn
	var lim := WORLD - 1.5
	p.x = clamp(p.x, -lim, lim)
	p.z = clamp(p.z, -lim, lim)
	return p


func _process(dt: float) -> void:
	dt = min(dt, 0.05)
	net.poll()
	var tnow := Time.get_ticks_msec()
	# Bewegung
	if playing:
		var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
		var right := Vector3(-fwd.z, 0, fwd.x)
		var mv := Vector3.ZERO
		if Input.is_key_pressed(KEY_W):
			mv += fwd
		if Input.is_key_pressed(KEY_S):
			mv -= fwd
		if Input.is_key_pressed(KEY_D):
			mv += right
		if Input.is_key_pressed(KEY_A):
			mv -= right
		if touch_move.length() > 0.05:
			mv += fwd * touch_move.y + right * touch_move.x
		if mv.length_squared() > 0:
			var sprint := Input.is_key_pressed(KEY_SHIFT) and not inhaling
			var speed := 7.5 if sprint else (2.6 if inhaling else 4.4)
			ppos += mv.normalized() * speed * dt * clampf(mv.length(), 0.0, 1.0) if touch_move.length() > 0.05 else mv.normalized() * speed * dt
			ppos = collide(ppos)
			if on_ground:
				bob += dt * speed * 2.1
	vy -= 14.0 * dt
	ppos.y += vy * dt
	if ppos.y <= 0:
		ppos.y = 0
		vy = 0
		on_ground = true
	update_charge()
	ui.bar.value = charge if inhaling else max(0.0, ui.bar.value - dt * 120.0)
	ui.fill.bg_color = Color("67e8f9").lerp(Color("ef4444"), clamp(charge / 100.0, 0, 1)) if inhaling else Color("c084fc")

	# Kamera
	shake = max(0.0, shake - dt)
	var bob_y := sin(bob) * 0.045
	var bob_x := cos(bob * 0.5) * 0.03
	cam.position = Vector3(ppos.x, ppos.y + EYE + bob_y - (0.02 if inhaling else 0.0), ppos.z)
	cam.rotation = Vector3(pitch + randf_range(-1, 1) * shake * 0.05, yaw + randf_range(-1, 1) * shake * 0.05, 0)

	# Vape in der Hand
	var target := Vector3(0.05, -0.12, -0.26) if inhaling else Vector3(0.21, -0.2, -0.42)
	vape_node.position = vape_node.position.lerp(target + Vector3(bob_x * 0.4, bob_y * 0.4, 0), min(1.0, dt * 10.0))
	var tr := Vector3(0.75, -0.2, 0.15) if inhaling else Vector3(0.15, -0.35, 0.1)
	vape_node.rotation = vape_node.rotation.lerp(tr, min(1.0, dt * 10.0))
	vape_led_mat.albedo_color = Color.from_hsv(0.83 - charge / 100.0 * 0.83, 1, 1) if inhaling else Color("22d3ee")

	# Smog: viel Rauch hüllt die Stadt ein
	if tnow > smog_hold:
		smog = max(0.0, smog - dt * 0.018)
	env.fog_light_color = Color("bcd7f0").lerp(Color("f4f6f8"), smog)
	env.fog_density = lerp(0.006, 0.22, smog * smog)
	sky_mat.sky_top_color = Color("3b82f6").lerp(Color("f4f6f8"), smog * 0.95)
	sky_mat.sky_horizon_color = Color("a5d8ff").lerp(Color("f4f6f8"), smog)
	sun.light_energy = 1.4 * (1.0 - smog * 0.6)

	# Wolken
	for c in clouds:
		c.position.x += dt * 1.5
		if c.position.x > 240:
			c.position.x = -240

	# NPCs
	for n in npcs:
		var g: Node3D = n["node"]
		if g.position.distance_to(ppos) < 16:
			var want := atan2(-(ppos.x - g.position.x), -(ppos.z - g.position.z))
			g.rotation.y = lerp_angle(g.rotation.y, want, min(1.0, dt * 3.0))
		n["hype"] = max(0.0, float(n["hype"]) - dt)
		g.position.y = abs(sin(tnow / 90.0 + n["phase"])) * 0.35 if n["hype"] > 0 else 0.0
		if n["bubble"].visible and tnow > int(n["until"]):
			n["bubble"].visible = false

	# Mitspieler (weich interpoliert)
	for id in remotes:
		var rr: Dictionary = remotes[id]
		var g: Node3D = rr["node"]
		g.position = g.position.lerp(rr["target"], min(1.0, dt * 10.0))
		g.rotation.y = lerp_angle(g.rotation.y, float(rr["yaw"]), min(1.0, dt * 10.0))
		if rr["bubble"].visible and tnow > int(rr["until"]):
			rr["bubble"].visible = false

	# Zustand senden (10x pro Sekunde)
	if online:
		send_t -= dt
		if send_t <= 0:
			send_t = 0.1
			net.send({"t": "state", "p": [ppos.x, ppos.y, ppos.z], "yaw": yaw, "vape": vape_i, "aura": round(aura), "farmed": round(farmed)})


# ═══════════════════════════ Selbsttest (CI) ═══════════════════════════
func _hold(ms: int) -> void:
	time_offset += ms


func _do_trick(keys: Array, ms: int) -> void:
	start_inhale()
	for k in keys:
		push_key(k)
	_hold(ms)
	release()
	_hold(1200) # Abkühlzeit überspringen


func _check(cond: bool, what: String) -> bool:
	print(("  OK   " if cond else "  FAIL ") + what)
	return cond


func _run_selftest() -> void:
	print("Aura Farm Selbsttest v", VERSION)
	playing = true
	var ok := true
	aura = 0
	farmed = 0
	equip(0)
	await get_tree().process_frame
	_do_trick([U, U, U], 1600)
	ok = _check(tricks_n == 1 and aura > 0, "O-Ringe gibt Aura (%s)" % fmt(aura)) and ok
	_do_trick([L, U], 1000)
	ok = _check(fails == 1, "falsche Kombo = Fail") and ok
	_do_trick([L, L, D, D, R, R], 2500)
	ok = _check(fails == 2, "gesperrte Wolkenwand = Fail") and ok
	start_inhale()
	_hold(4000)
	update_charge()
	ok = _check(fails == 3 and not inhaling, "Hustenanfall bei über 100 %") and ok
	_hold(1700)
	farmed = 1490
	_do_trick([D, U], 1300)
	ok = _check(unlocked(1), "Einweg-Puff ab 1.500 freigeschaltet") and ok
	equip(1)
	ok = _check(vape_i == 1 and smoke.cloud == 1.5, "Vape ausrüsten setzt Rauch-Faktor") and ok
	farmed = 2e7
	equip(6)
	var before := aura
	_do_trick([U, U, D, D, L, R, L, R], 4100)
	ok = _check(aura - before > 100000 and smog >= 1.0, "Stadtnebel mit Wolkenkratzer 9000 (+%s, Smog %.2f)" % [fmt(aura - before), smog]) and ok
	for i in 30:
		await get_tree().process_frame
	ok = _check(smoke.active_count() > 100, "Rauchpartikel aktiv (%d)" % smoke.active_count()) and ok
	if test_server != "":
		print("Verbinde mit ", test_server)
		net.connect_to(test_server)
		var waited := 0.0
		while not online and waited < 8.0:
			await get_tree().create_timer(0.1).timeout
			waited += 0.1
		ok = _check(online and my_id > 0, "Server-Verbindung (id %d)" % my_id) and ok
		if online:
			net.send({"t": "state", "p": [1, 0, 2], "yaw": 0.5, "vape": vape_i, "aura": round(aura), "farmed": round(farmed)})
			net.send({"t": "trick", "id": "tornado", "st": 0.8, "p": [1, 1.6, 2], "dir": [0, 0, -1]})
			await get_tree().create_timer(0.5).timeout
			net.close()
	print("SELFTEST ", "BESTANDEN" if ok else "FEHLGESCHLAGEN")
	get_tree().quit(0 if ok else 1)
