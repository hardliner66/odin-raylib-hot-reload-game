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

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

PIXEL_WINDOW_HEIGHT :: 720
MAX_SPEED_X :: 25
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450
ACCELERATION_X_GROUNDED :: 3
ACCELERATION_X_AIR :: 2
ACCELERATION_Y :: 25
FRICTION :: 1.0
GRAVITY :: 0.98
DESIRED_FPS :: 60

Game_Memory :: struct {
	player: Player,
	tileset: rl.Texture,
	sprite_width_tiles: f32,
}

g_mem: ^Game_Memory

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	return {
		zoom = 1, //h/PIXEL_WINDOW_HEIGHT,
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
	handle_input(&g_mem.player, ACCELERATION_X_GROUNDED, ACCELERATION_X_AIR, ACCELERATION_Y)

	g_mem.player.velocity.x = math.clamp(g_mem.player.velocity.x, -MAX_SPEED_X, MAX_SPEED_X)

	if g_mem.player.grounded {
		apply_friction(&g_mem.player, FRICTION)
	} else {
		apply_gravity(&g_mem.player, GRAVITY)
	}

	update_position(&g_mem.player)

	update_state(&g_mem.player)

	if g_mem.player.state == PlayerState.Running && g_mem.player.last_state != PlayerState.Running {
		reset_frame(&g_mem.player)
	}

	animate(&g_mem.player)
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

	for i := 0; i < 100; i+=1 {
		frame_rec_tiles := rl.Rectangle{
			f32((i + 100) % 5) * g_mem.sprite_width_tiles,
			0,
			g_mem.sprite_width_tiles,
			g_mem.sprite_width_tiles,
		}

		rl.DrawTextureRec(
			g_mem.tileset,
			frame_rec_tiles,
			rl.Vector2{f32(i) * g_mem.sprite_width_tiles, 0},
			rl.BROWN,
		)

		rl.DrawRectangleLinesEx(
			rl.Rectangle{
				f32(i) * g_mem.sprite_width_tiles,
				0,
				g_mem.sprite_width_tiles,
				g_mem.sprite_width_tiles,
			},
			1,
			rl.BLACK,)
	}

	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())
	rl.DrawText(fmt.ctprintf("player.position: %v", g_mem.player.position), 5, 5, 8, rl.BLACK)
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

	texture := rl.LoadTexture("assets/main.png")
	sprite_sheet := new_spritesheet(texture, 8, 4, 1)

	tileset := rl.LoadTexture("assets/tiles.png")

	g_mem^ = Game_Memory {
		player = new_player(sprite_sheet),
		tileset = tileset,
		sprite_width_tiles = f32(tileset.width) / 6,
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