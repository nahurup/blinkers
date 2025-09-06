Paddle = Class {}
function Paddle:init()
    self.x = VIRTUAL_WIDTH / 2 - 32
    self.y = VIRTUAL_HEIGHT - 32

    self.dx = 0

    self.width = 64
    self.height = 16

    self.size = 2
    
    -- Pinball paddle features
    self.tiltAngle = 0  -- Current tilt angle in radians
    self.targetTilt = 0 -- Target tilt angle
    self.isTilting = false -- Whether the paddle is currently tilting
    
    -- Key press tracking for momentary tilt
    self.aPressed = false
    self.dPressed = false
    
    -- Modifier state
    self.sizeModifier = 'none'
    self.speedModifierActive = false
end

function Paddle:update(dt)
    local currentSpeed = PADDLE_SPEED
    if self.speedModifierActive then
        currentSpeed = PADDLE_SPEED * 1.5
    end

    if love.keyboard.isDown(gKeyBindings.paddleLeft) then
        self.dx = -currentSpeed
    elseif love.keyboard.isDown(gKeyBindings.paddleRight) then
        self.dx = currentSpeed
    else
        self.dx = 0
    end

    if self.dx < 0 then
        self.x = math.max(0, self.x + self.dx * dt)
    else
        self.x = math.min(VIRTUAL_WIDTH - self:getWidth(), self.x + self.dx * dt)
    end

    -- Handle paddle tilting
    self:updateTilt(dt)
end

function Paddle:updateTilt(dt)
    -- Check for initial key press (not held down)
    local aJustPressed = love.keyboard.isDown(gKeyBindings.tiltLeft) and not self.aPressed
    local dJustPressed = love.keyboard.isDown(gKeyBindings.tiltRight) and not self.dPressed
    
    -- Update key press states
    self.aPressed = love.keyboard.isDown(gKeyBindings.tiltLeft)
    self.dPressed = love.keyboard.isDown(gKeyBindings.tiltRight)
    
    -- Only tilt on initial press, not while holding
    if aJustPressed then
        self.targetTilt = -PADDLE_MAX_TILT
        self.isTilting = true
    elseif dJustPressed then
        self.targetTilt = PADDLE_MAX_TILT
        self.isTilting = true
    end
    
    -- Smoothly interpolate to target tilt
    if self.isTilting then
        -- Tilt towards target
        if self.tiltAngle < self.targetTilt then
            self.tiltAngle = math.min(self.targetTilt, self.tiltAngle + PADDLE_TILT_SPEED * dt)
        elseif self.tiltAngle > self.targetTilt then
            self.tiltAngle = math.max(self.targetTilt, self.tiltAngle - PADDLE_TILT_SPEED * dt)
        end
        
        -- After reaching target tilt, start returning to neutral
        if math.abs(self.tiltAngle - self.targetTilt) < 0.01 then
            self.targetTilt = 0
            self.isTilting = false
        end
    else
        -- Return to neutral position
        if self.tiltAngle > 0 then
            self.tiltAngle = math.max(0, self.tiltAngle - PADDLE_TILT_RETURN_SPEED * dt)
        elseif self.tiltAngle < 0 then
            self.tiltAngle = math.min(0, self.tiltAngle + PADDLE_TILT_RETURN_SPEED * dt)
        end
    end
end

function Paddle:getTiltAngle()
    return self.tiltAngle
end

function Paddle:isTilted()
    return math.abs(self.tiltAngle) > 0.01
end

function Paddle:getWidth()
    -- Check if size modifier is active (this will be set by PlayState)
    if self.sizeModifier == 'large' then
        return self.width * 2.0 -- Twice as wide
    elseif self.sizeModifier == 'small' then
        return self.width * 0.5 -- Half as wide
    else
        return self.width
    end
end

function Paddle:setSizeModifier(modifierType)
    self.sizeModifier = modifierType
end

function Paddle:setSpeedModifier(active)
    self.speedModifierActive = active
end

function Paddle:render()
    -- Save the current graphics state
    love.graphics.push()
    
    -- Move to paddle center for rotation
    local centerX = self.x + self:getWidth() / 2
    local centerY = self.y + self.height / 2
    
    -- Add color tint when tilted (reddish tint for aggressive feel)
    if math.abs(self.tiltAngle) > 0.1 then
        local tintIntensity = math.abs(self.tiltAngle) / PADDLE_MAX_TILT
        love.graphics.setColor(1 + tintIntensity * 0.3, 1 - tintIntensity * 0.2, 1 - tintIntensity * 0.2, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Translate to center, rotate, then translate back
    love.graphics.translate(centerX, centerY)
    love.graphics.rotate(self.tiltAngle)
    love.graphics.translate(-centerX, -centerY)
    
    -- Draw the paddle, scaling it to its current width
    love.graphics.draw(gTextures['main'], gFrames['paddles'][1], self.x, self.y, 0, self:getWidth() / 64)
    
    -- Restore the graphics state
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end
