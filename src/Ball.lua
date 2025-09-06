Ball = Class {}

function Ball:init(skin)
    self.width = 8
    self.height = 8  -- FIXED: was self.width twice

    self.x = VIRTUAL_WIDTH / 2 - self.width / 2
    self.y = VIRTUAL_HEIGHT / 2 - self.height / 2

    self.dx = 0
    self.dy = 0

    self.gravity = 100 -- Set to 0 for classic Pong style; increase for physics-based fall
    self.bounce = -1 -- Reverse direction on bounce; tweak for energy loss

    self.skin = skin
    
    -- Destruction state
    self.isDestroyed = false
    self.destructionTimer = 0
    self.destructionDuration = 0.1 -- How long the destruction effect lasts
    
    -- Sound state
    self.offScreenSoundPlayed = false
    
    -- Modifier states
    self.sizeModifierActive = false
    self.speedModifierActive = false
end

function Ball:collides(target)
    if self.x > target.x + target:getWidth() or target.x > self.x + self:getWidth() then
        return false
    end
    if self.y > target.y + target.height or target.y > self.y + self:getHeight() then
        return false
    end
    return true
end

function Ball:collidesWithPaddle(paddle)
    -- Get the ball's center point
    local ballCenterX = self.x + self:getWidth() / 2
    local ballCenterY = self.y + self:getHeight() / 2
    
    -- Get the paddle's center point
    local paddleCenterX = paddle.x + paddle:getWidth() / 2
    local paddleCenterY = paddle.y + paddle.height / 2
    
    -- Get paddle dimensions
    local paddleWidth = paddle:getWidth()
    local paddleHeight = paddle.height
    
    -- If paddle is not tilted, use simple rectangular collision
    if math.abs(paddle:getTiltAngle()) < 0.01 then
        return self:collides(paddle)
    end
    
    -- For tilted paddle, use more precise collision detection
    -- Transform ball position to paddle's local coordinate system
    local cosAngle = math.cos(-paddle:getTiltAngle())
    local sinAngle = math.sin(-paddle:getTiltAngle())
    
    -- Translate ball position relative to paddle center
    local relativeX = ballCenterX - paddleCenterX
    local relativeY = ballCenterY - paddleCenterY
    
    -- Rotate ball position to paddle's local coordinate system
    local rotatedX = relativeX * cosAngle - relativeY * sinAngle
    local rotatedY = relativeX * sinAngle + relativeY * cosAngle
    
    -- Check if ball is within the rotated paddle bounds
    local halfPaddleWidth = paddleWidth / 2
    local halfPaddleHeight = paddleHeight / 2
    
    -- Add a small collision margin for better feel
    local collisionMargin = 2
    
    if math.abs(rotatedX) <= halfPaddleWidth + collisionMargin and 
       math.abs(rotatedY) <= halfPaddleHeight + collisionMargin then
        return true
    end
    
    return false
end

function Ball:reset()
    self.x = VIRTUAL_WIDTH / 2 - self.width / 2
    self.y = VIRTUAL_HEIGHT / 2 - self.height / 2
    self.dx = 0
    self.dy = 0
end

function Ball:update(dt)
    -- Update destruction timer
    if self.isDestroyed then
        self.destructionTimer = self.destructionTimer + dt
        return -- Don't update position if destroyed
    end
    
    -- Apply speed modifier
    local speedMultiplier = self.speedModifierActive and 0.55 or 1.0 -- 75% slower when active
    
    -- Apply gravity if enabled
    self.dy = self.dy + self.gravity * dt * speedMultiplier

    -- Update position
    self.x = self.x + self.dx * dt * speedMultiplier
    self.y = self.y + self.dy * dt * speedMultiplier

    -- Removed top wall bouncing - ball can now go off screen at the top
    -- if self.y <= 0 then
    --     self.y = 0
    --     self.dy = self.dy * self.bounce
    --     gSounds['wall-hit']:play()
    -- end
    
    -- No horizontal wall bouncing - balls can go off screen on sides
end

function Ball:isOffScreen()
    -- Check if ball has gone off screen on any side
    return self.x < -self:getWidth() or 
           self.x > VIRTUAL_WIDTH or 
           self.y > VIRTUAL_HEIGHT
end

function Ball:isOffScreenSides()
    -- Check if ball has gone off screen on left or right sides only
    return self.x < -self:getWidth() or self.x > VIRTUAL_WIDTH
end

function Ball:isOffScreenBottom()
    -- Check if ball has gone off screen on the bottom
    return self.y > VIRTUAL_HEIGHT
end

function Ball:render()
    -- Don't render if ball is destroyed and destruction effect is complete
    if self.isDestroyed and self.destructionTimer >= self.destructionDuration then
        return
    end
    
    -- Add fade effect if ball is going off screen on sides
    local alpha = 1.0
    if self:isOffScreenSides() then
        alpha = 0.5 -- Fade out when off screen on sides
    end
    
    -- Destruction effect - flash and fade out
    if self.isDestroyed then
        local destructionProgress = self.destructionTimer / self.destructionDuration
        alpha = alpha * (1 - destructionProgress) -- Fade out during destruction
        -- Flash effect during destruction
        if math.floor(self.destructionTimer * 20) % 2 == 0 then
            love.graphics.setColor(1, 0, 0, alpha) -- Red flash
        else
            love.graphics.setColor(1, 1, 1, alpha) -- White flash
        end
    else
        love.graphics.setColor(1, 1, 1, alpha) -- Normal white ball
    end
    
    -- Apply size modifier for rendering
    local scale = self.sizeModifierActive and 1.5 or 1.0
    love.graphics.push()
    love.graphics.translate(self.x + self.width/2, self.y + self.height/2)
    love.graphics.scale(scale, scale)
    love.graphics.translate(-(self.x + self.width/2), -(self.y + self.height/2))
    love.graphics.draw(gTextures['main'], gFrames['balls'][self.skin], self.x, self.y)
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function Ball:markForDestruction()
    self.isDestroyed = true
    self.destructionTimer = 0
end

function Ball:setSizeModifier(active)
    self.sizeModifierActive = active
end

function Ball:setSpeedModifier(active)
    self.speedModifierActive = active
end

function Ball:getWidth()
    if self.sizeModifierActive then
        return self.width * 1.5 -- 50% larger
    else
        return self.width
    end
end

function Ball:getHeight()
    if self.sizeModifierActive then
        return self.height * 1.5 -- 50% larger
    else
        return self.height
    end
end
