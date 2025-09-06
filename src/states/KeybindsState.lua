KeybindsState = Class { __includes = BaseState }

local highlighted = 1
local waitingForKey = false
local currentBinding = nil

function KeybindsState:enter(params)
end

function KeybindsState:update(dt)
    if waitingForKey then
        -- Wait for any key press
        for key, _ in pairs(love.keyboard.keysPressed) do
            if key ~= 'escape' then
                gKeyBindings[currentBinding] = key
                waitingForKey = false
                currentBinding = nil
                saveKeyBindings()
                gSounds['confirm']:play()
                return
            end
        end
        
        if love.keyboard.wasPressed('escape') then
            waitingForKey = false
            currentBinding = nil
            gSounds['no-select']:play()
        end
        return
    end

    if love.keyboard.wasPressed('up') then
        highlighted = highlighted > 1 and highlighted - 1 or 5
        gSounds['paddle-hit']:play()
    elseif love.keyboard.wasPressed('down') then
        highlighted = highlighted < 5 and highlighted + 1 or 1
        gSounds['paddle-hit']:play()
    end

    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        if highlighted == 5 then
            -- BACK option
            gStateMachine:change('options', {
            })
        else
            -- Start binding a key
            waitingForKey = true
            currentBinding = self:getBindingForHighlight()
            gSounds['select']:play()
        end
    end

    if love.keyboard.wasPressed('escape') then
        gStateMachine:change('options')
    end
end

function KeybindsState:getBindingForHighlight()
    if highlighted == 1 then return 'paddleLeft'
    elseif highlighted == 2 then return 'paddleRight'
    elseif highlighted == 3 then return 'tiltLeft'
    elseif highlighted == 4 then return 'tiltRight'
    else return nil end
end

function KeybindsState:render()
    love.graphics.setFont(gFonts['large'])
    -- Draw shadow first
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("KEYBINDS", 1, 21, VIRTUAL_WIDTH, 'center')
    -- Draw main text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("KEYBINDS", 0, 20, VIRTUAL_WIDTH, 'center')
    
    love.graphics.setFont(gFonts['medium'])
    
    -- Paddle Left
    local yPos = 80
    self:renderBindingOption("Paddle Left:", gKeyBindings.paddleLeft, 1, yPos)
    
    -- Paddle Right
    yPos = yPos + 30
    self:renderBindingOption("Paddle Right:", gKeyBindings.paddleRight, 2, yPos)
    
    -- Tilt Left
    yPos = yPos + 30
    self:renderBindingOption("Tilt Left:", gKeyBindings.tiltLeft, 3, yPos)
    
    -- Tilt Right
    yPos = yPos + 30
    self:renderBindingOption("Tilt Right:", gKeyBindings.tiltRight, 4, yPos)
    
    -- BACK option
    yPos = yPos + 40
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("BACK", 1, yPos + 1, VIRTUAL_WIDTH, 'center')
    if highlighted == 5 then
        love.graphics.setColor(103 / 255, 1, 1, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.printf("BACK", 0, yPos, VIRTUAL_WIDTH, 'center')
    
    -- Instructions
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0, 0, 0, 0.5)
    if waitingForKey then
        love.graphics.printf("Press any key to bind...", 0, VIRTUAL_HEIGHT - 175, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press ESC to cancel", 0, VIRTUAL_HEIGHT - 185, VIRTUAL_WIDTH, 'center')
    else
        love.graphics.printf("Press ENTER to change key binding", 0, VIRTUAL_HEIGHT - 185, VIRTUAL_WIDTH, 'center')
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function KeybindsState:renderBindingOption(label, key, optionIndex, yPos)
    -- Draw shadow first
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf(label, 1, yPos + 1, VIRTUAL_WIDTH / 2 - 20, 'right')
    love.graphics.printf(key:upper(), VIRTUAL_WIDTH / 2 + 1, yPos + 1, VIRTUAL_WIDTH / 2 - 20, 'left')
    
    -- Draw main text
    if highlighted == optionIndex then
        love.graphics.setColor(103 / 255, 1, 1, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.printf(label, 0, yPos, VIRTUAL_WIDTH / 2 - 20, 'right')
    love.graphics.printf(key:upper(), VIRTUAL_WIDTH / 2, yPos, VIRTUAL_WIDTH / 2 - 20, 'left')
end 