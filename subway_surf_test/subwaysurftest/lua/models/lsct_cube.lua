-- exported with a helper script written by lokachop (Lokachop#5862)
LSCT = LSCT or {}
Surf3D = Surf3D or {}
Surf3D.Models = Surf3D.Models or {}

print("loading model: cube")

Surf3D.Models.cube = {}
Surf3D.Models.cube.Verts = {
    Vector(1, 1, -1),
    Vector(1, -1, -1),
    Vector(1, 1, 1),
    Vector(1, -1, 1),
    Vector(-1, 1, -1),
    Vector(-1, -1, -1),
    Vector(-1, 1, 1),
    Vector(-1, -1, 1),
}
Surf3D.Models.cube.UVs = {
    {0.875, 0.5},
    {0.625, 0.75},
    {0.625, 0.5},
    {0.375, 1},
    {0.375, 0.75},
    {0.625, 0},
    {0.375, 0.25},
    {0.375, 0},
    {0.375, 0.5},
    {0.125, 0.75},
    {0.125, 0.5},
    {0.625, 0.25},
    {0.875, 0.75},
    {0.625, 1},
}
Surf3D.Models.cube.Indices = {
    {
        {5, 1},
        {3, 2},
        {1, 3}
    },
    {
        {3, 2},
        {8, 4},
        {4, 5}
    },
    {
        {7, 6},
        {6, 7},
        {8, 8}
    },
    {
        {2, 9},
        {8, 10},
        {6, 11}
    },
    {
        {1, 3},
        {4, 5},
        {2, 9}
    },
    {
        {5, 12},
        {2, 9},
        {6, 7}
    },
    {
        {5, 1},
        {7, 13},
        {3, 2}
    },
    {
        {3, 2},
        {7, 14},
        {8, 4}
    },
    {
        {7, 6},
        {5, 12},
        {6, 7}
    },
    {
        {2, 9},
        {4, 5},
        {8, 10}
    },
    {
        {1, 3},
        {3, 2},
        {4, 5}
    },
    {
        {5, 12},
        {1, 3},
        {2, 9}
    },
}
