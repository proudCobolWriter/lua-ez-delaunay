# Divide-and-conquer Delaunay triangulation

A fast light ported luau version of the [delaunay-triangulation](https://github.com/Bathlamos/delaunay-triangulation) library written in ``js``
> **Note**
> While this library was initially written to work solely with [luau](https://luau-lang.org/), I have pushed out a version compatible with lua version 5.3.6
that doesn't feature typechecking and special operators. It can be found [here](./src/) if interested.

## API

### Special types
```ts
//   Stores 2 dimensional vector data in a dictionary (=hashtable) containing ["x"] and ["y"] keys
type Point = {
	x: number,
	y: number
}

//   Generic array-like table type
type Array<T> = { [number]: T }

//   Stores 4 values, read more about QuadEdges here: http://www.cs.cmu.edu/afs/andrew/scs/cs/15-463/2001/pub/src/a2/quadedge.html
type QuadEdge = typeof(setmetatable({}, _quadEdgeCache)) & {
	onext: QuadEdge,
	mark: boolean,
	orig: Point,
	rot: QuadEdge
}
```

### Functions
```lua
function triangulate ( pointsArray: Array<Point> ): Array<Point>
--	 ^ Init function, computes Guibas & Stolfi's divide-and-conquer algorithm
--	 *
--	 * @param pointsArray an array-like table containing Points
--	 ** 	  ^example: { {x = 0, y = 0}, {x = 1, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}, {x = 0, y = 1}, {x = 1, y = 0} }
--	 *
--	 * @return an array-like table containing face data

function iterate ( tbl: Array<Point>, callback: ( Array<Point> ) -> nil, defer: boolean ): Array<{ Array<Point> }>
--	 ^ Customizable shortcut function that reads through data returned by function triangulate
--	 *
--	 * @param tbl an array-like table containing Points
--	 * @param callback an anonymous function that gets called for each triangle processed, should always return void
--	 * @param defer defines whether or not we should make use of the built-in roblox ``task`` lib
--	 *
--	 * @return an array-like table containing array-like tables representing triangles (each containing 3 points)

```

## Example usages

*Standard usage*

```lua
local delaunay = require(--[[ path to the module ]])
   
local function randomPoints(iterations)
    	local points = table.create(iterations) -- generate an array-like table
    	
    	for i = 1, iterations do
    		points[#points + 1] = {x = math.random() * 1000, y = math.random() * 1000} -- append the point to the table
    	end
    	return points
end

-- Given a set of tables containing 2D points, we can call delaunay.triangulate and pass our set of points

local results = delaunay.triangulate( randomPoints(100) ) -- should take roughly 0.01 second
```

*What it should look like in js*

```js
import { triangulate } as delaunay from '/example/module.js';

function randomPoints(iterations) {
    	let points = []; // construct array
   
    	for (let i = iterations; i > 0; i--) points.push({x: Math.random() * 1000, y: Math.random() * 1000});
    	return points
};

delaunay( randomPoints(100) );
```

*Use case for the ``iterate`` function*
```lua
local delaunay = require(--[[ path to the module ]]))
local results = delaunay.triangulate( randomPoints(100) ) -- should take roughly 0.01 second

local function linkPoints(parent, p1, p2)
	local segment = Instance.new("Frame")
	local relative = p2 - p1
	local angle = math.atan2(relative.Y, relative.X)
	local mag = (relative.X ^ 2 + relative.Y ^ 2) ^ 0.5
	
	segment.Rotation = math.deg(angle)
	segment.Position = UDim2.new(0, p1.X + relative.X * 0.5, 0, p1.Y + relative.Y * 0.5)
	segment.Size = UDim2.new(0, mag, 0, 5)
	segment.BorderSizePixel = 0
	segment.AnchorPoint = Vector2.new(0.5, 0.5)
	segment.Name = "Segment/Edge"
	segment.BackgroundColor3 = Color3.fromRGB(17, 88, 255)
	segment.Parent = parent
	
	return segment
end

local frame = urFrame or Instance.new("Frame")

delaunay.iterate(results, function(triangle) -- pass an anonymous function as callback
	local edge1, edge2, edge3 = unpack(triangle)

	linkPoints(frame, Vector2.new(edge1.x, edge1.y), Vector2.new(edge2.x, edge2.y))
	linkPoints(frame, Vector2.new(edge2.x, edge2.y), Vector2.new(edge3.x, edge3.y))
	linkPoints(frame, Vector2.new(edge3.x, edge3.y), Vector2.new(edge1.x, edge1.y))
end, true)
```

*Note that this library only works with 2D coordinates, if you wish to apply this library in 3D, project the set of coordinates onto an infinite plante using stereographic coordinates, then run the library again. Once you computed the results you just wrap the results from the infinite plane back onto your object* [[1]](https://www.redblobgames.com/x/1842-delaunay-voronoi-sphere/)


## [Benchmarking](/tests/StarterPlayerScripts/LocalScript)

### DISCLAIMER: The following samples might not be very accurate as it was tested within Roblox Studio, therefore they should only be regarded as an approximate reference. The runtime can vary over different lua environments.

> **Note**
> Benchmark hardware specs: *Intel core i5 4460 @ 3.2GHz, 8GB DDR3-1600MHz, NVidia GT705, Windows 10 64-bit*

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

This implementation is based on a traditional O(n * log n * n) divide-and-conquer algorithm described [there](https://github.com/Bathlamos/delaunay-triangulation) that is surprisingly doing the job with dense points set. The [QuadEdge data structure](http://www.cs.cmu.edu/afs/andrew/scs/cs/15-463/2001/pub/src/a2/quadedge.html) came in handy when navigating the triangulation's topology, whilst still greatly minizing the amount of metamethods invoked.

## Convex hull

This library is also provided with [convexHull.lua](/convexHull.lua), which solves a convex hull of a given a set of 2-dimensional points.
The implementation follows the same logic and datastructure as the main file [(source)](https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain)

## Addendum

This module doesn't support native lua, it was written in Luau fashion (roblox) which occasionally uses the extended Roblox syntax,
running this piece of code in a native lua interpreter will raise a syntax error.

Although, if you have little knowledge with luau you should be able to make it work, as luau features
the C++ assignment operators and typechecking.

Be aware that the metatables might behave differently in some cases - you might want to make tweak the Quad Edge datastructure implementation to make it work.

## Acknowledgements

@Bathlamos for the [original library](https://github.com/Bathlamos/delaunay-triangulation)

[Another delaunay lua implementation](https://github.com/Nolan-O/LuaDelaunayTriangulation) for some of the wording

Quad-Edge article : http://www.cs.cmu.edu/afs/andrew/scs/cs/15-463/2001/pub/src/a2/quadedge.html

<br>

### To-do list:

- [ ] Additional sanity checks
- [ ] Add Voronoi support
- [ ] Eventually implement a faster sorting algorithm for large arrays
