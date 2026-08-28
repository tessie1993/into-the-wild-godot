extends Node
## Global signal hub. Autoloaded as `EventBus`.
## Systems talk through signals so UI, rules, and future animations stay decoupled.

signal turn_started(player_index: int)
signal turn_ended(player_index: int)
signal tile_explored(axial: Vector2i)
signal player_moved(player_index: int, axial: Vector2i)
signal light_changed(player_index: int, value: int)
signal vp_changed(player_index: int, value: int)
signal inventory_changed(player_index: int)
signal message(text: String)
signal rage_changed(value: int)
signal game_won(player_index: int, path: String)
