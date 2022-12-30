--[[ 
	THIS WORK IS PROTECTED BY THE GNU AFFERO GENERAL PUBLIC LICENSE, CHECK THE LICENSE FOR FURTHER NOTICE
	
	This is a ported version of the ``delaunay-triangulation`` library in js
	Pardon me if the code looks like spaghetti, there's for sure a lot of cleaning up and adjustments to do
	
	I'll eventually make my own implementation which will provide extra functions and a better algorithm performance-wise, but as of writing it satisfies my needs for my project I used it for
	~~also blame the js repo owner for the messy maths lol~~
	
	I didn't plan to use classes for this project, but it was quickly becoming a mess so I decided to do otherwise,
	I wish it won't cause any considerable performance issue.
	
	@Lua-Delaunay
	API:
		
		### Check the Github readme to learn more about the type annotations used: https://github.com/proudCobolWriter/lua-ez-delaunay
		
		### Functions
		
			function triangulate ( pointsArray: Array<Point> ): Array<Point> | false
				 ^ Init function, computes Guibas & Stolfi's divide-and-conquer algorithm
				 *
				 * @param pointsArray an Array containing Points
				 ** 	  ^example: { {x = 0, y = 0}, {x = 1, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}, {x = 0, y = 1}, {x = 1, y = 0} }
				 *
				 * @return if successful: an array-like table containing face data
				 * @return if not: false
			function iterate ( facesArray: Array<Point>, callback: ( Array<Point> ) -> nil, defer: boolean ): Array<{ Array<Point>? }>
				 ^ Customizable shortcut function that reads through data returned by function triangulate
				 *
				 * @param facesArray an Array containing Points
				 * @param callback an anonymous function that gets called for every triangles processed, should always return void
				 * @param defer defines whether or not we should make use of the built-in roblox ``task`` lib
				 *
				 * @return an array-like table containing (empty?) Arrays representing triangles (each containing 3 points)

]]

local SAFE_MODE = true -- keep it as true if you want the triangulate function to run in a protected call (meaning that any exceptions will be caught)
local PRINT_DUPLICATES = true -- true by default
local BIG_INT = 10 * 10 ^ 8 -- while it's called an int value in the variable name to make it clearer, lua only features a "number" (float64) primitive type that allows for both integer-like and float-like numbers

-- DEFINE QUADEDGE

local _quadEdgeCache = {}

_quadEdgeCache.__index = _quadEdgeCache
_quadEdgeCache.__eq = function(a, b)
	-- Compare memory addresses, keep in mind that those are fake and don't correspond to the metatables' memory addresses.

	return rawequal(a.address, b.address)
end
_quadEdgeCache.__tostring = function(t)
	-- to make it more ergonomic readability-wise
	local onext = rawget(t, "onext")
	local orig  = rawget(t, "orig")
	local rot   = rawget(t, "rot")

	return ("type %s\n		orig:  {x: %s, y: %s}\n		onext: {x: %s, y: %s}\n		rot:   {x: %s, y: %s}\n"):format("QuadEdge", 
		orig and orig.x or "nil", orig and orig.y or "nil",
		onext and (onext.orig and onext.orig.x or "nil") or "nil", onext and (onext.orig and onext.orig.y or "nil") or "nil",
		rot and (rot.orig and rot.orig.x or "nil") or "nil", rot and (rot.orig and rot.orig.y or "nil") or "nil"
	)
end

-- DEFINE QUADEDGE CONSTRUCTOR

--[[
function QuadEdge ( ...:  boolean? | QuadEdge? | Point? ): QuadEdge
	 ^ Constructor function of class QuadEdge
	 *
	 * @param tuple defines onext, rot and orig
	 *
	 * @return QuadEdge
]]
function QuadEdge(...)
	local onext, rot, orig = ...

	local self = setmetatable({}, _quadEdgeCache)
	self.onext = onext -- QuadEdge
	self.mark = false
	self.orig = orig -- Point
	self.rot = rot -- QuadEdge


	self.address = tostring({}) -- not sure if it's the best way to do it

	return self
end

-- DEFINE QUADEDGE METHODS

function _quadEdgeCache:getSym()
	return self.rot.rot
end

function _quadEdgeCache:getDest()
	return self:getSym().orig
end

function _quadEdgeCache:getRotSym()
	return self.rot:getSym()
end

function _quadEdgeCache:getOprev()
	return self.rot.onext.rot
end

function _quadEdgeCache:getDprev()
	return self:getRotSym().onext:getRotSym()
end

function _quadEdgeCache:getLnext()
	return self:getRotSym().onext.rot
end

function _quadEdgeCache:getLprev()
	return self.onext:getSym()
end

function _quadEdgeCache:getRprev()
	return self:getSym().onext
end

-- STATIC FUNCTIONS

--[[
function ccw ( a: Point, b: Point, c: Point ): boolean
	 ^ Computes | a.x  a.y  1 |
               	    | b.x  b.y  1 | > 0
               	    | c.x  c.y  1 |
	 *
	 * @param a Point
	 * @param b Point
	 * @param c Point
	 *
	 * @return boolean
]]
local function ccw(a, b, c)
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x) > 0
end

local function rightOf(x, e)
	return ccw(x, e:getDest(), e.orig)
end

local function leftOf(x, e)
	return ccw(x, e.orig, e:getDest())
end

local function valid(e, base1)
	return rightOf(e:getDest(), base1)
end

--[[
function inCircle ( a: Point, b: Point, c: Point, d: Point ): boolean
	 ^ Computes  | a.x  a.y  a.x²+a.y²  1 |
		     | b.x  b.y  b.x²+b.y²  1 | > 0
		     | c.x  c.y  c.x²+c.y²  1 |
		     | d.x  d.y  d.x²+d.y²  1 |
	
	 * Return true is d is in the circumcircle of a, b, c
	 *
	 * @param a Point
	 * @param b Point
	 * @param c Point
	 * @param d Point
	 *
	 * @return boolean
]]
local function inCircle(a, b, c, d)
	if ((a.x == d.x and a.y == d.y)
		or (b.x == d.x and b.y == d.y)
		or (c.x == d.x and c.y == d.y)) then return false
	end

	local sa = a.x * a.x + a.y * a.y
	local sb = b.x * b.x + b.y * b.y
	local sc = c.x * c.x + c.y * c.y
	local sd = d.x * d.x + d.y * d.y

	local d1 = sc - sd
	local d2 = c.y - d.y
	local d3 = c.y * sd - sc * d.y
	local d4 = c.x - d.x
	local d5 = c.x * sd - sc * d.x
	local d6 = c.x * d.y - c.y * d.x

	return a.x * (b.y * d1 - sb * d2 + d3)
	- a.y * (b.x * d1 - sb * d4 + d5)
		+ sa * (b.x * d2 - b.y * d4 + d6)
	- b.x * d3 + b.y * d5 - sb * d6 > 1

end

local function makeEdge(orig, dest)
	local q0 = QuadEdge(nil, nil, orig)
	local q1 = QuadEdge(nil, nil,  nil)
	local q2 = QuadEdge(nil, nil, dest)
	local q3 = QuadEdge(nil, nil,  nil)

	-- create segment
	q0.onext = q0; q2.onext = q2 -- lonely segment: no "next" quadedge
	q1.onext = q3; q3.onext = q1 -- in the dual: 2 communicating facets

	-- dual switch
	q0.rot = q1; q1.rot = q2
	q2.rot = q3; q3.rot = q0

	return q0
end

--[[
function splice ( a: QuadEdge, b: QuadEdge ): nil
	 ^ Attach/detach the two QuadEdges = combine/split the two rings in the dual space
	 *
	 * @param a the first QuadEdge to attach/detach
	 * @param b the second QuadEdge to attach/detach
	 *
	 * @return void
]]
local function splice(a, b)
	local alpha, beta = a.onext.rot, b.onext.rot
	local t2, t3, t4 = a.onext, beta.onext, alpha.onext

	a.onext = b.onext
	b.onext = t2
	alpha.onext = t3
	beta.onext = t4

	return
end

--[[
function connect ( a: QuadEdge, b: QuadEdge ): QuadEdge
	 ^ Create a new QuadEdge by connecting 2 QuadEdges
	 *
	 * @param a the first QuadEdge to connect
	 * @param b the second QuadEdge to connect
	 *
	 * @return the new QuadEdge
]]
local function connect(a, b)
	local q = makeEdge(a:getDest(), b.orig)

	splice(q, a:getLnext())
	splice(q:getSym(), b)

	return q
end

local function deleteEdge(q)
	splice(q, q:getOprev())
	splice(q:getSym(), q:getSym():getOprev())
	
	return
end

--[[
function intSplice<T> ( tbl: Array<T>, start: number, length: number ): ...Array<T>
	 ^ Equivalent function for js Array.prototype.splice
	 * Source: https://github.com/torch/xlua/blob/master/init.lua#L640
	 *
	 * @param tbl an array-like table of type T
	 * @param start number
	 * @param length number
	 *
	 * @return an array-like table containing the spliced result and the remainder
]]
local function intSlice(tbl, start, length)
	local endd = start + length
	local spliced = {}
	local remainder = {}

	for i, elt in ipairs(tbl) do
		if i < start or i >= endd then
			table.insert(spliced, elt)
		else
			table.insert(remainder, elt)
		end
	end

	return spliced, remainder
end

local function delaunay(s)
	local a, b, c, t
	
	if (#s == 2) then
		a = makeEdge(s[1], s[2])

		return {
			le = a,
			re = a:getSym()
		}
	elseif (#s == 3) then
		a = makeEdge(s[1], s[2])
		b = makeEdge(s[2], s[3])
		splice(a:getSym(), b)

		if (ccw(s[1], s[2], s[3])) then
			c = connect(b, a)

			return {
				le = a,
				re = b:getSym()
			}
		elseif (ccw(s[1], s[3], s[2])) then
			c = connect(b, a)

			return {
				le = c:getSym(),
				re = c
			}
		else -- All three points are colinear
			return {
				le = a,
				re = b:getSym()
			}
		end
	else -- |S| >= 4
		local half_length = math.ceil(#s / 2)
		local spliced_result, remainder_result = intSlice(s, 0, half_length + 1)
		local left = delaunay(remainder_result)
		local right = delaunay(spliced_result)

		local ldo = left.le
		local ldi = left.re
		local rdi = right.le
		local rdo = right.re

		-- Compute the lower common tangent of L and R
		while (true) do
			if (leftOf(rdi.orig, ldi)) then
				ldi = ldi:getLnext()
			elseif (rightOf(ldi.orig, rdi)) then
				rdi = rdi:getRprev()
			else
				break
			end
		end

		local basel = connect(rdi:getSym(), ldi)
		if(ldi.orig == ldo.orig) then
			ldo = basel:getSym()
		end

		if(rdi.orig == rdo.orig) then
			rdo = basel
		end

		-- This is the merge loop
		while (true) do
			-- Locate the first L point (lcand.Dest) to be encountered by the rising bubble,
			-- and delete L edges out of base1.Dest that fail the circle test.

			local lcand = basel:getSym().onext
			if (valid(lcand, basel)) then
				while (inCircle(basel:getDest(), basel.orig, lcand:getDest(), lcand.onext:getDest())) do
					t = lcand.onext
					deleteEdge(lcand)
					lcand = t
				end
			end

			-- Symmetrically, locate the first R point to be hit, and delete R edges
			local rcand = basel:getOprev()

			if (valid(rcand, basel)) then
				while (inCircle(basel:getDest(), basel.orig, rcand:getDest(), rcand:getOprev():getDest())) do
					t = rcand:getOprev()
					deleteEdge(rcand)
					rcand = t
				end
			end

			-- If both lcand and rcand are invalid, then basel is the upper common tangent
			if (not valid(lcand, basel) and not valid(rcand, basel)) then
				break
			end

			-- The next cross edge is to be connected to either lcand.Dest or rcand.Dest
			-- If both are valid, then choose the appropriate one using the InCircle test

			if (not valid(lcand, basel) or (valid(rcand, basel) and inCircle(lcand:getDest(), lcand.orig, rcand.orig, rcand:getDest() ))) then
				-- Add cross edge basel from rcand.Dest to basel.Dest

				basel = connect(rcand, basel:getSym())
			else
				-- Add cross edge base1 from basel.Org to lcand.Dest

				basel = connect(basel:getSym(), lcand:getSym())
			end
		end
		
		return {
			le = ldo,
			re = rdo
		}
	end
end


return {
	--[[
		function triangulate ( pointsArray: Array<Point> ): Array<Point> | false
			 ^ Init function, computes Guibas & Stolfi's divide-and-conquer algorithm
			 *
			 * @param pointsArray an Array containing Points
			 ** 	  ^example: { {x = 0, y = 0}, {x = 1, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}, {x = 0, y = 1}, {x = 1, y = 0} }
			 *
			 * @return if successful: an array-like table containing face data
                         * @return if not: false
	]]
	triangulate = function (pointsArray)
		local compute = function()
			assert(type(pointsArray) == "table", "Script prompted error : an array-like table of Points must be passed to function triangulate")

			local vertices = pointsArray
			
			-- We sort the vertices prior to the math
			table.sort(vertices, function(...)
				-- Query the array so a.x == b.x ? a.y < b.y : a.x < b.x
				-- (TODO?): eventually implement a faster algorithm, 
				--			but the traditional C-based algorithm does the job with small arrays

				local a, b = ...

				if (a.x == b.x) then
					return a.y < b.y
				end
				return a.x < b.x
			end)

			-- Make sure there are atleast 3 vertices (to form a triangle)
			assert(#vertices >= 3, "Script prompted error : pointsArray must contain atleast 3 or more Points")

			-- Get rid of the duplicates
			local i = #vertices
			local duplicates = 0

			while (i > 1) do
				if (vertices[i].x == vertices[i - 1].x and vertices[i].y == vertices[i - 1].y) then
					-- Found duplicate
					-- Take care of the duplicate that we just found using table.remove
					table.remove(vertices, i) -- Expensive operation, but there should be only a little duplicates
					duplicates = duplicates + 1
				end
				i = i - 1
			end
			
			if duplicates > 0 and PRINT_DUPLICATES then
				print(("Found %s duplicate%s"):format(tostring(duplicates), duplicates > 1 and "s" or ""))
			end

			local quadEdge = delaunay(vertices).le

			local faces = {}
			local queueIndex = 0
			local queue = {quadEdge}

			while (leftOf(quadEdge.onext:getDest(), quadEdge)) do
				quadEdge = quadEdge.onext
			end

			local curr = quadEdge

			local function _iterate()
				-- Append sym
				table.insert(queue, curr:getSym())

				curr.mark = true
				curr = curr:getLnext()
			end

			_iterate()
			while not (curr == quadEdge) do
				_iterate()
			end

			_iterate = function()
				queueIndex = queueIndex + 1
				local edge = queue[queueIndex - 1 + 1]
				-- since i++ returns the initial value, we just substract one so it behaves the same as the js module
				-- then we add back one because of the first indice in js of an array is 0 : whereas in lua the first index is 1

				if (not edge.mark) then
					-- Stores the edges for a visited triangle. Also pushes sym (neighbour) edges on stack to visit later.
					curr = edge

					local function _process()
						table.insert(faces, curr.orig)
						if (not curr:getSym().mark) then
							table.insert(queue, curr:getSym())
						end

						curr.mark = true
						curr = curr:getLnext()
					end

					_process()
					while not (curr == edge) do
						_process()
					end
				end
			end

			_iterate()
			while (queueIndex < #queue) do
				_iterate()
			end

			return faces
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

	--[[
		function iterate ( facesArray: Array<Point>, callback: ( Array<Point> ) -> nil, defer: boolean ): Array<{ Array<Point>? }>
			 ^ Customizable shortcut function that reads through data returned by function triangulate
			 *
			 * @param facesArray an Array containing Points
			 * @param callback an anonymous function that gets called for every triangles processed, should always return void
			 * @param defer defines whether or not we should make use of the built-in roblox ``task`` lib
			 *
			 * @return an array-like table containing (empty?) Arrays representing triangles (each containing 3 points)
	]]
	iterate = function(facesArray, callback, defer)
		local triangles = {}

		for index = 1, #facesArray, 3 do
			local edge  = facesArray[index]
			local edge1 = facesArray[index + 1]
			local edge2 = facesArray[index + 2]

			triangles[#triangles + 1] = {edge, edge1, edge2} -- append the triangle
			if callback and defer then task.defer(callback, {edge, edge1, edge2}) elseif callback and not defer then callback({edge, edge1, edge2}) end
		end

		return triangles
	end
	
}
