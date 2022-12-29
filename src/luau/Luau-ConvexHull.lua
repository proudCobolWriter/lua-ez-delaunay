--!nonstrict

--[[ 
	THIS WORK IS PROTECTED BY THE GNU AFFERO GENERAL PUBLIC LICENSE, CHECK THE LICENSE FOR FURTHER NOTICE
	
	@Luau-ConvexHull
	API:
		
		### Special types

			type Point = {
				x: number,
				y: number
			}
			^ Stores 2 dimensional vector data in a dictionary (=hashtable) containing ["x"] and ["y"] keys
			* This type is not exported, meaning you have to access it by requiring Luau-TypeDefinitions.lua

			type Array<T> = { [number]: T }
			^ Generic array-like table type
			* This type is not exported, meaning you have to access it by requiring Luau-TypeDefinitions.lua
		
		### Functions
		
			function convexHull2D ( pointsArray: Array<Point> ): Array<Point> | false
				 ^ Constructs the convex hull of a set of 2-dimensional points
				 * source: https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain
				 *
				 * @param pointsArray an Array containing a set of Points
				 *
				 * @return if successful: an array-like table of the polygon boundaries (convex hull in other terms), also contains a set of Points
				 * @return if not: false
	

		ADDENDUM: @Luau-ConvexHull doesn't support native lua as it was written in a pure Luau fashion (meant for Roblox) which occasionally involves the use the extended Roblox Luau syntax (including type checking and special operators).
			  Running this piece of code in a native lua interpreter will raise a syntax error.

]]

local SAFE_MODE = true -- same as for Luau_Delaunay, keep it as true if you want the convexHull2D function to run in a protected call (meaning that any exceptions will be caught)

-- TYPE DEFINITIONS

local TypeDefinitions = require(script.Parent:WaitForChild("Luau-TypeDefinitions.lua"))

type Point = TypeDefinitions.Point
type Array<T> = TypeDefinitions.Array<T>

-- STATIC FUNCTIONS

local function cross(a: Point, b: Point, o: Point): number
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
end

local function merge<T>(tbl1: Array<T?>, tbl2: Array<T?>): Array<T?>
	local newArray = tbl1 :: Array<T?>

	for _, el in pairs(tbl2) do
		table.insert(newArray, el)
	end

	return newArray
end


return {
	--[[ function convexHull2D ( pointsArray: Array<Point> ): Array<Point> | false
		      ^ Constructs the convex hull of a set of 2-dimensional points
		      * source: https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain
		      *
		      * @param pointsArray an Array containing a set of Points
		      *
		      * @return if successful: an array-like table of the polygon boundaries (convex hull in other terms), also contains a set of Points
		      * @return if not: false
	]]
	convexHull2D = function(pointsArray: Array<Point>): Array<Point> | false
		local compute = function()
			assert(typeof(pointsArray) == "table", "Script prompted error : an array-like table of Points must be passed to function triangulate")
			
			local pointsSet = pointsArray
			local sortedArray = pointsArray
			
			table.sort(sortedArray, function(a, b)
				return a.x == b.x and a.y < b.y or a.x < b.x
			end)

			local lower = {}

			for i = 0, #sortedArray - 1 do
				while (#lower >= 2 and cross(lower[#lower - 2 + 1], lower[#lower - 1 + 1], pointsSet[i + 1]) <= 0) do
					table.remove(lower, #lower) -- equivalent function of ArrayPrototype.pop() in js
				end
				table.insert(lower, pointsSet[i + 1])
			end

			local upper = {}

			local _i = #pointsSet - 1
			while _i >= 0 do
				while (#upper >= 2 and cross(upper[#upper - 2 + 1], upper[#upper - 1 + 1], pointsSet[_i + 1]) <= 0) do
					table.remove(upper, #upper) -- equivalent function of ArrayPrototype.pop() in js
				end
				table.insert(upper, pointsSet[_i + 1])
				_i-=1
			end

			table.remove(lower, #lower) -- equivalent function of ArrayPrototype.pop() in js
			table.remove(upper, #upper) -- equivalent function of ArrayPrototype.pop() in js
			
			return merge(upper, lower)
		end
		
		if SAFE_MODE then
			-- Catch eventual error(s)
			local success, results = xpcall(compute, function(e)
				local traceback = debug.traceback()
				local indent = string.rep(" ", 5 * 3 + 3)

				local exceptioncode = string.match(e, ":(.+)")
				exceptioncode = exceptioncode:sub(5, #exceptioncode)
				
				print(("Caught exception:  %s\n%s%s"):format(exceptioncode, indent, ({string.gsub(traceback, "\n", "\n" .. indent)})[1] ))
			end)

			return success and results
		else
			return compute()
		end
		
		
	end,

}
