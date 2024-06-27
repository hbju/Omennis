class_name HexHelper

# Conversions
static func cube_to_axial(cube: Vector3i) -> Vector2i:
    var q = cube.x
    var r = cube.y
    return Vector2i(q, r)

static func axial_to_cube(hex: Vector2i) -> Vector3i:
    var q = hex.x
    var r = hex.y
    var s = -q-r
    return Vector3i(q, r, s)

static func axial_to_oddr(hex: Vector2i) -> Vector2i:
    var col = hex.x + (hex.y - (hex.y&1)) / 2
    var row = hex.y
    return Vector2i(col, row)

static func oddr_to_axial(hex: Vector2i) -> Vector2i:
    var q = hex.x - (hex.y - (hex.y&1)) / 2
    var r = hex.y
    return Vector2i(q, r)


## Neighbors

## Cube coordinates
static var cube_direction_vectors = [
    Vector3i(+1, 0, -1), Vector3i(+1, -1, 0), Vector3i(0, -1, +1), 
    Vector3i(-1, 0, +1), Vector3i(-1, +1, 0), Vector3i(0, +1, -1), 
]

static func cube_direction(direction: int) -> Vector3i:
    return cube_direction_vectors[direction]

static func cube_add(hex: Vector3i, vec: Vector3i) -> Vector3i:
    return Vector3i(hex.x + vec.x, hex.y + vec.y, hex.z + vec.z)

static func cube_neighbor(cube: Vector3i, direction: int) -> Vector3i:
    return cube_add(cube, cube_direction(direction))

## Axial coordinates
static var axial_direction_vectors = [
    Vector2i(+1, 0), Vector2i(+1, -1), Vector2i(0, -1), 
    Vector2i(-1, 0), Vector2i(-1, +1), Vector2i(0, +1), 
]

static func axial_direction(direction: int) -> Vector2i:
    return axial_direction_vectors[direction]

static func axial_add(hex: Vector2i, vec: Vector2i) -> Vector2i:
    return Vector2i(hex.x + vec.x, hex.y + vec.y)

static func axial_neighbor(hex: Vector2i, direction: int) -> Vector2i:
    return axial_add(hex, axial_direction(direction))

## Offset coordinates

static var oddr_direction_differences = [
    # even rows 
    [[+1,  0], [ 0, -1], [-1, -1], 
     [-1,  0], [-1, +1], [ 0, +1]],
    # odd rows 
    [[+1,  0], [+1, -1], [ 0, -1], 
     [-1,  0], [ 0, +1], [+1, +1]],
]

static func hex_neighbor(hex: Vector2i, direction: int) -> Vector2i:
    var parity = hex.y & 1
    var diff = oddr_direction_differences[parity][direction]
    return Vector2i(hex.x + diff[0], hex.y + diff[1])

# Distances

## Cube coordinates

static func cube_subtract(a: Vector3i, b: Vector3i) -> Vector3i:
    return Vector3i(a.x - b.x, a.y - b.y, a.z - b.z)

static func cube_distance(a: Vector3i, b: Vector3i) -> int:
    var vec = cube_subtract(a, b)
    return max(abs(vec.x),  abs(vec.y), abs(vec.z))

## Axial coordinates

static func axial_subtract(a: Vector2i, b: Vector2i) -> Vector2i:
    return Vector2i(a.x - b.x, a.y - b.y)

static func axial_distance(a: Vector2i, b: Vector2i) -> int:
    var ac = axial_to_cube(a)
    var bc = axial_to_cube(b)
    return cube_distance(ac, bc)

## Offset coordinates

static func distance(a: Vector2i, b: Vector2i) -> int:
    var ac = oddr_to_axial(a)
    var bc = oddr_to_axial(b)
    return axial_distance(ac, bc)

# Line drawing

static func lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t

static func cube_lerp(a: Vector3i, b: Vector3i, t: float) -> Vector3:
    return Vector3(lerp(a.x, b.x, t),
                lerp(a.y, b.y, t),
                lerp(a.z, b.z, t))

static func cube_linedraw(a: Vector3i, b: Vector3i) -> Array[Vector3i]:
    var N = cube_distance(a, b)
    var results: Array[Vector3i] = []
    for i in range(N+1):
        results.append(cube_round(cube_lerp(a, b, 1.0/N * i)))
    return results

static func axial_linedraw(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
    var results: Array[Vector2i] = []
    for hex in cube_linedraw(axial_to_cube(a), axial_to_cube(b)):
        results.append(cube_to_axial(hex))
    return results

static func oddr_linedraw(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
    var results: Array[Vector2i] = []
    for hex in axial_linedraw(oddr_to_axial(a), oddr_to_axial(b)):
        results.append(axial_to_oddr(hex))
    return results

# Range

static func cube_range(center: Vector3i, radius: int) -> Array[Vector3i]:
    var results: Array[Vector3i] = []
    for dx in range(-radius, radius+1):
        for dy in range(max(-radius, -dx-radius), min(radius, -dx+radius)+1):
            var dz = -dx-dy
            results.append(Vector3i(center.x + dx, center.y + dy, center.z + dz))
    return results

static func axial_range(center: Vector2i, radius: int) -> Array[Vector2i]:
    var results: Array[Vector2i] = []
    for dx in range(-radius, radius+1):
        for dy in range(max(-radius, -dx-radius), min(radius, -dx+radius)+1):
            results.append(Vector2i(center.x + dx, center.y + dy))
    return results

static func range(center: Vector2i, radius: int) -> Array[Vector2i]:
    var results: Array[Vector2i] = []
    for hex in axial_range(oddr_to_axial(center), radius):
        results.append(axial_to_oddr(hex))
    return results

static func cube_range_intersection(a: Vector3i, b: Vector3i, radius: int) -> Array[Vector2i]:
    var results = []
    var xmin = max(a.x - radius, b.x - radius)
    var xmax = min(a.x + radius, b.x + radius)
    var ymin = max(a.y - radius, b.y - radius)
    var ymax = min(a.y + radius, b.y + radius)
    var zmin = max(a.z - radius, b.z - radius)
    var zmax = min(a.z + radius, b.z + radius)

    for dx in range(xmin, xmax+1):
        for dy in range(max(ymin, -dx-zmax), min(ymax, -dx-zmin)+1):
            results.append(Vector2i(dx, dy))

    return results


static func axial_range_intersection(a: Vector2i, b: Vector2i, radius: int) -> Array[Vector2i]:
    return cube_range_intersection(axial_to_cube(a), axial_to_cube(b), radius)

static func range_intersection(a: Vector2i, b: Vector2i, radius: int) -> Array[Vector2i]:
    var results = []
    for hex in axial_range_intersection(oddr_to_axial(a), oddr_to_axial(b), radius):
        results.append(axial_to_oddr(hex))
    return results

static func hex_reachable(start: Vector2i, movement: int, can_move_to: Callable) -> Array[Vector2i]:
    var visited = {} # set of hexes
    visited[start] = null
    var fringes = [] # array of arrays of hexes
    fringes.append([start])

    for k in range(1, movement+1):
        fringes.append([])
        for hex in fringes[k-1]:
            for dir in range(6):
                var neighbor = hex_neighbor(hex, dir)
                if neighbor not in visited and can_move_to.call(neighbor):
                    visited[neighbor] = null
                    fringes[k].append(neighbor)

    var reachables : Array[Vector2i] = []
    for hex in visited.keys():
        reachables.append(hex)
    return reachables

# Rotation

static func rotate_left(hex: Vector2i, center: Vector2i) -> Vector2i:
    var hex_cube = axial_to_cube(oddr_to_axial(hex))
    var center_cube = axial_to_cube(oddr_to_axial(center))
    var vec = cube_subtract(hex_cube, center_cube)
    var rotated = Vector3i(-vec.y, -vec.z, -vec.x)
    return axial_to_oddr(cube_to_axial(cube_add(rotated, center_cube)))

static func rotate_right(hex: Vector2i, center: Vector2i) -> Vector2i:
    var hex_cube = axial_to_cube(oddr_to_axial(hex))
    var center_cube = axial_to_cube(oddr_to_axial(center))
    var vec = cube_subtract(hex_cube, center_cube)
    var rotated = Vector3i(-vec.z, -vec.x, -vec.y)
    return axial_to_oddr(cube_to_axial(cube_add(rotated, center_cube)))

# Rings and Spirals

static func cube_scale(hex: Vector3i, factor: int) -> Vector3i:
    return Vector3i(hex.x * factor, hex.y * factor, hex.z * factor)

static func cube_ring(center: Vector3i, radius: int) -> Array[Vector3i]:
    var results: Array[Vector3i] = []
    var hex = cube_add(center,
                        cube_scale(cube_direction(4), radius))
    for i in range(0, 6):
        for j in range(0, radius):
            results.append(hex)
            hex = cube_neighbor(hex, i)
    return results

static func cube_spiral(center: Vector3i, radius: int) -> Array[Vector3i]:
    var results: Array[Vector3i] = [center]
    for k in range(1, radius+1):
        results += cube_ring(center, k)
    return results

static func axial_ring(center: Vector2i, radius: int) -> Array[Vector2i]:
    var results: Array[Vector2i] = []
    for hex in cube_ring(axial_to_cube(center), radius):
        results.append(cube_to_axial(hex))
    return results

static func axial_spiral(center: Vector2i, radius: int) -> Array[Vector2i]:
    var results: Array[Vector2i] = [center]
    for k in range(1, radius+1):
        results += axial_ring(center, k)
    return results

static func ring(center: Vector2i, radius: int) -> Array[Vector2i]:
    var results: Array[Vector2i] = []
    for hex in axial_ring(oddr_to_axial(center), radius):
        results.append(axial_to_oddr(hex))
    return results

static func spiral(center: Vector2i, radius: int) -> Array[Vector2i]:
    var results: Array[Vector2i] = [center]
    for k in range(1, radius+1):
        results += ring(center, k)
    return results

# Columns

static func cube_column(start: Vector3i, direction: int, length: int) -> Array[Vector3i]:
    var results: Array[Vector3i] = []
    for i in range(0, length):
        results.append(start)
        start = cube_neighbor(start, direction)
    return results

static func axial_column(start: Vector2i, direction: int, length: int) -> Array[Vector2i]:
    var results: Array[Vector2i] = []
    for hex in cube_column(axial_to_cube(start), direction, length):
        results.append(cube_to_axial(hex))
    return results

static func column(start: Vector2i, direction: int, length: int) -> Array[Vector2i]:
    var results: Array[Vector2i] = []
    for hex in axial_column(oddr_to_axial(start), direction, length):
        results.append(axial_to_oddr(hex))
    return results


# Field of view


static func fov(center: Vector2i, target: Vector2i, can_view: Callable) -> Array[Vector2i]:
    var results: Array[Vector2i] = []
    for hex in oddr_linedraw(center, target):
        if can_view.call(hex):
            results.append(hex)
    return results

# Rounding

static func cube_round(frac: Vector3) -> Vector3i:
    var q = round(frac.x)
    var r = round(frac.y)
    var s = round(frac.z)

    var q_diff = abs(q - frac.x)
    var r_diff = abs(r - frac.y)
    var s_diff = abs(s - frac.z)

    if q_diff > r_diff and q_diff > s_diff:
        q = -r-s
    elif r_diff > s_diff:
        r = -q-s
    else:
        s = -q-r

    return Vector3i(q, r, s)
