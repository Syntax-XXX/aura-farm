extends RefCounted
## WebSocket-Client für das Aura-Farm-Protokoll (JSON-Textnachrichten).

signal opened
signal closed(reason: String)
signal message(msg: Dictionary)

var ws := WebSocketPeer.new()
var url := ""
var was_open := false
var active := false


func connect_to(u: String) -> int:
	url = u
	ws = WebSocketPeer.new()
	ws.outbound_buffer_size = 1 << 16
	ws.inbound_buffer_size = 1 << 18
	was_open = false
	active = true
	return ws.connect_to_url(u)


func poll() -> void:
	if not active:
		return
	ws.poll()
	var st := ws.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN:
		if not was_open:
			was_open = true
			opened.emit()
		while ws.get_available_packet_count() > 0:
			var txt := ws.get_packet().get_string_from_utf8()
			var m = JSON.parse_string(txt)
			if m is Dictionary:
				message.emit(m)
	elif st == WebSocketPeer.STATE_CLOSED:
		active = false
		var why := ws.get_close_reason()
		if why == "":
			why = "Verbindung getrennt" if was_open else "Server nicht erreichbar"
		closed.emit(why)


func send(d: Dictionary) -> void:
	if active and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(JSON.stringify(d))


func close() -> void:
	if active:
		ws.close(1000, "tschüss")
	active = false


func is_open() -> bool:
	return active and ws.get_ready_state() == WebSocketPeer.STATE_OPEN
