OptionsState = Class { __includes = BaseState }

local highlighted = 1

function OptionsState:enter(params)
end

function OptionsState:update(dt)
    if love.keyboard.wasPressed('up') then
        highlighted = highlighted > 1 and highlighted - 1 or 3
        gSounds['paddle-hit']:play()
    elseif love.keyboard.wasPressed('down') then
        highlighted = highlighted < 3 and highlighted + 1 or 1
        gSounds['paddle-hit']:play()
    end

    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gSounds['confirm']:play()
        if highlighted == 1 then
            gStateMachine:change('keybinds', {
            })
        elseif highlighted == 2 then
            gStateMachine:change('display', {
            })
        else
            gStateMachine:change('start', {
            })
        end
    end

    if love.keyboard.wasPressed('escape') then
            gStateMachine:change('start')
    end
end

function OptionsState:render()
    love.graphics.setFont(gFonts['large'])
    -- Draw shadow first
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("OPTIONS", 1, VIRTUAL_HEIGHT / 3 + 1, VIRTUAL_WIDTH, 'center')
    -- Draw main text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("OPTIONS", 0, VIRTUAL_HEIGHT / 3, VIRTUAL_WIDTH, 'center')
    
    love.graphics.setFont(gFonts['medium'])
    -- Draw KEYBINDS shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("KEYBINDS", 1, VIRTUAL_HEIGHT / 2 + 51, VIRTUAL_WIDTH, 'center')
    -- Draw KEYBINDS text
    if highlighted == 1 then
        love.graphics.setColor(103 / 255, 1, 1, 1)
    else
        love.graphics.setColor(1, 1, 1, 255/255)
    end
    love.graphics.printf("KEYBINDS", 0, VIRTUAL_HEIGHT / 2 + 50, VIRTUAL_WIDTH, 'center')
    
    -- Draw DISPLAY shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("DISPLAY", 1, VIRTUAL_HEIGHT / 2 + 71, VIRTUAL_WIDTH, 'center')
    -- Draw DISPLAY text
    if highlighted == 2 then
        love.graphics.setColor(103 / 255, 1, 1, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.printf("DISPLAY", 0, VIRTUAL_HEIGHT / 2 + 70, VIRTUAL_WIDTH, 'center')
    
    -- Draw BACK shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("BACK", 1, VIRTUAL_HEIGHT / 2 + 91, VIRTUAL_WIDTH, 'center')
    -- Draw BACK text
    if highlighted == 3 then
        love.graphics.setColor(103 / 255, 1, 1, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.printf("BACK", 0, VIRTUAL_HEIGHT / 2 + 90, VIRTUAL_WIDTH, 'center')
    love.graphics.setColor(1, 1, 1, 1)
end 