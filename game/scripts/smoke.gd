extends MultiMeshInstance3D
## Eigenes Rauch-Partikelsystem: bis zu MAXP Billboard-Quads in einer MultiMesh.
## Läuft mit dem Compatibility-Renderer (auch Web) und ist schnell genug für dicke Wolken.

const MAXP := 2400

var cam: Camera3D
var cloud := 1.0 # Rauch-Faktor der aktuellen Vape (Größe/Lebensdauer)

var pos := PackedVector3Array()
var vel := PackedVector3Array()
var life := PackedFloat32Array()
var maxl := PackedFloat32Array()
var s0 := PackedFloat32Array()
var s1 := PackedFloat32Array()
var alpha := PackedFloat32Array()
var drag := PackedFloat32Array()
var rise := PackedFloat32Array()
var delay := PackedFloat32Array()
var tint := PackedFloat32Array()
# Wirbel (Tornado)
var sw_on := PackedByteArray()
var sw := PackedFloat32Array() # 8 Werte je Partikel: cx, cy, cz, r, ang, speed, h, up
# Zurückziehen (Ghost)
var pull_after := PackedFloat32Array()
var pull_to := PackedVector3Array()
var idx := 0
var buf := PackedFloat32Array()


func _ready() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.albedo_texture = _soft_texture()
	q.material = mat
	mm.mesh = q
	mm.instance_count = MAXP
	multimesh = mm
	custom_aabb = AABB(Vector3(-600, -50, -600), Vector3(1200, 500, 1200))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Packed-Arrays sind Werttypen – jedes einzeln vergrößern
	pos.resize(MAXP); vel.resize(MAXP); pull_to.resize(MAXP)
	life.resize(MAXP); maxl.resize(MAXP); s0.resize(MAXP); s1.resize(MAXP); alpha.resize(MAXP)
	drag.resize(MAXP); rise.resize(MAXP); delay.resize(MAXP); tint.resize(MAXP); pull_after.resize(MAXP)
	life.fill(1.0)
	maxl.fill(1.0)
	sw_on.resize(MAXP)
	sw.resize(MAXP * 8)
	buf.resize(MAXP * 16)


func _soft_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.5))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 64
	t.height = 64
	return t


## Ein Partikel ausstoßen. o: s0, s1, life, a, drag, rise, delay, tint, swirl (Array[8]), pull (Sekunden), pull_to
func emit(p: Vector3, v: Vector3, o: Dictionary = {}) -> void:
	idx = (idx + 1) % MAXP
	var i := idx
	pos[i] = p
	vel[i] = v
	life[i] = 0.0
	maxl[i] = float(o.get("life", 2.2)) * (1.0 + (cloud - 1.0) * 0.12)
	s0[i] = float(o.get("s0", 0.08))
	s1[i] = float(o.get("s1", 0.9)) * (1.0 + (cloud - 1.0) * 0.45)
	alpha[i] = float(o.get("a", 0.55))
	drag[i] = float(o.get("drag", 1.6))
	rise[i] = float(o.get("rise", 0.25))
	delay[i] = float(o.get("delay", 0.0))
	tint[i] = float(o.get("tint", 0.96))
	pull_after[i] = float(o.get("pull", -1.0))
	pull_to[i] = o.get("pull_to", p)
	if o.has("swirl"):
		sw_on[i] = 1
		var s: Array = o["swirl"]
		for k in 8:
			sw[i * 8 + k] = s[k]
	else:
		sw_on[i] = 0


func n(count: float) -> int:
	return int(roundf(count * minf(2.6, sqrt(cloud))))


func _process(dt: float) -> void:
	if cam == null:
		return
	var b := cam.global_transform.basis
	var bx := b.x
	var by := b.y
	var bz := b.z
	for i in MAXP:
		var o := i * 16
		if delay[i] > 0.0:
			delay[i] -= dt
			_hide(o)
			continue
		if life[i] >= maxl[i]:
			_hide(o)
			continue
		life[i] += dt
		var t := life[i] / maxl[i]
		if t >= 1.0:
			_hide(o)
			continue
		var p := pos[i]
		if pull_after[i] >= 0.0 and life[i] > pull_after[i]:
			var d := pull_to[i] - p
			vel[i] = vel[i].lerp(d * 4.0, minf(1.0, dt * 5.0))
			if d.length() < 0.15:
				life[i] = maxl[i]
		if sw_on[i] == 1:
			var k := i * 8
			sw[k + 4] += dt * sw[k + 5]
			sw[k + 6] += dt * sw[k + 7]
			var r := sw[k + 3] * (0.4 + t)
			p = Vector3(sw[k] + cos(sw[k + 4]) * r, sw[k + 1] + sw[k + 6], sw[k + 2] + sin(sw[k + 4]) * r)
		else:
			var v := vel[i] * exp(-drag[i] * dt)
			v.y += rise[i] * dt
			vel[i] = v
			p += v * dt
		pos[i] = p
		var s := s0[i] + (s1[i] - s0[i]) * sqrt(t)
		var a := alpha[i] * minf(1.0, t * 8.0) * pow(1.0 - t, 1.4)
		var c := tint[i]
		buf[o] = bx.x * s; buf[o + 1] = by.x * s; buf[o + 2] = bz.x * s; buf[o + 3] = p.x
		buf[o + 4] = bx.y * s; buf[o + 5] = by.y * s; buf[o + 6] = bz.y * s; buf[o + 7] = p.y
		buf[o + 8] = bx.z * s; buf[o + 9] = by.z * s; buf[o + 10] = bz.z * s; buf[o + 11] = p.z
		buf[o + 12] = c; buf[o + 13] = c; buf[o + 14] = c + 0.02; buf[o + 15] = a
	multimesh.buffer = buf


func _hide(o: int) -> void:
	for k in 16:
		buf[o + k] = 0.0


func active_count() -> int:
	var c := 0
	for i in MAXP:
		if delay[i] > 0.0 or life[i] < maxl[i]:
			c += 1
	return c
