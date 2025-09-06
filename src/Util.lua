function GenerateQuads(atlas, tilewidth, tileheight)
    local sheetWidth = atlas:getWidth() / tilewidth
    local sheetHeight = atlas:getHeight() / tileheight

    local sheetCounter = 1
    local spritesheet = {}

    for y = 0, sheetHeight - 1 do
        for x = 0, sheetWidth - 1 do
            spritesheet[sheetCounter] = love.graphics.newQuad(x * tilewidth, y * tileheight, tilewidth, tileheight, atlas:getDimensions())
            sheetCounter = sheetCounter + 1
        end
    end

    return spritesheet
end

function table.slice(tbl, first, last, step)
    local sliced = {}
    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced + 1] = tbl[i]
    end
    return sliced
end

function GeneratePaddle(atlas)
    local quads = {}
    
    quads[1] = love.graphics.newQuad(0, 0, 64, 14, atlas:getDimensions())
    
    return quads
end

function GenerateBalls(atlas)
    local quads = {}

    -- Blue ball (0,16): 8x8 pixels
    quads[1] = love.graphics.newQuad(0, 14, 8, 8, atlas:getDimensions())
    
    -- Yellow ball (0,24): 8x6 pixels
    quads[2] = love.graphics.newQuad(0, 22, 8, 8, atlas:getDimensions())

    return quads
end
