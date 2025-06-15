# PointOfInterest.gd
class_name PointOfInterest
extends Area2D

# The user-facing name of this location.
@export var poi_name: String = "Old Ruins"

# The city this POI is associated with. Use the city's event ID (e.g., "gall", "northwood").
@export var region_id: String = "gall"

# Tags for the radiant quest system. A quest template might require a "cave" or "ruins".
@export var tags: Array[String] = ["ruins"]

# A reference to the event file to trigger when the player enters.
@export var event_id_on_enter: String = "evt_ruins_entry"