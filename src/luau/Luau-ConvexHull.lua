return {
	--[[ ConvexHull2D function
		 * Constructs the convex hull of a set of 2-dimensional points in O(n log n) time
		 * source: https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain
		 *
		 * @param points an array-like table containing a set of 2D points
		 *
		 * @return an array-like table of the polygon boundaries
	]]
	convexHull2D = function(points)
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
		
		local pointsSet = points
		local sortedArray = points
		table.sort(sortedArray, function(a, b)
			return a.x == b.x and a.y < b.y or a.x < b.x
		end)
		
		local lower = {}
		
		for i = 0, #sortedArray - 1 do
			while (#lower >= 2 and cross(lower[#lower - 2 + 1], lower[#lower - 1 + 1], pointsSet[i + 1]) <= 0) do
				table.remove(lower, #lower) -- equivalent function of ArrayPrototype.pop()
			end
			table.insert(lower, pointsSet[i + 1])
		end
		
		local upper = {}
		
		local _i = #pointsSet - 1
		while _i >= 0 do
			while (#upper >= 2 and cross(upper[#upper - 2 + 1], upper[#upper - 1 + 1], pointsSet[_i + 1]) <= 0) do
				table.remove(upper, #upper) -- equivalent function of ArrayPrototype.pop()
			end
			table.insert(upper, pointsSet[_i + 1])
			_i-=1
		end
		
		table.remove(lower, #lower) -- equivalent function of ArrayPrototype.pop()
		table.remove(upper, #upper) -- equivalent function of ArrayPrototype.pop()
		return merge(upper, lower)
	end,
	
}
