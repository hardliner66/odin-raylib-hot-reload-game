package game

import "core:math"
import rl "../raylib"

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
	position:     rl.Vector2,
	velocity:     rl.Vector2,
	grounded:     bool,
	state:        PlayerState,
	last_state:   PlayerState,
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

apply_friction :: proc(player: ^Player, friction: f32) {
    if player.velocity.x > 0 {
        player.velocity.x -= friction
        if player.velocity.x < 0 {
            player.velocity.x = 0
        }
    } else if player.velocity.x < 0 {
        player.velocity.x += friction
        if player.velocity.x > 0 {
            player.velocity.x = 0
        }
    }
}

apply_gravity :: proc(player: ^Player, gravity: f32) {
    player.velocity.y += gravity
}

update_position :: proc(player: ^Player) {
    player.position += player.velocity

    player.grounded = player.position.y >= 0
    if player.grounded {
        player.velocity.y = 0
    }

    if player.position.y > 0 {
        player.position.y = 0
    }
}

update_state :: proc(player: ^Player) {
    player.last_state = player.state
    if player.grounded {
        if player.velocity.x != 0 {
            player.state = PlayerState.Running
        } else {
            player.state = PlayerState.Idle
        }
    } else {
        player.state = PlayerState.Jumping
    }
}

handle_input :: proc(player: ^Player, acceleration_x_grounded: f32, acceleration_x_air: f32, acceleration_y: f32) {
    acceleration_x := acceleration_x_grounded if player.grounded else acceleration_x_air
    if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
        player.velocity.x += acceleration_x
    }
    if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
        player.velocity.x -= acceleration_x
    }

    if player.grounded && (rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.W) || rl.IsKeyPressed(.UP)) {
        player.velocity.y = -acceleration_y
    }
}

animate :: proc(player: ^Player) {
    velocity_sign := math.sign(player.velocity.x)
    sprite_sheet_sign := math.sign(player.sprite_sheet.frame_rec.width)
    if velocity_sign != 0 && velocity_sign != sprite_sheet_sign {
        player.sprite_sheet.frame_rec.width *= -1
    }

    switch player.state {
    case PlayerState.Idle: {
        player.sprite_sheet.frame_rec.x = 2 * player.sprite_sheet.sprite_size.x
    }
    case PlayerState.Running: {
        player.sprite_sheet.frame_counter += 1

        if player.sprite_sheet.frame_counter >= (DESIRED_FPS / player.sprite_sheet.frame_speed) {
            player.sprite_sheet.frame_counter = 0
            player.sprite_sheet.current_frame += 1
            if player.sprite_sheet.current_frame > 1 {
                player.sprite_sheet.current_frame = 0
            }
        }
        player.sprite_sheet.frame_rec.x = f32(player.sprite_sheet.current_frame) * player.sprite_sheet.sprite_size.x
    }
    case PlayerState.Jumping: {
        player.sprite_sheet.frame_rec.x = 3 * player.sprite_sheet.sprite_size.x
    }
    }
}

reset_frame :: proc(player: ^Player) {
    reset_frame_sprite_sheet(&player.sprite_sheet)
}