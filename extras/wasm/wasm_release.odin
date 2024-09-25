// For making a release exe that does not use hot reload.

package main_release

import "base:runtime"
import rl "../raylib"
import c "core:c"
import "core:mem"
import "core:strings"

IS_WASM :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32

@export
_fltused: c.int = 0

mainArena: mem.Arena
mainData: [mem.Megabyte * 20]byte
temp_allocator: mem.Scratch_Allocator

ctx: runtime.Context

import game "../game"

@export
init :: proc "c" () {
    using rl
    context = runtime.default_context()
    // needed to setup some runtime type information in odin
    #force_no_inline runtime._startup_runtime()

    when IS_WASM {
        mem.arena_init(&mainArena, mainData[:])
        context.allocator = mem.arena_allocator(&mainArena)

        mem.scratch_allocator_init(&temp_allocator, mem.Megabyte * 2)
        context.temp_allocator = mem.scratch_allocator(&temp_allocator)

        TraceLog(rl.TraceLogLevel.INFO, "Setup hardcoded arena allocators")
    }
    ctx = context

	game.game_init_window()
	game.game_init()
}

@export
update :: proc "c" () {
    using rl
    context = ctx
    defer free_all(context.temp_allocator)

	game.game_update()
}

// make game use good GPU on laptops etc

@(export)
NvOptimusEnablement: u32 = 1

@(export)
AmdPowerXpressRequestHighPerformance: i32 = 1