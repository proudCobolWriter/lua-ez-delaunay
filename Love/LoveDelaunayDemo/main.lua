local MINIMUM_POINTS = 3 -- the minimum to form a triangle
local MAXIMUM_POINTS = 300 -- the maximum amount of points that we can generate

local points = {} -- contains points in 2-dimensional space
local cachedColors = {} -- this table's purpose is to save the rgb segment colors
local delaunayResults = {} -- stores triangulate function results
local theme = "Dark" -- color scheme, either "Dark" or "Light"

local function randomPoints(iterations) -- Generates a random set of 2D points with maximum x and y the window dimensions
    local tbl = {}
    
    for i = 1, iterations do
        local x, y = love.graphics.getDimensions()

        tbl[#tbl + 1] = {x = math.random() * x * 0.90, y = math.random() * y * 0.90} -- append the point to the table
    end
    return tbl
end

local function compute(newPoints)
    math.randomseed(os.clock())

    if newPoints then
        points = {}
        points = randomPoints(newPoints)

        print("Generated " .. #points .. " points")
    end
    delaunayResults = delaunay.triangulate(points)
end

function love.load() -- Init function
    love.window.setTitle("Delaunay triangulation demo")
    delaunay = require("Lua-Delaunay")

    compute(3)
end

function love.draw()
    local screenX, screenY = love.graphics.getDimensions()

    love.graphics.setLineWidth(4)
    love.graphics.setBackgroundColor(theme == "Dark" and { 0, 0, 0 } or { 1, 1, 1 })

    local i = 0
    delaunay.iterate(delaunayResults, function(triangle) -- pass an anonymous function as callback
        i = i + 1
        if not cachedColors[i] then cachedColors[i] = { math.random(), math.random(), math.random() } end

        local point1, point2, point3 = unpack(triangle)
        if not point1 or not point2 or not point3 then return end

        love.graphics.setColor(cachedColors[i])
        love.graphics.line(point1.x + screenX * 0.05 + 5, point1.y + screenY * 0.10 + 5, point2.x + screenX * 0.05 + 5, point2.y + screenY * 0.10 + 5)
        love.graphics.line(point2.x + screenX * 0.05 + 5, point2.y + screenY * 0.10 + 5, point3.x + screenX * 0.05 + 5, point3.y + screenY * 0.10 + 5)
        love.graphics.line(point3.x + screenX * 0.05 + 5, point3.y + screenY * 0.10 + 5, point1.x + screenX * 0.05 + 5, point1.y + screenY * 0.10 + 5)
    end, false)

    love.graphics.setColor(theme == "Dark" and { 1, 1, 1 } or { 0, 0, 0 })

    for _, point in ipairs(points) do -- Draw on top of the lines, kinda mimics the Roblox property ZIndex if it was set to 100
        local x, y = point.x, point.y
        if not x or not y then return end

        love.graphics.rectangle("fill", x + screenX * 0.05, y + screenY * 0.10, 10, 10)
    end

    love.graphics.print("LMB - Switch color theme\nRMB - Add point\nMMB - Regenerate random points", 5, 5)
end

function love.mousepressed(x, y, button) -- Switches from dark theme to light theme and vice versa
    if button == 1 then
        theme = theme == "Dark" and "Light" or "Dark"
        love.window.setTitle(theme .. " Theme")
    elseif button == 2 then
        local screenX, screenY = love.graphics.getDimensions()

        table.insert(points, { x = x - screenX * 0.05, y = y - screenY * 0.10 })
        compute()

        print(string.format("Added point at location : x%i y%i", x, y))
    elseif button == 3 then
        compute( math.random() * (MAXIMUM_POINTS - MINIMUM_POINTS) + MINIMUM_POINTS )
    end
end
