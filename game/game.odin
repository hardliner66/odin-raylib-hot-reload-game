// This file is compiled as part of the `odin.dll` file. It contains the
// procs that `game.exe` will call, such as:
//
// game_init: Sets up the game state
// game_update: Run once per frame
// game_shutdown: Shuts down game and frees memory
// game_memory: Run just before a hot reload, so game.exe has a pointer to the
//		game's memory.
// game_hot_reloaded: Run after a hot reload so that the `g_mem` global variable
//		can be set to whatever pointer it was in the old DLL.
//
// Note: When compiled as part of the release executable this whole package is imported as a normal
// odin package instead of a DLL.

package game

import "core:math/linalg"
import "core:fmt"
import rl "vendor:raylib"

PIXEL_WINDOW_HEIGHT :: 720

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

PlayerState :: enum {
	Idle,
	Running,
	Jumping,
}

Direction :: enum {
	Left,
	Right,
}

Player :: struct {
	position: rl.Vector2,
	velocity: rl.Vector2,
	grounded: bool,
	state: PlayerState,
	last_state: PlayerState,
	sprite_sheet: SpriteSheet,
}

new_player :: proc(sprite_sheet: SpriteSheet) -> Player {
	return Player {
		position = rl.Vector2{0, 0},
		velocity = rl.Vector2{0, 0},
		grounded = true,
		state = PlayerState.Idle,
		last_state = PlayerState.Idle,
		sprite_sheet = sprite_sheet,
	}
}

Game_Memory :: struct {
	player: Player,
	some_number: int,
}

g_mem: ^Game_Memory

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	return {
		zoom = h/PIXEL_WINDOW_HEIGHT,
		target = g_mem.player.position + g_mem.player.sprite_sheet.sprite_size_half,
		offset = { w/2, h/2 },
	}
}

ui_camera :: proc() -> rl.Camera2D {
	return {
		zoom = f32(rl.GetScreenHeight())/PIXEL_WINDOW_HEIGHT,
	}
}

update :: proc() {
	input: rl.Vector2

	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
		input.y -= 1
	}
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
		input.y += 1
	}
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		input.x -= 1
	}
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		input.x += 1
	}

	input = linalg.normalize0(input)
	g_mem.player.position += input * rl.GetFrameTime() * 100
	g_mem.some_number -= 1
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.WHITE)

	rl.BeginMode2D(game_camera())
	rl.DrawTextureRec(
		g_mem.player.sprite_sheet.texture,
		g_mem.player.sprite_sheet.frame_rec,
		g_mem.player.position - rl.Vector2 {
			g_mem.player.sprite_sheet.sprite_size_half.x,
			g_mem.player.sprite_sheet.sprite_size.x,
		},
		rl.BLACK,
	)
	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())
	rl.DrawText(fmt.ctprintf("some_number: %v\nplayer.position: %v", g_mem.some_number, g_mem.player.position), 5, 5, 8, rl.BLACK)
	rl.EndMode2D()

	rl.EndDrawing()
}

@(export)
game_update :: proc() -> bool {
	update()
	draw()
	return !rl.WindowShouldClose()
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(1280, 720, "Odin + Raylib + Hot Reload template!")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(60)
}

@(export)
game_init :: proc() {
	g_mem = new(Game_Memory)

	g_mem^ = Game_Memory {
		some_number = 100,
		player = new_player(new_spritesheet(rl.LoadTexture("assets/main.png"), 8, 4, 1)),
	}

	game_hot_reloaded(g_mem)
}

@(export)
game_shutdown :: proc() {
	free(g_mem)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g_mem
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g_mem = (^Game_Memory)(mem)
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}