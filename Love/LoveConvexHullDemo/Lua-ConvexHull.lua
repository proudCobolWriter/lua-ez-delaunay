--[[ 
	THIS WORK IS PROTECTED BY THE GNU AFFERO GENERAL PUBLIC LICENSE, CHECK THE LICENSE FOR FURTHER NOTICE
	
	@Lua-ConvexHull
	API:
		
		### Check the Github readme to learn more about the type annotations used: https://github.com/proudCobolWriter/lua-ez-delaunay
		
		### Functions
		
			function convexHull2D ( pointsArray: Array<Point> ): Array<Point> | false
				 ^ Constructs the convex hull of a set of 2-dimensional points
				 * source: https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain
				 *
				 * @param pointsArray an Array containing a set of Points
				 *
				 * @return if successful: an array-like table of the polygon boundaries (convex hull in other terms), also contains a set of Points
				 * @return if not: false

]]

local SAFE_MODE = true -- same as for @Lua_Delaunay, keep it as true if you want the convexHull2D function to run in a protected call (meaning that any exceptions will be caught)

-- STATIC FUNCTIONS

local function cross(a, b, o)
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
end

local function merge(tbl1, tbl2)
	local newArray = tbl1

	for _, el in pairs(tbl2) do
		table.insert(newArray, el)
	end

	return newArray
end


return {
	--[[ function convexHull2D ( pointsArray )
		      ^ Constructs the convex hull of a set of 2-dimensional points
		      * source: https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain
		      *
		      * @param pointsArray an Array containing a set of Points
		      *
		      * @return if successful: an array-like table of the polygon boundaries (convex hull in other terms), also contains a set of Points
		      * @return if not: false
	]]
	convexHull2D = function(pointsArray)
		local compute = function()
			assert(type(pointsArray) == "table", "Script prompted error : an array-like table of Points must be passed to function convexHull2D")
			
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
				_i = _i - 1
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