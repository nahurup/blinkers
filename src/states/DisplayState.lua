DisplayState = Class { __includes = BaseState }

local highlighted = 1

function DisplayState:enter(params)
end

function DisplayState:update(dt)
    if love.keyboard.wasPressed('up') or love.keyboard.wasPressed('down') then
        highlighted = highlighted == 1 and 2 or 1
        gSounds['paddle-hit']:play()
    end

    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gSounds['confirm']:play()
        if highlighted == 1 then
            -- Toggle fullscreen
            local fullscreen = love.window.getFullscreen()
            love.window.setFullscreen(not fullscreen)
            -- Save the setting
            love.filesystem.setIdentity('blinkers')
            love.filesystem.write('fullscreen.txt', tostring(not fullscreen))
        else
            gStateMachine:change('options', {
            })
        end
    end

    if love.keyboard.wasPressed('escape') then
        gStateMachine:change('options')
    end
end

function DisplayState:render()
    love.graphics.setFont(gFonts['large'])
    -- Draw shadow first
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("DISPLAY", 1, 21, VIRTUAL_WIDTH, 'center')
    -- Draw main text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("DISPLAY", 0, 20, VIRTUAL_WIDTH, 'center')
    
    love.graphics.setFont(gFonts['medium'])
    
    -- Current mode display
    local currentMode = love.window.getFullscreen() and "FULLSCREEN" or "WINDOWED"
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("Current: " .. currentMode, 1, 61, VIRTUAL_WIDTH, 'center')
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.printf("Current: " .. currentMode, 0, 60, VIRTUAL_WIDTH, 'center')
    
    -- Toggle option
    local yPos = 100
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("TOGGLE MODE", 1, yPos + 1, VIRTUAL_WIDTH, 'center')
    if highlighted == 1 then
        love.graphics.setColor(103 / 255, 1, 1, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.printf("TOGGLE MODE", 0, yPos, VIRTUAL_WIDTH, 'center')
    
    -- BACK option
    yPos = yPos + 40
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("BACK", 1, yPos + 1, VIRTUAL_WIDTH, 'center')
    if highlighted == 2 then
        love.graphics.setColor(103 / 255, 1, 1, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.printf("BACK", 0, yPos, VIRTUAL_WIDTH, 'center')
    
    -- Instructions
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("Press ENTER to change display mode", 0, VIRTUAL_HEIGHT - 25, VIRTUAL_WIDTH, 'center')
    
    love.graphics.setColor(1, 1, 1, 1)
end 