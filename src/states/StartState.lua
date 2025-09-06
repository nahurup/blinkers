StartState = Class { __includes = BaseState }

local highlighted = 1

function StartState:enter(params)
end

function StartState:update(dt)
    if love.keyboard.wasPressed('up') or love.keyboard.wasPressed('down') then
        highlighted = highlighted == 1 and 2 or 1
        gSounds['paddle-hit']:play()
    end

    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gSounds['confirm']:play()
        if highlighted == 1 then
            gStateMachine:change('serve', {
                paddle = Paddle(1),
                health = 5,
                score = 0,
                level = 1,
                recoverPoints = 5000
            })
        else
            gStateMachine:change('options')
        end
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function StartState:render()
    love.graphics.setFont(gFonts['large'])
    -- Draw shadow first
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("BLINKERS", 1, VIRTUAL_HEIGHT / 3 + 1, VIRTUAL_WIDTH, 'center')
    -- Draw main text
    love.graphics.setColor(34/255, 34/255, 34/255, 255/255)
    love.graphics.printf("BLINKERS", 0, VIRTUAL_HEIGHT / 3, VIRTUAL_WIDTH, 'center')
    
    love.graphics.setFont(gFonts['medium'])
    -- Draw START shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("START", 1, VIRTUAL_HEIGHT / 2 + 71, VIRTUAL_WIDTH, 'center')
    -- Draw START text
    if highlighted == 1 then
        love.graphics.setColor(103 / 255, 1, 1, 1)
    else
        love.graphics.setColor(1, 1, 1, 255/255)
    end
    love.graphics.printf("START", 0, VIRTUAL_HEIGHT / 2 + 70, VIRTUAL_WIDTH, 'center')
    
    -- Draw OPTIONS shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("OPTIONS", 1, VIRTUAL_HEIGHT / 2 + 91, VIRTUAL_WIDTH, 'center')
    -- Draw OPTIONS text
    if highlighted == 2 then
        love.graphics.setColor(103 / 255, 1, 1, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.printf("OPTIONS", 0, VIRTUAL_HEIGHT / 2 + 90, VIRTUAL_WIDTH, 'center')
    love.graphics.setColor(1, 1, 1, 1)
end
