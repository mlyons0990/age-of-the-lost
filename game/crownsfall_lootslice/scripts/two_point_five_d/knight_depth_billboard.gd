extends Node3D
## Visual-only proxy of the ORIGINAL, currently playing 2D knight frames.
## This is not a second player: no movement, collision, stats or save ownership.
## Sprite3D is drawn inside the exact scenery SubViewport so actual 3D architecture
## can depth-test and occlude the painted sprite correctly.

const GD := preload("res://scripts/game_data.gd")
var painted_sprite: Sprite3D
var contact_shadow: Sprite3D
var last_frame_key := ""
var last_boot_delta_px := 0.0
var frames_synced := 0
# Calibrated in the real Godot 4.6.3 1440x810 gameplay camera using native
# vs. Sprite3D pixel masks, not by eye. Height applies to the billboard origin.
const PAINTED_AVATAR_ORIGIN_HEIGHT := 1.90
var reference_offset_px := 0.0

func _ready() -> void:
    painted_sprite = Sprite3D.new()
    painted_sprite.name = "Approved_Painterly_Knight_LiveFrame"
    painted_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    painted_sprite.shaded = false
    painted_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
    # The painterly walkable-floor material uses transparent alpha falloff.
    # Force the knight transparent pass AFTER that painted ground while still
    # leaving GPU depth testing enabled against opaque 3D architecture.
    painted_sprite.render_priority = 12
    painted_sprite.double_sided = true
    painted_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    painted_sprite.fixed_size = false
    add_child(painted_sprite)
    painted_sprite.position.y = PAINTED_AVATAR_ORIGIN_HEIGHT
    # A separate ground-oriented contact shadow restores visual weight in F10.
    # It reads the same radial gradient as the real 2D player; this is not physics.
    contact_shadow = Sprite3D.new()
    contact_shadow.name = "GroundContactShadow_SyncedFromOriginalActor"
    contact_shadow.billboard = BaseMaterial3D.BILLBOARD_DISABLED
    contact_shadow.rotation_degrees.x = -90.0
    contact_shadow.shaded = false
    contact_shadow.double_sided = true
    contact_shadow.no_depth_test = false
    contact_shadow.render_priority = 8
    contact_shadow.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
    contact_shadow.position.y = 0.07
    add_child(contact_shadow)

func sync_from_player(actor: Node2D, to_world: Callable) -> void:
    if actor == null or not is_instance_valid(actor) or painted_sprite == null:
        return
    var sprite: AnimatedSprite2D = actor.sprite
    if sprite == null or sprite.sprite_frames == null:
        painted_sprite.visible = false
        return
    var frame_tex: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
    if frame_tex == null:
        painted_sprite.visible = false
        return
    painted_sprite.visible = not actor.dead
    contact_shadow.visible = not actor.dead and actor.shadow.visible == false
    contact_shadow.texture = actor.shadow.texture
    contact_shadow.pixel_size = 1.0 / GD.U
    contact_shadow.scale = Vector3(actor.shadow.scale.x, actor.shadow.scale.y, 1)
    contact_shadow.modulate = actor.shadow.modulate
    var frame_key: String = String(sprite.animation) + ":" + str(sprite.frame) + ":" + actor.class_id
    if frame_key != last_frame_key or painted_sprite.texture != frame_tex:
        painted_sprite.texture = frame_tex
        last_frame_key = frame_key
        frames_synced += 1
    painted_sprite.flip_h = sprite.flip_h
    painted_sprite.pixel_size = absf(sprite.scale.x) / GD.U
    # Sprite3D's vertical image pivot is not the same as the native
    # AnimatedSprite2D pivot. Normalize against the original class idle pose,
    # then preserve each walk/attack/cast frame's source-authored foot delta.
    var source_class: String = "mage" if actor.mage_art_active else "knight"
    var idle_meta: Dictionary = actor.foot_anchor_frames.get(source_class + "/idle_se.png", {})
    var idle_feet: Array = idle_meta.get("feet_y", [])
    reference_offset_px = 0.0
    if not idle_feet.is_empty():
        reference_offset_px = -float(idle_feet[0]) + float(idle_meta.get("frame_size", 384)) * 0.5 + actor.FEET.y / actor.SPRITE_SCALE
    # Sprite3D is center-pivoted in object-space. When the actual sword atlas
    # expands from 384px to 512px, compensate the half-canvas size difference
    # so the original boot contact remains aligned across attack transitions.
    var height_delta_px: float = (float(frame_tex.get_height()) - float(idle_meta.get("frame_size", 384))) * 0.5
    painted_sprite.offset = Vector2(sprite.offset.x, sprite.offset.y - reference_offset_px + height_delta_px)
    painted_sprite.modulate = sprite.modulate * actor.visual_root.modulate
    # Only the presentation transform is mirrored. No game-world transform changes.
    var actor_px: Vector2 = actor.global_position + actor.visual_root.position
    global_position = to_world.call(actor_px)
    painted_sprite.scale = Vector3(actor.visual_root.scale.x, actor.visual_root.scale.y, 1.0)
    painted_sprite.rotation.z = -actor.visual_root.rotation
    var sheet_size: Vector2 = frame_tex.get_size()
    last_boot_delta_px = float(actor.current_foot_anchor_px) - sheet_size.y * 0.5 + sprite.offset.y

func status() -> Dictionary:
    return {
        "exists": painted_sprite != null,
        "frame_key": last_frame_key,
        "frames_synced": frames_synced,
        "pixel_size": painted_sprite.pixel_size if painted_sprite != null else 0.0,
        "ground_offset_px": last_boot_delta_px,
        "has_texture": painted_sprite != null and painted_sprite.texture != null,
        "pivot_origin_height": PAINTED_AVATAR_ORIGIN_HEIGHT,
        "idle_reference_offset_px": reference_offset_px,
        "three_d_frame_offset_px": painted_sprite.offset if painted_sprite != null else Vector2.ZERO,
        "render_priority": painted_sprite.render_priority if painted_sprite != null else -1,
        "shadow_visible": contact_shadow != null and contact_shadow.visible,
        "3d_depth_tested": true,
        "authority": "original_2d_player_only",
    }
