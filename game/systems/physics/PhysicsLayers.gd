extends Node
class_name PhysicsLayers

# LLM_HINT: Fonte única de verdade para layers 2D do projeto (1..6).
# Nunca use 1<<N solto em gameplay. Use PhysicsLayers.bit(LAYER).

const WORLD: int = 1
const PLAYER_BODY: int = 2
const ENEMY_BODY: int = 3
const PLAYER_HITBOX: int = 4
const DAMAGE_SOURCE: int = 5
const TRIGGERS: int = 6

static func bit(layer_1_to_32: int) -> int:
	return 1 << (layer_1_to_32 - 1)

static func has(mask: int, layer_1_to_32: int) -> bool:
	return (mask & bit(layer_1_to_32)) != 0

static func overlaps(body: CollisionObject2D, layer_1_to_32: int) -> bool:
	# Checa se o body possui a layer ligada no collision_layer.
	return (body.collision_layer & bit(layer_1_to_32)) != 0
