# Crownsfall gateway inspection

Blender 5.2.2 LTS imported and rendered the supplied GLB on November 20, 2026. Its SHA-256 is `4eca814083ffde756de9d43801a66ab4f29af9298e53320b61ae49980cf1ba46`. The [orthographic inspection render](../Citadel-gateway-Blender.png) shows the mesh from the stair approach under Blender Workbench studio lighting.

| Measured property | Result |
| --- | --- |
| GLB | glTF 2.0, 4,865,996 bytes, one scene |
| Geometry | 312 nodes, 292 mesh definitions, 44,832 imported vertices across mesh objects, 26,724 triangles |
| Bounds in Blender world coordinates | X −10 to 10, Y −18.5 to 11.15, Z −0.455 to 8.830 |
| Overall dimensions | 20.0 × 29.65 × 9.285 scene units |
| Materials | Ten glTF material entries, including painted ivory, patina, brass, royal blue cloth, water, flowers and ivy |
| Embedded texture images | 1,024² ivory, 1,024² patina and 512² ivy. Blender resolved all three as packed images |
| Animation | Static gateway with zero skins and zero animation clips |
| Stair flight | Nine authored treads, each roughly 7.5 units wide, rising in 0.2-unit increments to a landing at Z 1.8 |

## Reuse in Crownsfall

The staircase, brass coping, blue banners, carved lintel and upper landing provide an existing architectural module for Crownsfall. At the reference camera angle, the simple rectangular towers, narrow roofline and isolated patches of greenery leave the silhouette substantially simpler than the layered cathedral district in picture 4. The render shows open space on both sides of the stair rather than the surrounding buildings and canals visible in the reference.

For a Godot integration pass, instance the gateway at its native scale, register the landing to the current world path, and measure stair traversal and actor occlusion at the game camera. The nine risers give repeatable test locations. This inspection verified mesh bounds, material resolution and an actual Blender render. Runtime collision, navigation, draw-call cost and scene registration require a Godot scene-level test.
