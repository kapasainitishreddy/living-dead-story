extends "res://main.gd"
# Test-only adapter: record exit requests while keeping the test process alive.
var attempted_exits := 0
func quit_to_desktop():
	attempted_exits += 1
