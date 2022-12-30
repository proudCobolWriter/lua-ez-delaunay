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

local function generate()
    math.randomseed(os.clock())

    points = randomPoints( math.random() * (MAXIMUM_POINTS - MINIMUM_POINTS) + MINIMUM_POINTS )
    delaunayResults = delaunay.triangulate(points)

    print("Generated " .. #points .. " points")
end

function love.load() -- Init function
    love.window.setTitle("Delaunay triangulation demo")
    delaunay = require("Lua-Delaunay")

    generate()
end

function love.draw()
    local screenX, screenY = love.graphics.getDimensions()

    love.graphics.setLineWidth(4)
    love.graphics.setBackgroundColor(theme == "Dark" and { 0, 0, 0 } or { 1, 1, 1 })

    local i = 0
    delaunay.iterate(delaunayResults, function(triangle) -- pass an anonymous function as callback
        i = i + 1
        if not cachedColors[i] then cachedColors[i] = { math.random(), math.random(), math.random() } end

        local edge1, edge2, edge3 = triangle[1], triangle[2], triangle[3]
        if not edge1 or not edge2 or not edge3 then return end

        love.graphics.setColor(cachedColors[i])
        love.graphics.line(edge1.x + screenX * 0.05 + 5, edge1.y + screenY * 0.05 + 5, edge2.x + screenX * 0.05 + 5, edge2.y + screenY * 0.05 + 5)
        love.graphics.line(edge2.x + screenX * 0.05 + 5, edge2.y + screenY * 0.05 + 5, edge3.x + screenX * 0.05 + 5, edge3.y + screenY * 0.05 + 5)
        love.graphics.line(edge3.x + screenX * 0.05 + 5, edge3.y + screenY * 0.05 + 5, edge1.x + screenX * 0.05 + 5, edge1.y + screenY * 0.05 + 5)
    end, false)

    love.graphics.setColor(theme == "Dark" and { 1, 1, 1 } or { 0, 0, 0 })

    for _, point in ipairs(points) do -- Draw on top of the lines, kinda mimics the Roblox property ZIndex if it was set to 100
        local x, y = point.x, point.y
        if not x or not y then return end

        love.graphics.rectangle("fill", x + screenX * 0.05, y + screenY * 0.05, 10, 10)
    end

    love.graphics.print(" LMB - Switch color theme\n RMB - Regenerate points")
end

function love.mousepressed(_, _, button) -- Switches from dark theme to light theme and vice versa
    if button == 1 then
        theme = theme == "Dark" and "Light" or "Dark"
        love.window.setTitle(theme .. " Theme")
    elseif button == 2 then
        generate()
    end
end
