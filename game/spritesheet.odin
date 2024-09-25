package game

import rl "../raylib"

SpriteSheet :: struct {
	texture: rl.Texture,

	sprite_size: rl.Vector2,
	sprite_size_half: rl.Vector2,
	frame_rec: rl.Rectangle,

	frame_speed: i32,
	frame_counter: i32,
	current_frame: i32,
}

new_spritesheet :: proc(texture: rl.Texture, frame_speed: i32, horizontal_sprite_count: f32, vertical_sprite_count: f32) -> SpriteSheet {
	sprite_width := f32(texture.width) / horizontal_sprite_count
	sprite_height := f32(texture.height) / vertical_sprite_count
	return SpriteSheet {
		texture = texture,
		sprite_size = rl.Vector2{sprite_width, sprite_height},
		sprite_size_half = rl.Vector2{sprite_width/2, sprite_height/2},
		frame_rec = rl.Rectangle{0, 0, sprite_width, sprite_height},
		frame_speed = frame_speed,
		frame_counter = 0,
		current_frame = 0,
	}
}

reset_frame_sprite_sheet :: proc(sprite_sheet: ^SpriteSheet) {
	sprite_sheet.frame_counter = 0
	sprite_sheet.current_frame = 0
}