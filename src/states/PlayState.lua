PlayState = Class { __includes = BaseState }
function PlayState:enter(params)
    self.paddle = params.paddle or Paddle()
    self.health = params.health
    self.score = params.score
    self.level = params.level

    self.recoverPoints = 5000

    -- Initialize timer (10 minutes = 600 seconds)
    self.gameTimer = 600

    -- Initialize modifier system
    self.lastModifierScore = 0
    self.modifierActive = false
    self.currentModifier = nil
    self.modifierEndTime = 0
    
    -- Modifier shuffle animation
    self.modifierShuffle = false
    self.modifierShuffleTimer = 0
    self.modifierShuffleDuration = 1.5 -- How long the shuffle effect lasts
    self.modifierDisplayTimer = 0
    self.modifierDisplayInterval = 0.1 -- How quickly the modifier name changes
    self.shuffledModifierName = ""
    
    -- Modifier effect timers
    self.paddleSizeModifierEndTime = 0
    self.smallPaddleModifierEndTime = 0
    self.ballSizeModifierEndTime = 0
    self.ballSpeedModifierEndTime = 0
    self.paddleSpeedModifierEndTime = 0
    self.doubleScoreModifierEndTime = 0
    
    -- Active modifiers list
    self.activeModifiers = {}

    -- Initialize multiple balls system - start with no balls
    self.balls = {} -- Start with no balls on paddle
    self.ballSpawnTimer = 0
    self.ballSpawnInterval = math.random(1.0, 1.5) -- Initial spawning: 1-1.5 seconds
    self.initialSpawnDelay = 0.5 -- Wait 0.5 seconds before first spawn
    self.hasSpawnedFirstBall = false
    self.maxBalls = 8 -- Limit maximum balls to prevent overwhelming the player
    self.lastSpawnTime = 0 -- Track last spawn time for cooldown
    self.minSpawnCooldown = 0.3 -- Minimum 0.3 seconds between spawns
    
    -- Directional indicator system
    self.targetDirection = math.random(1, 2) -- 1 = LEFT, 2 = RIGHT
    self.directionChangeTimer = 0
    self.directionChangeInterval = math.random(3, 6) -- Faster changes: 3-6 seconds instead of 8-15
    self.directionChangeFlashTimer = 0 -- Timer for flash effect when direction changes
    self.directionChangeFlashDuration = 1.0 -- How long the flash effect lasts

    -- Define modifiers
    self.modifiers = {
        {
            name = "Time Extension",
            description = "Add 2 minutes to the game",
            image = "time_extension",
            effect = function()
                self.gameTimer = self.gameTimer + 120 -- Add 2 minutes
            end
        },
        {
            name = "Large Paddle",
            description = "The paddle becomes larger for 30 seconds",
            image = "large_paddle",
            effect = function()
                self.paddleSizeModifierEndTime = self.gameTimer - 30 -- 30 seconds
                self.smallPaddleModifierEndTime = 0
                table.insert(self.activeModifiers, {
                    name = "Large Paddle",
                    endTime = self.gameTimer - 30
                })
            end
        },
        {
            name = "Small Paddle",
            description = "The paddle becomes smaller for 30 seconds",
            image = "small_paddle",
            effect = function()
                self.smallPaddleModifierEndTime = self.gameTimer - 30 -- 30 seconds
                self.paddleSizeModifierEndTime = 0
                table.insert(self.activeModifiers, {
                    name = "Small Paddle",
                    endTime = self.gameTimer - 30
                })
            end
        },
        {
            name = "Big Balls",
            description = "The balls are bigger for 30 seconds",
            image = "big_balls",
            effect = function()
                self.ballSizeModifierEndTime = self.gameTimer - 30 -- 30 seconds
                table.insert(self.activeModifiers, {
                    name = "Big Balls",
                    endTime = self.gameTimer - 30
                })
            end
        },
        {
            name = "Slow Balls",
            description = "Balls are slower for 30 seconds",
            image = "slow_balls",
            effect = function()
                self.ballSpeedModifierEndTime = self.gameTimer - 30 -- 30 seconds
                table.insert(self.activeModifiers, {
                    name = "Slow Balls",
                    endTime = self.gameTimer - 30
                })
            end
        },
        {
            name = "Fast Paddle",
            description = "The paddle becomes faster for 30 seconds",
            image = "fast_paddle",
            effect = function()
                self.paddleSpeedModifierEndTime = self.gameTimer - 30 -- 30 seconds
                table.insert(self.activeModifiers, {
                    name = "Fast Paddle",
                    endTime = self.gameTimer - 30
                })
            end
        },
        {
            name = "Double Score",
            description = "Score 2 points instead of 1 for correct throws for 30 seconds",
            image = "double_score",
            effect = function()
                self.doubleScoreModifierEndTime = self.gameTimer - 30 -- 30 seconds
                table.insert(self.activeModifiers, {
                    name = "Double Score",
                    endTime = self.gameTimer - 30
                })
            end
        },
        {
            name = "Extra Lives",
            description = "Add 2 lives more to the player",
            image = "extra_lives",
            effect = function()
                self.health = self.health + 2
            end
        }
    }
end

function PlayState:update(dt)
    -- If the modifier screen is active, it has priority.
    -- Handle its input and pause all other game logic.
    if self.modifierActive then
        if love.keyboard.wasPressed('space') then
            -- Apply the modifier effect and close the screen.
            self.currentModifier.effect()
            self.modifierActive = false
            self.currentModifier = nil
            gSounds['confirm']:play()
        end
        -- Return immediately to ensure the game stays paused.
        return
    end

    -- Handle modifier shuffle animation
    if self.modifierShuffle then
        self.modifierShuffleTimer = self.modifierShuffleTimer + dt
        self.modifierDisplayTimer = self.modifierDisplayTimer + dt

        -- Rapidly change the displayed modifier name
        if self.modifierDisplayTimer > self.modifierDisplayInterval then
            local randomModifier = self.modifiers[math.random(#self.modifiers)]
            self.shuffledModifierName = randomModifier.name
            self.modifierDisplayTimer = 0
        end

        -- Once the shuffle duration is over, select the final modifier
        if self.modifierShuffleTimer >= self.modifierShuffleDuration then
            self.modifierShuffle = false
            self.modifierActive = true
            self.currentModifier = self.modifiers[math.random(#self.modifiers)]
            gSounds['confirm']:play() -- Play a sound to signal completion
        end
        
        -- Pause the game during the shuffle
        return
    end

    -- Standard pause logic; only runs if the modifier screen is not active.
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- Update game timer
    self.gameTimer = self.gameTimer - dt
    
    -- Check if timer ran out
    if self.gameTimer <= 0 then
        gStateMachine:change('game-over', {
            score = self.score
        })
        return
    end

    self.paddle:update(dt)
    
    -- Update direction change timer
    self.directionChangeTimer = self.directionChangeTimer + dt
    if self.directionChangeTimer >= self.directionChangeInterval then
        self.targetDirection = math.random(1, 2) -- Change to random direction
        self.directionChangeTimer = 0
        self.directionChangeInterval = math.random(3, 6) -- New random interval
        self.directionChangeFlashTimer = 0 -- Start flash effect
        gSounds['confirm']:play() -- Play sound to alert player
    end
    
    -- Update flash timer
    if self.directionChangeFlashTimer < self.directionChangeFlashDuration then
        self.directionChangeFlashTimer = self.directionChangeFlashTimer + dt
    end
    
    -- Update ball spawn timer
    self.ballSpawnTimer = self.ballSpawnTimer + dt
    
    -- Spawn new ball if timer is up and under ball limit
    if self.ballSpawnTimer >= self.ballSpawnInterval and #self.balls < self.maxBalls then
        -- Add initial delay for first ball to prevent immediate spawning
        if not self.hasSpawnedFirstBall then
            if self.ballSpawnTimer >= self.initialSpawnDelay then
                self:spawnNewBall()
                self.ballSpawnTimer = 0
                self.ballSpawnInterval = math.random(0.8, 1.2) -- Normal spawning: 0.8-1.2 seconds
                self.hasSpawnedFirstBall = true
                self.lastSpawnTime = love.timer.getTime() -- Track last spawn time
            end
        else
            -- Additional safety check: ensure minimum time has passed since last spawn
            local currentTime = love.timer.getTime()
            if self.lastSpawnTime == 0 or (currentTime - self.lastSpawnTime) >= self.minSpawnCooldown then
                self:spawnNewBall()
                self.ballSpawnTimer = 0
                self.ballSpawnInterval = math.random(0.8, 1.2) -- Normal spawning: 0.8-1.2 seconds
                self.lastSpawnTime = currentTime -- Update last spawn time
            else
                -- Reset timer if we're still in cooldown to prevent rapid spawning
                self.ballSpawnTimer = self.ballSpawnInterval * 0.5
            end
        end
    end
    
    -- Update all balls
    for i = #self.balls, 1, -1 do
        local ball = self.balls[i]
        ball:update(dt)
        
        -- Check paddle collision for each ball
        if ball:collidesWithPaddle(self.paddle) then
            -- Only process collision if ball is moving downward or is at the paddle level
            if ball.dy >= 0 or ball.y + ball:getHeight() >= self.paddle.y then
                -- Position the ball above the paddle
                ball.y = self.paddle.y - ball:getHeight()
                
                -- Ensure the ball bounces upward
                if ball.dy > 0 then
                    ball.dy = -ball.dy
                else
                    ball.dy = -math.abs(ball.dy) -- Force upward movement
                end

                -- Pinball paddle physics based on tilt
                local tiltAngle = self.paddle:getTiltAngle()
                local paddleWidth = self.paddle:getWidth() -- Use the actual width
                local paddleCenterX = self.paddle.x + (paddleWidth / 2)
                local ballCenterX = ball.x + (ball.width / 2)
                local hitPosition = (ballCenterX - paddleCenterX) / (paddleWidth / 2) -- -1 to 1
                
                -- Apply tilt physics
                if math.abs(tiltAngle) > 0.01 then
                    -- Tilt affects both horizontal and vertical velocity
                    local tiltMultiplier = 3.0 -- Increased from 1.5 for more aggressive effects
                    local tiltEffect = tiltAngle * tiltMultiplier
                    
                    -- Add tilt effect to horizontal velocity
                    ball.dx = ball.dx + tiltEffect * 300 -- Increased from 200
                    
                    -- Modify vertical velocity based on tilt
                    ball.dy = ball.dy * (1 + math.abs(tiltEffect) * 0.6) -- Increased from 0.3
                    
                    -- Add more randomness for more dynamic gameplay
                    ball.dx = ball.dx + math.random(-40, 40) -- Increased from -20, 20
                else
                    -- Normal paddle physics when not tilted
                    if ball.x < self.paddle.x + (paddleWidth / 2) and self.paddle.dx < 0 then
                        ball.dx = -50 + -(8 * (self.paddle.x + paddleWidth / 2 - ball.x))
                    elseif ball.x > self.paddle.x + (paddleWidth / 2) and self.paddle.dx > 0 then
                        ball.dx = 50 + (8 * math.abs(self.paddle.x + paddleWidth / 2 - ball.x))
                    end
                end

                gSounds['paddle-hit']:play()
            end
        end
        
        -- Check if ball went off screen
        if ball:isOffScreen() then
            local wentOffBottom = ball:isOffScreenBottom()
            local wentOffLeft = ball.x < -ball:getWidth()
            local wentOffRight = ball.x > VIRTUAL_WIDTH
            
            -- Only play sound and mark for destruction if not already done
            if not ball.offScreenSoundPlayed then
                -- Mark ball for destruction with visual effect
                ball:markForDestruction()
                
                -- Play destruction sound for any ball going off screen (only once)
                gSounds['wall-hit']:play()
                ball.offScreenSoundPlayed = true
                
                -- Check for correct direction (score points) - use ball's assigned direction
                if (ball.assignedDirection == 1 and wentOffLeft) or (ball.assignedDirection == 2 and wentOffRight) then
                    -- Ball went off the correct side - add score
                    local scoreToAdd = 1
                    if self.doubleScoreModifierEndTime > 0 then
                        scoreToAdd = 2 -- Double score when modifier is active
                    end
                    self.score = self.score + scoreToAdd
                    gSounds['score']:play()
                end
                
                -- Check for wrong direction penalty (lose life) - use ball's assigned direction
                if (ball.assignedDirection == 1 and wentOffRight) or (ball.assignedDirection == 2 and wentOffLeft) then
                    -- Ball went off the wrong side - lose health
                    self.health = self.health - 1
                    gSounds['hurt']:play()
                end
                
                -- Lose health if ball went off the bottom
                if wentOffBottom then
                    self.health = self.health - 1
                    gSounds['hurt']:play()
                end
            end
        end
        
        -- Remove balls that have completed their destruction effect
        if ball.isDestroyed and ball.destructionTimer >= ball.destructionDuration then
            table.remove(self.balls, i)
        end
    end
    
    -- Check for game over after all ball processing is done
    if self.health <= 0 then
        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    -- Check for modifier trigger every 20 points
    if math.floor(self.score / 20) > math.floor(self.lastModifierScore / 20) and not self.modifierActive and not self.modifierShuffle then
        self.modifierShuffle = true
        self.modifierShuffleTimer = 0
        self.lastModifierScore = self.score
    end

    -- Apply modifier effects based on timers
    if self.paddleSizeModifierEndTime > 0 and self.gameTimer <= self.paddleSizeModifierEndTime then
        self.paddleSizeModifierEndTime = 0
    end
    if self.smallPaddleModifierEndTime > 0 and self.gameTimer <= self.smallPaddleModifierEndTime then
        self.smallPaddleModifierEndTime = 0
    end

    if self.paddleSizeModifierEndTime > 0 then
        self.paddle:setSizeModifier('large')
    elseif self.smallPaddleModifierEndTime > 0 then
        self.paddle:setSizeModifier('small')
    else
        self.paddle:setSizeModifier('none')
    end
    
    if self.ballSizeModifierEndTime > 0 and self.gameTimer <= self.ballSizeModifierEndTime then
        self.ballSizeModifierEndTime = 0
        -- Reset ball size for all balls
        for _, ball in pairs(self.balls) do
            ball:setSizeModifier(false)
        end
    elseif self.ballSizeModifierEndTime > 0 then
        -- Keep ball size modifier active for all balls
        for _, ball in pairs(self.balls) do
            ball:setSizeModifier(true)
        end
    end
    
    if self.ballSpeedModifierEndTime > 0 and self.gameTimer <= self.ballSpeedModifierEndTime then
        self.ballSpeedModifierEndTime = 0
        -- Reset ball speed for all balls
        for _, ball in pairs(self.balls) do
            ball:setSpeedModifier(false)
        end
    elseif self.ballSpeedModifierEndTime > 0 then
        -- Keep ball speed modifier active for all balls
        for _, ball in pairs(self.balls) do
            ball:setSpeedModifier(true)
        end
    end

    if self.paddleSpeedModifierEndTime > 0 and self.gameTimer <= self.paddleSpeedModifierEndTime then
        self.paddleSpeedModifierEndTime = 0
        -- Reset paddle speed
        self.paddle:setSpeedModifier(false)
    elseif self.paddleSpeedModifierEndTime > 0 then
        -- Keep paddle speed modifier active
        self.paddle:setSpeedModifier(true)
    end

    if self.doubleScoreModifierEndTime > 0 and self.gameTimer <= self.doubleScoreModifierEndTime then
        self.doubleScoreModifierEndTime = 0
    end

    -- Clean up expired modifiers from the active list
    for i = #self.activeModifiers, 1, -1 do
        local modifier = self.activeModifiers[i]
        if self.gameTimer <= modifier.endTime then
            table.remove(self.activeModifiers, i)
        end
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:spawnNewBall()
    -- Use different ball skins based on direction (skin 1 for left, skin 2 for right)
    local ballSkin = self.targetDirection == 1 and 1 or 2
    local newBall = Ball(ballSkin)
    
    -- Assign the ball's direction when it spawns (this stays fixed for the ball's lifetime)
    newBall.assignedDirection = self.targetDirection
    
    -- Apply current modifiers to the new ball
    if self.ballSizeModifierEndTime > 0 then
        newBall:setSizeModifier(true)
    end
    if self.ballSpeedModifierEndTime > 0 then
        newBall:setSpeedModifier(true)
    end
    
    -- Spawn from top with reduced spawn zone (not at the very edges)
    local spawnMargin = 50 -- Distance from edges
    newBall.x = math.random(spawnMargin, VIRTUAL_WIDTH - newBall:getWidth() - spawnMargin) -- Reduced spawn zone
    newBall.y = -newBall:getHeight() -- Start above screen
    newBall.dx = math.random(-50, 50) -- Minimal horizontal velocity variation
    newBall.dy = math.random(100, 150) -- Consistent downward velocity
    
    table.insert(self.balls, newBall)
end

function PlayState:render()
    self.paddle:render()
    
    -- Render all balls
    for k, ball in pairs(self.balls) do
        ball:render()
    end

    renderScore(self.score)
    renderHealth(self.health)
    renderTimer(self.gameTimer)
    
    -- Render directional indicator
    love.graphics.setFont(gFonts['medium'])
    local directionText = self.targetDirection == 1 and "THROW LEFT" or "THROW RIGHT"
    local directionColor = self.targetDirection == 1 and {99/255, 155/255, 255/255, 1} or {251/255, 242/255, 54/255, 1} -- Blue for left, gold for right
    
    -- Flash effect when direction changes
    if self.directionChangeFlashTimer < self.directionChangeFlashDuration then
        local flashProgress = self.directionChangeFlashTimer / self.directionChangeFlashDuration
        local flashIntensity = math.sin(flashProgress * math.pi * 8) * 0.5 + 0.5 -- Rapid flashing
        local scale = 1 + flashIntensity * 0.3 -- Scale up during flash
        
        love.graphics.push()
        love.graphics.translate(VIRTUAL_WIDTH / 2, 20)
        love.graphics.scale(scale, scale)
        love.graphics.translate(-VIRTUAL_WIDTH / 2, -20)
        
        -- Bright white flash color
        love.graphics.setColor(1, 1, 1, 1)
        -- Draw shadow first
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf(directionText, 1, 6, VIRTUAL_WIDTH, 'center')
        -- Draw main text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(directionText, 0, 5, VIRTUAL_WIDTH, 'center')
        
        love.graphics.pop()
    else
        -- Normal color
        love.graphics.setColor(directionColor[1], directionColor[2], directionColor[3], directionColor[4])
        -- Draw shadow first
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf(directionText, 1, 6, VIRTUAL_WIDTH, 'center')
        -- Draw main text
        love.graphics.setColor(directionColor[1], directionColor[2], directionColor[3], directionColor[4])
        love.graphics.printf(directionText, 0, 5, VIRTUAL_WIDTH, 'center')
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color

    -- Render modifier shuffle animation
    if self.modifierShuffle then
        -- Semi-transparent overlay
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
        
        -- Modifier card background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
        local cardWidth = 220
        local cardHeight = 120
        local cardX = (VIRTUAL_WIDTH - cardWidth) / 2
        local cardY = (VIRTUAL_HEIGHT - cardHeight) / 2
        love.graphics.rectangle('fill', cardX, cardY, cardWidth, cardHeight)
        
        -- Card border
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('line', cardX, cardY, cardWidth, cardHeight)
        
        -- "Randomizing..." title
        love.graphics.setFont(gFonts['medium'])
        love.graphics.setColor(1, 1, 0, 1)
        
        -- Shuffling modifier name
        love.graphics.setFont(gFonts['medium'])
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(self.shuffledModifierName, cardX, cardY + 50, cardWidth, 'center')
    end

    -- Render modifier selection screen
    if self.modifierActive then
        -- Semi-transparent overlay
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
        
        -- Modifier card
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
        local cardWidth = 200
        local cardHeight = 120
        local cardX = (VIRTUAL_WIDTH - cardWidth) / 2
        local cardY = (VIRTUAL_HEIGHT - cardHeight) / 2
        love.graphics.rectangle('fill', cardX, cardY, cardWidth, cardHeight)
        
        -- Card border
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('line', cardX, cardY, cardWidth, cardHeight)
        
        -- Modifier name
        love.graphics.setFont(gFonts['medium'])
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(self.currentModifier.name, cardX, cardY + 10, cardWidth, 'center')
        
        -- Modifier description
        love.graphics.setFont(gFonts['small'])
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.printf(self.currentModifier.description, cardX + 10, cardY + 40, cardWidth - 20, 'center')
        
        -- Instructions
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.printf("Press SPACE to continue", cardX, cardY + 90, cardWidth, 'center')
    end

    if self.paused then
        love.graphics.setFont(gFonts['large'])
        -- Draw shadow first
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf("PAUSED", 1, VIRTUAL_HEIGHT / 2 - 15, VIRTUAL_WIDTH, 'center')
        -- Draw main text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
        
        -- Render active modifiers
        self:renderActiveModifiers()
    end
end

function PlayState:renderActiveModifiers()
    local yOffset = VIRTUAL_HEIGHT / 2 + 20
    
    -- Render active modifiers
    if #self.activeModifiers > 0 then
        love.graphics.setFont(gFonts['medium'])
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.printf("ACTIVE MODIFIERS:", 0, yOffset, VIRTUAL_WIDTH, 'center')
        
        love.graphics.setFont(gFonts['small'])
        yOffset = yOffset + 25
        
        for i, modifier in ipairs(self.activeModifiers) do
            local remainingTime = self.gameTimer - modifier.endTime
            
            -- Only process modifiers that haven't expired
            if remainingTime >= 0 then
                local minutes = math.floor(remainingTime / 60)
                local seconds = math.floor(remainingTime % 60)
                local timeString = string.format("%02d:%02d", minutes, seconds)
                
                -- Change color based on remaining time
                if remainingTime <= 30 then -- Last 30 seconds: red
                    love.graphics.setColor(1, 0, 0, 1)
                elseif remainingTime <= 60 then -- Last minute: orange
                    love.graphics.setColor(1, 0.5, 0, 1)
                else -- Normal: yellow
                    love.graphics.setColor(1, 1, 0, 1)
                end
                
                local text = modifier.name .. " - " .. timeString
                love.graphics.printf(text, 0, yOffset, VIRTUAL_WIDTH, 'center')
                yOffset = yOffset + 15
            end
        end
    else
        -- Show message when no modifiers are active
        love.graphics.setFont(gFonts['small'])
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.printf("No active modifiers", 0, yOffset, VIRTUAL_WIDTH, 'center')
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end
