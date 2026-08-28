class_name QuestEngine
extends RefCounted
## Quest Engine — tracks session common quests and personal guardian quests.
## Handles event-driven progress updates, VP claiming, revoke_vp enforcement,
## and democratic redraw voting per GDD §8.5 & synthesis S1.

var common_quests: Array = []       ## Active 3 common quests [easy, medium, hard]
var _redraw_votes: Dictionary = {}  ## player_index -> bool
var _redraw_caller: int = -1

const COMMON_QUEST_TARGETS: Dictionary = {
	"first_meal": 1,
	"shoreline": 3,
	"craft_gift": 1,
	"deep_step": 1,
	"circle_complete": 2,
	"no_one_hungry": 1,
}


func _init(initial_quests: Array = []) -> void:
	common_quests = initial_quests.duplicate(true)


func set_common_quests(quests: Array) -> void:
	common_quests = quests.duplicate(true)
	_redraw_votes.clear()
	_redraw_caller = -1


## Checks if a player has completed a given quest ID.
func is_completed(p: PlayerState, quest_id: String) -> bool:
	return p.completed_quests.has(quest_id)


## Returns progress dictionary {current: int, target: int, completed: bool, desc: String, name: String, vp: int}
func get_quest_info(quest: Dictionary, p: PlayerState) -> Dictionary:
	var qid := String(quest.get("id", ""))
	var target: int = int(COMMON_QUEST_TARGETS.get(qid, 1))
	var current: int = int(p.quest_progress.get(qid, 0))
	var done := is_completed(p, qid)
	return {
		"id": qid,
		"name": String(quest.get("name", "Unknown Quest")),
		"desc": String(quest.get("desc", "")),
		"difficulty": String(quest.get("difficulty", "common")),
		"vp": int(quest.get("vp", 0)),
		"revoke_vp": bool(quest.get("revoke_vp", false)),
		"current": current,
		"target": target,
		"completed": done,
	}


## Event hook: a tile was explored by player p.
func on_tile_explored(p: PlayerState, tile: IslandTile) -> void:
	if tile.tier == 1:
		p.explored_t1_count += 1
		p.quest_progress["shoreline"] = p.explored_t1_count
		_check_auto_complete(p, "shoreline")


## Event hook: a resource or item was gifted from from_p to to_p.
func on_gift_given(from_p: PlayerState, to_p: PlayerState, item_or_res: String, is_item: bool, all_players_count: int) -> void:
	# 1. First Meal (any resource)
	if not is_item:
		p_add_progress(from_p, "first_meal", 1)
		_check_auto_complete(from_p, "first_meal")

	# 2. Made to be Given (crafted item given away)
	if is_item and from_p.crafted_items_history.has(item_or_res):
		p_add_progress(from_p, "craft_gift", 1)
		_check_auto_complete(from_p, "craft_gift")

	# 3. No One Hungry (gifted to every other player in one round)
	if not from_p.gifted_players_this_round.has(to_p.index):
		from_p.gifted_players_this_round.append(to_p.index)
	if from_p.gifted_players_this_round.size() >= all_players_count - 1 and all_players_count > 1:
		p_add_progress(from_p, "no_one_hungry", 1)
		_check_auto_complete(from_p, "no_one_hungry")


## Event hook: an item was crafted by player p.
func on_item_crafted(p: PlayerState, item_id: String) -> void:
	if not p.crafted_items_history.has(item_id):
		p.crafted_items_history.append(item_id)


## Event hook: player gathered or moved to a T2 tile with an uncommon card.
func on_gather_card(p: PlayerState, tile_tier: int, card_tier: String) -> void:
	if tile_tier >= 2 and (card_tier == "uncommon" or card_tier == "rare" or card_tier == "legendary"):
		p_add_progress(p, "deep_step", 1)
		_check_auto_complete(p, "deep_step")


## Event hook: an offering was made at a Guardian site.
func on_guardian_offering(p: PlayerState, tile_pos: Vector2i) -> void:
	if not p.guardian_sites_offered.has(tile_pos):
		p.guardian_sites_offered.append(tile_pos)
	p.quest_progress["circle_complete"] = p.guardian_sites_offered.size()
	_check_auto_complete(p, "circle_complete")


func p_add_progress(p: PlayerState, quest_id: String, delta: int) -> void:
	var cur: int = int(p.quest_progress.get(quest_id, 0))
	p.quest_progress[quest_id] = cur + delta


## Checks if quest criteria met; if so, marks completed and awards VP.
func _check_auto_complete(p: PlayerState, quest_id: String) -> bool:
	if is_completed(p, quest_id):
		return false
	var quest: Dictionary = _find_common_quest(quest_id)
	if quest.is_empty():
		return false
	var target: int = int(COMMON_QUEST_TARGETS.get(quest_id, 1))
	var current: int = int(p.quest_progress.get(quest_id, 0))
	if current >= target:
		complete_quest(p, quest)
		return true
	return false


func _find_common_quest(quest_id: String) -> Dictionary:
	for q in common_quests:
		if String(q.get("id", "")) == quest_id:
			return q
	return {}


## Awards quest VP and registers completion on player.
func complete_quest(p: PlayerState, quest: Dictionary) -> void:
	var qid := String(quest.get("id", ""))
	if p.completed_quests.has(qid):
		return
	p.completed_quests.append(qid)
	var vp_reward := int(quest.get("vp", 1))
	# Update VP through Game state or directly on player
	p.vp = clampi(p.vp + vp_reward, 0, 20)
	EventBus.vp_changed.emit(p.index, p.vp)
	EventBus.quest_completed.emit(p.index, quest)


## Revokes VP if a quest with revoke_vp is violated/abandoned.
func revoke_quest_vp(p: PlayerState, quest_id: String) -> void:
	if not p.completed_quests.has(quest_id):
		return
	var q := _find_common_quest(quest_id)
	if q.is_empty():
		return
	p.completed_quests.erase(quest_id)
	var vp_loss := int(q.get("vp", 0))
	p.vp = maxi(0, p.vp - vp_loss)
	EventBus.vp_changed.emit(p.index, p.vp)


# ------------------------------------------------------------------ Redraw Vote (GDD §8.5)

## Begins a redraw vote initiated by calling player.
func start_redraw_vote(caller_index: int, total_players: int) -> Dictionary:
	_redraw_votes.clear()
	_redraw_caller = caller_index
	_redraw_votes[caller_index] = true  # caller votes yes
	return get_vote_status(total_players)


## Registers a player's vote. Returns vote status and whether resolved.
func submit_vote(player_index: int, agree: bool, total_players: int) -> Dictionary:
	_redraw_votes[player_index] = agree
	return get_vote_status(total_players)


## Returns current vote summary.
## Rules (GDD §8.5): Majority of all active players needed.
## In case of an even tie with an even player count, the non-owner / first responder decides.
func get_vote_status(total_players: int) -> Dictionary:
	var yes_count := 0
	var no_count := 0
	for idx in _redraw_votes.keys():
		if bool(_redraw_votes[idx]):
			yes_count += 1
		else:
			no_count += 1
	var total_voted := yes_count + no_count
	var all_voted := total_voted >= total_players
	var needed := (total_players / 2) + 1
	var passed := yes_count >= needed
	var failed := no_count >= needed or (all_voted and yes_count < needed)
	
	# Tiebreaker rule for 2 players or even split when everyone voted:
	# If 2 players and 1 voted Yes (caller) and 1 voted No -> non-owner decides (fails)
	var resolved := passed or failed or all_voted
	return {
		"caller": _redraw_caller,
		"yes_count": yes_count,
		"no_count": no_count,
		"total_voted": total_voted,
		"total_players": total_players,
		"resolved": resolved,
		"passed": passed,
	}


func clear_vote() -> void:
	_redraw_votes.clear()
	_redraw_caller = -1
