require 'src/Dependencies'

function love.load()
	love.graphics.setDefaultFilter('nearest', 'nearest')
	math.randomseed(os.time())
	love.window.setTitle('Blinkers')

	gFonts = {
		['small'] = love.graphics.newFont('fonts/font.ttf', 8),
		['medium'] = love.graphics.newFont('fonts/font.ttf', 16),
		['large'] = love.graphics.newFont('fonts/font.ttf', 32)
	}
	love.graphics.setFont(gFonts['small'])

	gTextures = {
		['background'] = love.graphics.newImage('graphics/background.png'),
		['main'] = love.graphics.newImage('graphics/blinkers.png'),
		['hearts'] = love.graphics.newImage('graphics/hearts.png'),
		['particle'] = love.graphics.newImage('graphics/particle.png')
	}

	gFrames = {
		['paddles'] = GeneratePaddle(gTextures['main']),
		['balls'] = GenerateBalls(gTextures['main']),
		['hearts'] = GenerateQuads(gTextures['hearts'], 10, 9)
	}

	push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
		vsync = true,
		fullscreen = false,
		resizable = true
	})

	gSounds = {
		['paddle-hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
		['score'] = love.audio.newSource('sounds/score.wav', 'static'),
		['wall-hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static'),
		['confirm'] = love.audio.newSource('sounds/confirm.wav', 'static'),
		['select'] = love.audio.newSource('sounds/select.wav', 'static'),
		['no-select'] = love.audio.newSource('sounds/no-select.wav', 'static'),
		['hurt'] = love.audio.newSource('sounds/hurt.wav', 'static'),
		['pause'] = love.audio.newSource('sounds/pause.wav', 'static'),

		['music'] = love.audio.newSource('sounds/music.wav', 'static')
	}

	gStateMachine = StateMachine {
		['start'] = function() return StartState() end,
		['play'] = function() return PlayState() end,
		['serve'] = function() return ServeState() end,
		['game-over'] = function() return GameOverState() end,
		['options'] = function() return OptionsState() end,
		['keybinds'] = function() return KeybindsState() end,
		['display'] = function() return DisplayState() end
	}
	gStateMachine:change('start')
		
	gSounds['music']:play()
	gSounds['music']:setLooping(true)
	
	love.keyboard.keysPressed = {}
	
	-- Initialize key bindings
	gKeyBindings = {
		paddleLeft = 'left',
		paddleRight = 'right',
		tiltLeft = 'a',
		tiltRight = 'd'
	}
	loadKeyBindings()
	loadDisplaySettings()
end

function love.resize(w, h)
	push:resize(w, h)
end

function love.update(dt)
	gStateMachine:update(dt)
	love.keyboard.keysPressed = {}
end

function love.keypressed(key)
	love.keyboard.keysPressed[key] = true
end

function love.keyboard.wasPressed(key)
	if love.keyboard.keysPressed[key] then
		return true
	else
		return false
	end
end

function love.draw()
	push:apply('start')

	local backgroundWidth = gTextures['background']:getWidth()
	local backgroundHeight = gTextures['background']:getHeight()

	love.graphics.draw(gTextures['background'],
		0, 0,
		0,
		VIRTUAL_WIDTH / (backgroundWidth - 1), VIRTUAL_HEIGHT / (backgroundHeight - 1))
	gStateMachine:render()
	-- displayFPS()
	push:apply('end')
end


function renderHealth(health)
local healthX = 5

for i = 1, health do
love.graphics.draw(gTextures['hearts'],gFrames['hearts'][1], healthX, 4)
healthX = healthX + 11
end
end

function drawTextWithShadow(text, x, y, width, align)
    -- Draw shadow first
    love.graphics.setColor(0, 0, 0, 0.5)
    if width then
        love.graphics.printf(text, x + 1, y + 1, width, align or 'left')
    else
        love.graphics.print(text, x + 1, y + 1)
    end
    
    -- Draw main text
    love.graphics.setColor(1, 1, 1, 1)
    if width then
        love.graphics.printf(text, x, y, width, align or 'left')
    else
        love.graphics.print(text, x, y)
    end
end

function renderScore(score)
    love.graphics.setFont(gFonts['small'])
    drawTextWithShadow("Score:", VIRTUAL_WIDTH - 60, 5)
    drawTextWithShadow(tostring(score), VIRTUAL_WIDTH - 50, 5, 40, 'right')
end

function renderTimer(timer)
    love.graphics.setFont(gFonts['small'])
    
    -- Convert seconds to minutes and seconds
    local minutes = math.floor(timer / 60)
    local seconds = math.floor(timer % 60)
    
    -- Format as MM:SS
    local timeString = string.format("%02d:%02d", minutes, seconds)
    
    -- Special effects for last 10 seconds
    if timer <= 10 then
        -- Use larger font for last 10 seconds
        love.graphics.setFont(gFonts['medium'])
        
        -- Create flashing effect
        local flashIntensity = math.sin(love.timer.getTime() * 8) * 0.5 + 0.5 -- Rapid flashing
        local pulseScale = 1 + math.sin(love.timer.getTime() * 6) * 0.2 -- Pulsing effect
        
        -- Combine time label and value into one string
        local fullTimeText = "Time: " .. timeString
        
        -- Calculate position to keep it on screen
        local textWidth = love.graphics.getFont():getWidth(fullTimeText)
        local xPos = VIRTUAL_WIDTH - textWidth - 10 -- 10 pixels margin from right edge
        
        -- Bright red color with flashing
        love.graphics.setColor(1, 0, 0, 1)
        
        -- Apply pulsing transformation
        love.graphics.push()
        love.graphics.translate(xPos + textWidth/2, 25)
        love.graphics.scale(pulseScale, pulseScale)
        love.graphics.translate(-(xPos + textWidth/2), -25)
        
        -- Draw shadow with increased intensity
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.print(fullTimeText, xPos + 2, 22)
        
        -- Draw main text with flashing effect
        love.graphics.setColor(1, 0, 0, flashIntensity)
        love.graphics.print(fullTimeText, xPos, 20)
        
        love.graphics.pop()
        
        -- Reset font
        love.graphics.setFont(gFonts['small'])
    else
        -- Normal timer display for more than 10 seconds
        -- Change color based on remaining time
        if timer <= 60 then -- Last minute: red
            love.graphics.setColor(1, 0, 0, 1)
        elseif timer <= 300 then -- Last 5 minutes: yellow
            love.graphics.setColor(1, 1, 0, 1)
        else -- Normal: white
            love.graphics.setColor(1, 1, 1, 1)
        end
        
        drawTextWithShadow("Time:", VIRTUAL_WIDTH - 60, 20)
        drawTextWithShadow(timeString, VIRTUAL_WIDTH - 50, 20, 40, 'right')
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function displayFPS()
    love.graphics.setFont(gFonts['small'])
    drawTextWithShadow('FPS : ' .. tostring(love.timer.getFPS()), 5, VIRTUAL_HEIGHT - 15)
end

function loadKeyBindings()
	love.filesystem.setIdentity('blinkers')
	if love.filesystem.getInfo('keybinds.txt') then
		local content = love.filesystem.read('keybinds.txt')
		local lines = {}
		for line in content:gmatch("[^\r\n]+") do
			table.insert(lines, line)
		end
		if #lines >= 4 then
			gKeyBindings.paddleLeft = lines[1]
			gKeyBindings.paddleRight = lines[2]
			gKeyBindings.tiltLeft = lines[3]
			gKeyBindings.tiltRight = lines[4]
		end
	end
end

function loadDisplaySettings()
	love.filesystem.setIdentity('blinkers')
	if love.filesystem.getInfo('fullscreen.txt') then
		local content = love.filesystem.read('fullscreen.txt')
		if content == 'true' then
			love.window.setFullscreen(true)
		end
	end
end

function saveKeyBindings()
	love.filesystem.setIdentity('blinkers')
	local content = gKeyBindings.paddleLeft .. '\n' .. 
				   gKeyBindings.paddleRight .. '\n' .. 
				   gKeyBindings.tiltLeft .. '\n' .. 
				   gKeyBindings.tiltRight
	love.filesystem.write('keybinds.txt', content)
end