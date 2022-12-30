# Divide-and-conquer Delaunay triangulation

A straight-forward fast and light ported luau version of the [delaunay-triangulation](https://github.com/Bathlamos/delaunay-triangulation) library written in ``js``
> **Note**
> **While this library was initially written to work solely with [luau](https://luau-lang.org/), I have pushed out a version compatible with lua version 5.3.6
that doesn't feature typechecking and special operators. It can be found [here](./src/lua/Lua-Delaunay.lua) if interested.**

## Demo
<h5 align="center">(throttled down to ~10 segments per second)</h5>

<div>
<img src="https://cdn.discordapp.com/attachments/735132698603159562/1058109329535930378/delaunaydemo.gif" align="left" width=49.5%>
</img>
<img src="https://cdn.discordapp.com/attachments/735132698603159562/1058101080753451089/convexhulldemo.gif" align="right" width=49.5%>
</img>
</div>
<div>
<h4 align="center">⠀⠀⠀Delaunay demo<sup><a href="https://github.com/proudCobolWriter/lua-ez-delaunay/releases/tag/Delaunay">[download]</a></sup>⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀Convex-hull demo<sup><a href="https://github.com/proudCobolWriter/lua-ez-delaunay/releases/tag/Convex-hull">[download]</a></sup>
</h4>
</div>

Table of Contents
=================

   * [API](#API)
      * [Special types](#special-types)
      * [Delaunay functions](#functions-delaunay)
      * [Convex-hull functions](#functions-convex-hull)
   * [Example usages](#example-usages)
   * [Benchmarking](#benchmarking)
   * [Algorithm specifications](#algorithm)
   * [Convex-hull](#convex-hull)
   * [Addendum](#addendum)
   * [Acknowledgements](#acknowledgements)
   * [To-do list](#to-do-list)

## API

### Special [types](./src/luau/Luau-TypeDefinitions.lua)
```ts
//   Stores 4 values, read more about QuadEdges here: http://www.cs.cmu.edu/afs/andrew/scs/cs/15-463/2001/pub/src/a2/quadedge.html
//   This type is exported, meaning you can access it by simply indexing it, ex: delaunay.QuadEdge
type QuadEdge = {
	onext: QuadEdge,
	mark: boolean,
	orig: Point,
	rot: QuadEdge
}

//   Generic array-like table type
//   Unlike QuadEdge, this type is not exported, meaning you have to access it by requiring Luau-TypeDefinitions.lua
type Array<T> = { [number]: T }

//   Stores 2 dimensional vector data in a dictionary (=hashtable) containing ["x"] and ["y"] keys
//   Unlike QuadEdge, this type is not exported, meaning you have to access it by requiring Luau-TypeDefinitions.lua
type Point = {
	x: number,
	y: number
}
```

### Functions ([Delaunay](./src/luau/Luau-Delaunay.lua#L461))

```lua
function triangulate ( pointsArray: Array<Point> ): Array<Point>
--	 ^ Init function, computes Guibas & Stolfi's divide-and-conquer algorithm
--	 *
--	 * @param pointsArray an Array containing Points
--	 ** 	  ^example: { {x = 0, y = 0}, {x = 1, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}, {x = 0, y = 1}, {x = 1, y = 0} }
--	 *
--	 * @return an array-like table containing face data

function iterate ( facesArray: Array<Point>, callback: ( Array<Point> ) -> nil, defer: boolean ): Array<{ Array<Point> }>
--	 ^ Customizable shortcut function that reads through data returned by function triangulate
--	 *
--	 * @param facesArray an Array containing Points
--	 * @param callback an anonymous function that gets called for every triangles processed, should always return void
--	 * @param defer defines whether or not we should make use of the built-in roblox ``task`` lib
--	 *
--	 * @return an array-like table containing Arrays representing triangles (each containing 3 points)
```

### Functions ([Convex-hull](./src/luau/Luau-ConvexHull.lua#L75))

```lua
function iterate ( facesArray: Array<Point>, callback: ( Array<Point> ) -> nil, defer: boolean ): Array<{ Array<Point> }>
--	 ^ Customizable shortcut function that reads through data returned by function triangulate
--	 *
--	 * @param facesArray an Array containing Points
--	 * @param callback an anonymous function that gets called for every triangles processed, should always return void
--	 * @param defer defines whether or not we should make use of the built-in roblox ``task`` lib
--	 *
--	 * @return an array-like table containing Arrays representing triangles (each containing 3 points)
```

## Example usages

*Standard usage*

```lua
local delaunay = require(--[[ path to the library ]])
   
local function randomPoints(iterations)
    	local points = table.create(iterations)
    	
    	for i = 1, iterations do
    		points[#points + 1] = {x = math.random() * 1000, y = math.random() * 1000} -- append the point to the table
    	end
    	return points
end

-- Given a set of Points, we can call delaunay.triangulate and pass our set of 2D points

local results = delaunay.triangulate( randomPoints(100) ) -- should take roughly 0.01 second
```

*What it should look like in js*

```js
import { triangulate as delaunay } from '/example/library.js';

function randomPoints(iterations) {
    	let points = []; // construct array
   
    	for (let i = iterations; i > 0; i--) points.push({x: Math.random() * 1000, y: Math.random() * 1000});
    	return points
};

delaunay( randomPoints(100) );
```

*Use case for the ``iterate`` function* (using the Roblox API)
```lua
local canvasSize = Vector2.new(1000, 500)
local canvas = urFrame or Instance.new("Frame")

local delaunay = require(--[[ path to the library ]]))
local results = delaunay.triangulate( randomPoints(100) ) -- should take roughly 0.01 second

local function linkPoints(parent, p1, p2, thickness)
	local segment = Instance.new("Frame")
	local relative = p2 - p1
	local angle = math.atan2(relative.Y, relative.X)
	local mag = (relative.X ^ 2 + relative.Y ^ 2) ^ 0.5

	segment.Rotation = math.deg(angle)
	segment.Position = UDim2.new(0, p1.X + relative.X * 0.5, 0, p1.Y + relative.Y * 0.5)
	segment.Size = UDim2.new(0, mag, 0, thickness)
	segment.BorderSizePixel = 0
	segment.AnchorPoint = Vector2.new(0.5, 0.5)
	segment.Name = "Segment/Edge"
	segment.BackgroundColor3 = Color3.new(math.random(), math.random(), math.random())
	segment.Parent = parent

	return segment
end

delaunay.iterate(results, function(triangle) -- pass an anonymous function as callback
	local point1, point3, point3 = triangle[1], triangle[2], triangle[3]

	linkPoints(canvas, Vector2.new(point1.x, point1.y), Vector2.new(point2.x, point2.y), 3)
	linkPoints(canvas, Vector2.new(point2.x, point2.y), Vector2.new(point3.x, point3.y), 3)
	linkPoints(canvas, Vector2.new(point3.x, point3.y), Vector2.new(point1.x, point1.y), 3)
end, true)
```

*Note that this library only works with 2D coordinates, if you wish to apply this library in 3D, project your set of 2D coordinates onto an infinite 2D plane using stereographic coordinates, then run the triangulate function again. Once you have computed the results all you have to do is wrap the points from the infinite 2D plane back onto your 3D mesh.* You would typically do this when working with spheres[[1]](https://www.redblobgames.com/x/1842-delaunay-voronoi-sphere/).


## [Benchmarking](/tests/StarterPlayerScripts/LocalScript)

### DISCLAIMER: The following samples might not be very accurate as it was tested within Roblox Studio with rather mediocre old hardware, therefore it should only be regarded as an approximate reference. The runtime can vary over different lua environments.

> **Note**
> Benchmark hardware specs: *Intel core i5 4460 @ 3.2GHz, 8GB DDR3-1600MHz, NVidia GT705, Windows 10 64-bit luau version <0.5 env*

![](/tests/benchmarkGraph.png)

**Grid point distribution (equidistant points)**

AMOUNT OF POINTS | Execution time (S) in average (tested 100 times)
---------------- | -------------
100 points	 | 0.001480s
1 000 points	 | 0.020110s
25 000 points    | 0.554840s
50 000 points    | 0.999739s
75 000 points    | 1.751809s
150 000 points   | 3.061690s
350 000 points   | 7.195849s

**Uniform point distribution (random)**

AMOUNT OF POINTS | Execution time (S) in average (tested 100 times)
---------------- | -------------
100 points       | 0.009019s
1 000 points     | 0.050649s
25 000 points    | 0.124629s
50 000 points    | 0.278569s
75 000 points    | 13.02379s
150 000 points   | 30.23039s
350 000 points   | 79.38119s

**Multivariate normal distribution (multiple iterations)**

AMOUNT OF POINTS | Execution time (S) in average (tested 100 times)
---------------- | -------------
100 points       | 0.009569s
1 000 points     | 0.049230s
25 000 points    | 0.116719s
50 000 points    | 0.271659s
75 000 points    | 14.40540s
150 000 points   | 27.08019s
350 000 points   | 71.71020s

## Algorithm

This implementation is based on a traditional O(n * log n * n) Divide-and-conquer algorithm as described [there](https://github.com/Bathlamos/delaunay-triangulation) that is surprisingly doing the job with dense points set. The [QuadEdge data structure](http://www.cs.cmu.edu/afs/andrew/scs/cs/15-463/2001/pub/src/a2/quadedge.html) came in handy when manipulating points, whilst still greatly minizing the amount of metamethods invoked.

## Convex-hull

This library is provided with a Monotone-chain convex hull solver also available in both [lua](./src/lua/Lua-ConvexHull.lua) and [luau](./src/luau/Luau-ConvexHull.lua), which computes the convex hull of a given a set of 2-dimensional points.
The implementation follows the same logic and datastructure as the main file. [(wikipedia article)](https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain)

## Addendum

If you plan on using this library for Roblox, please consider including the [TypeDefinitions](./src/luau/Lua-TypeDefinitions.lua] modulescript
as a child. If you think this is not convenient for you, you can always copy paste the type definitions from this modulescript and replace the existing references.

## Acknowledgements

[@Bathlamos](https://github.com/Bathlamos) for the [original library](https://github.com/Bathlamos/delaunay-triangulation)

[Another Delaunay lua implementation](https://github.com/Nolan-O/LuaDelaunayTriangulation) for some of the wording

Quad-Edge article : http://www.cs.cmu.edu/afs/andrew/scs/cs/15-463/2001/pub/src/a2/quadedge.html

### To-do list:

- [ ] Additional sanity checks
- [ ] Add Voronoi support
- [ ] Eventually implement a faster sorting algorithm for large arrays
