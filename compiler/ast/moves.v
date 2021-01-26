// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module ast

enum MovementsOfFRLF {
	look_up = 0x01
	look_left = 0x02
	look_right = 0x03
	look_down = 0x04
	walk_down_vslow = 0x08
	walk_up_vslow = 0x09
	walk_left_vslow = 0x0A
	walk_right_vslow = 0x0B
	walk_down_slow = 0x0C
	walk_up_slow = 0x0D
	walk_left_slow = 0x0E
	walk_right_slow = 0x0F
	walk_down = 0x10
	walk_up = 0x11
	walk_left = 0x12
	walk_right = 0x13
	jump_down2 = 0x14
	jump_up2 = 0x15
	jump_left2 = 0x16
	jump_right2 = 0x17
	pause_xshort = 0x18
	pause_vshort = 0x19
	pause_short = 0x1A
	move_pause = 0x1B
	pause_long = 0x1C
	run_down = 0x1D
	run_up = 0x1E
	run_left = 0x1F
	run_right = 0x20
	onspot_down_slow = 0x21
	onspot_up_slow = 0x22
	onspot_left_slow = 0x23
	onspot_right_slow = 0x24
	onspot_down = 0x25
	onspot_up = 0x26
	onspot_left = 0x27
	onspot_right = 0x28
	onspot_down_fast = 0x29
	onspot_up_fast = 0x2A
	onspot_left_fast = 0x2B
	onspot_right_fast = 0x2C
	look_down_delayed = 0x2D
	look_up_delayed = 0x2E
	look_left_delayed = 0x2F
	look_right_delayed = 0x30
	slide_down = 0x31
	slide_up = 0x32
	slide_left = 0x33
	slide_right = 0x34
	run_down_vfast = 0x35
	run_up_vfast = 0x36
	run_left_vfast = 0x37
	run_right_vfast = 0x38
	slide_down_vfast = 0x39
	slide_up_vfast = 0x3A
	slide_left_vfast = 0x3B
	slide_right_vfast = 0x3C
	slide_down2 = 0x3D
	slide_up2 = 0x3E
	slide_left2 = 0x3F
	slide_right2 = 0x40
	slide_down3 = 0x41
	slide_up3 = 0x42
	slide_left3 = 0x43
	slide_right3 = 0x44
	walk_onspot = 0x45
	look_left_jump_down = 0x46
	look_down_jump_up = 0x47
	look_up_jump_left = 0x48
	look_left_jump_right = 0x49
	move_faceplayer = 0x4A
	face_away = 0x4B
	jump_down1 = 0x4E
	jump_up1 = 0x4F
	jump_left1 = 0x50
	jump_right1 = 0x51
	jump_down = 0x52
	jump_up = 0x53
	jump_left = 0x54
	jump_right = 0x55
	jump_downup = 0x56
	jump_updown = 0x57
	jump_leftright = 0x58
	jump_rightleft = 0x59
	face_default = 0x5A
	hide = 0x60
	say_exclamation = 0x62
	say_question = 0x63
	say_equis = 0x64
	say_bang_bang = 0x65
	say_happy = 0x66
	rock_animate = 0x68
	tree_animate = 0x69
	move_end = 0xfe
}

enum MovementsOfRSE {
	hide = 0x54
	show = 0x55
	alert = 0x56
	question = 0x57
	love = 0x58
	pokeball = 0x5A
	pause0 = 0x10
	pause1 = 0x11
	pause2 = 0x12
	pause3 = 0x13
	pause4 = 0x14
	look_down = 0x00
	look_up = 0x01
	look_left = 0x02
	look_right = 0x03
	walk_down_vslow = 0x04
	walk_up_vslow = 0x05
	walk_left_vslow = 0x06
	walk_right_vslow = 0x07
	walk_down_slow = 0x08
	walk_up_slow = 0x09
	walk_left_slow = 0x0A
	walk_right_slow = 0x0B
	walk_down = 0x17
	walk_up = 0x18
	walk_left = 0x15
	walk_right = 0x16
	walk_down_fast = 0x2D
	walk_up_fast = 0x2E
	walk_left_fast = 0x2F
	walk_right_fast = 0x30
	run_down = 0x35
	run_up = 0x36
	run_left = 0x37
	run_right = 0x38
	run_down_fast = 0x7e
	run_up_fast = 0x7f
	run_left_fast = 0x80
	run_right_fast = 0x81
	move_end = 0xfe
}

pub const movements_of_frlf = {
		'look_up':              MovementsOfFRLF.look_up
		'look_left':            MovementsOfFRLF.look_left
		'look_right':           MovementsOfFRLF.look_right
		'look_down':            MovementsOfFRLF.look_down
		'walk_down_vslow':      MovementsOfFRLF.walk_down_vslow
		'walk_up_vslow':        MovementsOfFRLF.walk_up_vslow
		'walk_left_vslow':      MovementsOfFRLF.walk_left_vslow
		'walk_right_vslow':     MovementsOfFRLF.walk_right_vslow
		'walk_down_slow':       MovementsOfFRLF.walk_down_slow
		'walk_up_slow':         MovementsOfFRLF.walk_up_slow
		'walk_left_slow':       MovementsOfFRLF.walk_left_slow
		'walk_right_slow':      MovementsOfFRLF.walk_right_slow
		'walk_down':            MovementsOfFRLF.walk_down
		'walk_up':              MovementsOfFRLF.walk_up
		'walk_left':            MovementsOfFRLF.walk_left
		'walk_right':           MovementsOfFRLF.walk_right
		'jump_down2':           MovementsOfFRLF.jump_down2
		'jump_up2':             MovementsOfFRLF.jump_up2
		'jump_left2':           MovementsOfFRLF.jump_left2
		'jump_right2':          MovementsOfFRLF.jump_right2
		'pause_xshort':         MovementsOfFRLF.pause_xshort
		'pause_vshort':         MovementsOfFRLF.pause_vshort
		'pause_short':          MovementsOfFRLF.pause_short
		'move_pause':           MovementsOfFRLF.move_pause
		'pause_long':           MovementsOfFRLF.pause_long
		'run_down':             MovementsOfFRLF.run_down
		'run_up':               MovementsOfFRLF.run_up
		'run_left':             MovementsOfFRLF.run_left
		'run_right':            MovementsOfFRLF.run_right
		'onspot_down_slow':     MovementsOfFRLF.onspot_down_slow
		'onspot_up_slow':       MovementsOfFRLF.onspot_up_slow
		'onspot_left_slow':     MovementsOfFRLF.onspot_left_slow
		'onspot_right_slow':    MovementsOfFRLF.onspot_right_slow
		'onspot_down':          MovementsOfFRLF.onspot_down
		'onspot_up':            MovementsOfFRLF.onspot_up
		'onspot_left':          MovementsOfFRLF.onspot_left
		'onspot_right':         MovementsOfFRLF.onspot_right
		'onspot_down_fast':     MovementsOfFRLF.onspot_down_fast
		'onspot_up_fast':       MovementsOfFRLF.onspot_up_fast
		'onspot_left_fast':     MovementsOfFRLF.onspot_left_fast
		'onspot_right_fast':    MovementsOfFRLF.onspot_right_fast
		'look_down_delayed':    MovementsOfFRLF.look_down_delayed
		'look_up_delayed':      MovementsOfFRLF.look_up_delayed
		'look_left_delayed':    MovementsOfFRLF.look_left_delayed
		'look_right_delayed':   MovementsOfFRLF.look_right_delayed
		'slide_down':           MovementsOfFRLF.slide_down
		'slide_up':             MovementsOfFRLF.slide_up
		'slide_left':           MovementsOfFRLF.slide_left
		'slide_right':          MovementsOfFRLF.slide_right
		'run_down_vfast':       MovementsOfFRLF.run_down_vfast
		'run_up_vfast':         MovementsOfFRLF.run_up_vfast
		'run_left_vfast':       MovementsOfFRLF.run_left_vfast
		'run_right_vfast':      MovementsOfFRLF.run_right_vfast
		'slide_down_vfast':     MovementsOfFRLF.slide_down_vfast
		'slide_up_vfast':       MovementsOfFRLF.slide_up_vfast
		'slide_left_vfast':     MovementsOfFRLF.slide_left_vfast
		'slide_right_vfast':    MovementsOfFRLF.slide_right_vfast
		'slide_down2':          MovementsOfFRLF.slide_down2
		'slide_up2':            MovementsOfFRLF.slide_up2
		'slide_left2':          MovementsOfFRLF.slide_left2
		'slide_right2':         MovementsOfFRLF.slide_right2
		'slide_down3':          MovementsOfFRLF.slide_down3
		'slide_up3':            MovementsOfFRLF.slide_up3
		'slide_left3':          MovementsOfFRLF.slide_left3
		'slide_right3':         MovementsOfFRLF.slide_right3
		'walk_onspot':          MovementsOfFRLF.walk_onspot
		'look_left_jump_down':  MovementsOfFRLF.look_left_jump_down
		'look_down_jump_up':    MovementsOfFRLF.look_down_jump_up
		'look_up_jump_left':    MovementsOfFRLF.look_up_jump_left
		'look_left_jump_right': MovementsOfFRLF.look_left_jump_right
		'move_faceplayer':      MovementsOfFRLF.move_faceplayer
		'face_away':            MovementsOfFRLF.face_away
		'jump_down1':           MovementsOfFRLF.jump_down1
		'jump_up1':             MovementsOfFRLF.jump_up1
		'jump_left1':           MovementsOfFRLF.jump_left1
		'jump_right1':          MovementsOfFRLF.jump_right1
		'jump_down':            MovementsOfFRLF.jump_down
		'jump_up':              MovementsOfFRLF.jump_up
		'jump_left':            MovementsOfFRLF.jump_left
		'jump_right':           MovementsOfFRLF.jump_right
		'jump_downup':          MovementsOfFRLF.jump_downup
		'jump_updown':          MovementsOfFRLF.jump_updown
		'jump_leftright':       MovementsOfFRLF.jump_leftright
		'jump_rightleft':       MovementsOfFRLF.jump_rightleft
		'face_default':         MovementsOfFRLF.face_default
		'hide':                 MovementsOfFRLF.hide
		'say_exclamation':      MovementsOfFRLF.say_exclamation
		'say_question':         MovementsOfFRLF.say_question
		'say_equis':            MovementsOfFRLF.say_equis
		'say_bang_bang':        MovementsOfFRLF.say_bang_bang
		'say_happy':            MovementsOfFRLF.say_happy
		'rock_animate':         MovementsOfFRLF.rock_animate
		'tree_animate':         MovementsOfFRLF.tree_animate
		'move_end':             MovementsOfFRLF.move_end
	}

pub const movements_of_rse = {
		'hide':             MovementsOfRSE.hide
		'show':             MovementsOfRSE.show
		'alert':            MovementsOfRSE.alert
		'question':         MovementsOfRSE.question
		'love':             MovementsOfRSE.love
		'pokeball':         MovementsOfRSE.pokeball
		'pause0':           MovementsOfRSE.pause0
		'pause1':           MovementsOfRSE.pause1
		'pause2':           MovementsOfRSE.pause2
		'pause3':           MovementsOfRSE.pause3
		'pause4':           MovementsOfRSE.pause4
		'look_down':        MovementsOfRSE.look_down
		'look_up':          MovementsOfRSE.look_up
		'look_left':        MovementsOfRSE.look_left
		'look_right':       MovementsOfRSE.look_right
		'walk_down_vslow':  MovementsOfRSE.walk_down_vslow
		'walk_up_vslow':    MovementsOfRSE.walk_up_vslow
		'walk_left_vslow':  MovementsOfRSE.walk_left_vslow
		'walk_right_vslow': MovementsOfRSE.walk_right_vslow
		'walk_down_slow':   MovementsOfRSE.walk_down_slow
		'walk_up_slow':     MovementsOfRSE.walk_up_slow
		'walk_left_slow':   MovementsOfRSE.walk_left_slow
		'walk_right_slow':  MovementsOfRSE.walk_right_slow
		'walk_down':        MovementsOfRSE.walk_down
		'walk_up':          MovementsOfRSE.walk_up
		'walk_left':        MovementsOfRSE.walk_left
		'walk_right':       MovementsOfRSE.walk_right
		'walk_down_fast':   MovementsOfRSE.walk_down_fast
		'walk_up_fast':     MovementsOfRSE.walk_up_fast
		'walk_left_fast':   MovementsOfRSE.walk_left_fast
		'walk_right_fast':  MovementsOfRSE.walk_right_fast
		'run_down':         MovementsOfRSE.run_down
		'run_up':           MovementsOfRSE.run_up
		'run_left':         MovementsOfRSE.run_left
		'run_right':        MovementsOfRSE.run_right
		'run_down_fast':    MovementsOfRSE.run_down_fast
		'run_up_fast':      MovementsOfRSE.run_up_fast
		'run_left_fast':    MovementsOfRSE.run_left_fast
		'run_right_fast':   MovementsOfRSE.run_right_fast
		'move_end':         MovementsOfRSE.move_end
	}
