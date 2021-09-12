# Divide-and-conquer Delaunay triangulation

A light ported version of the [delaunay-triangulation](https://github.com/Bathlamos/delaunay-triangulation) library written in ``js``

## API

```javascript
void triangulate ( pointsArray: table )
	* @param pointsArray contains a list of dictionaries as {[string]: float}
	*
	* @return an array-like table containing the faces
			
void iterate (tbl: table, callback: <void>, multithread: boolean)
	 * Just another useless util function for ease of use-
	 *
	 * @param tbl array-like table containing the edges
     	 * @param callback (void) function that gets called for each triangle processed
     	 * @param multithread defines whether we use the built-in roblox ``task`` lib
     	 *
     	 * @return array-like table containing a set of 3 edges (x: float, y: float) each

```

## Example usages

*Standard usage*

```lua
local delaunay = require(--[[ path to the module ]]))
   
local function randomPoints(iterations)
	local points = table.create(iterations) -- generate an array-like table
    
    for i = 1, iterations do
    	iterations[#iterations + 1] = {x = math.random() * 1000, y = math.random() * 1000} -- append the point to the table
    end
    
    return points
end

-- Given a set of tables containing 2D points, we can call delaunay.triangulate and pass our set of points

local results = delaunay.triangulate( randomPoints(100) ) -- should take approximatively 0.01 second
```

*What it should look like in js*

```js
import module as delaunay

function randomPoints(iterations) {
	let points = []; // Construct array
   
   	for (let i = iterations; i > 0; i--) points.push({x: Math.random() * 1000, y: Math.random() * 1000});
    return points
};

delaunay.triangulate( randomPoints(100) );
```

*Use case for the ``iterate`` function*
```lua
local delaunay = require(--[[ path to the module ]]))
local results = delaunay.triangulate( randomPoints(100) ) -- should take approximatively 0.01 second

local function linkPoints(parent, p1, p2, size)
	local segment = Instance.new("Frame")
	local relative = p2 - p1
	local angle = math.atan2(relative.Y, relative.X)
	local mag = (relative.X ^ 2 + relative.Y ^ 2) ^ 0.5
	
	segment.Rotation = math.deg(angle)
	segment.Position = UDim2.new(0.1, p1.X + relative.X * 0.5, 0.1, p1.Y + relative.Y * 0.5)
	segment.Size = UDim2.new(0, mag, 0, size or 7)
	segment.BorderSizePixel = 0
	segment.AnchorPoint = Vector2.new(0.5, 0.5)
	segment.Name = "Segment/Edge"
	segment.BackgroundColor3 = Color3.fromRGB(17, 88, 255)
	segment.Parent = parent
	
	
	return segment
end

local frame = urFrame or Instance.new("Frame")

delaunay.iterate( results, function(triangle) -- pass an anonymous function as callback
    local half_edge1, half_edge2, half_edge3 = triangle[1], triangle[2], triangle[3]
    
    linkPoints(frame, Vector2.new(half_edge1.x, half_edge1.y), Vector2.new(half_edge2.x, half_edge2.y), stroke or 5)
    linkPoints(frame, Vector2.new(half_edge2.x, half_edge2.y), Vector2.new(half_edge3.x, half_edge3.y), stroke or 5)
    linkPoints(frame, Vector2.new(half_edge3.x, half_edge3.y), Vector2.new(half_edge1.x, half_edge1.y), stroke or 5)
end, true)
```

*Note that this library only works with 2D coordinates, if you wish to apply this library in 3D, project the set of coordinates onto an infinite plante using stereographic coordinates, then run the library again. Once you computed the results you just wrap the results from the infinite plane back onto your object* [[1]](https://www.redblobgames.com/x/1842-delaunay-voronoi-sphere/)


## [Benchmarking](/tests/StarterPlayerScripts/LocalScript)

### DISCLAIMER: The following samples might not be very accurate as they were tested in Roblox, therefore they should only be used as a reference. The runtime can vary over different lua environments.

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

This implementation is based on a traditional O(n * log n * n) divide-and-conquer algorithm described [there](https://github.com/Bathlamos/delaunay-triangulation) which is surprisingly doing the job with dense points set. The [QuadEdge data structure](http://www.cs.cmu.edu/afs/andrew/scs/cs/15-463/2001/pub/src/a2/quadedge.html) came handy when navigating the triangulation's topology, while still greatly minizing the amount of metamethods invoked.

## Convex hull

This library is also provided with [convexHull.lua](/convexHull.lua), which solves a convex hull of a given a set of 2-dimensional points.
The implementation follows the same logic and datastructure as the main file [(source)](https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain)

## Abbendum

This module doesn't support native lua, it was written in Luau fashion (roblox) which occasionally uses the extended Roblox syntax
running this piece of code in a native lua interpreter will raise a syntax error

Although, if you have little knowledge with luau you should be able to make it work, as luau features
the C++ assignment operators and typechecking.

Be aware that the metatables might behave differently in some cases - you might want to make tweak the Quad Edge datastructure implementation to make it work.

## Acknowledgements

@Bathlamos for the [original library](https://github.com/Bathlamos/delaunay-triangulation)

[Another delaunay lua implementation](https://github.com/Nolan-O/LuaDelaunayTriangulation) for some of the wording

Quad-Edge article : https://github.com/Bathlamos/delaunay-triangulation)



- [ ] Additional sanity checks
- [ ] Add Voronoi support
- [ ] Eventually implement a faster sorting algorithm for large arrays
