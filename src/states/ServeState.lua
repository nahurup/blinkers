ServeState = Class { __includes = BaseState }

function ServeState:enter(params)
	self.paddle = params.paddle
	self.health = params.health
	self.score = params.score
	self.level = params.level
	self.recoverPoints = params.recoverPoints
end

function ServeState:update(dt)
	self.paddle:update(dt)

	if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
		gStateMachine:change('play', {
			paddle = self.paddle,
			health = self.health,
			score = self.score,
			level = self.level,
			recoverPoints = self.recoverPoints
		})
	end

	if love.keyboard.wasPressed('escape') then
		love.event.quit()
	end
end

function ServeState:render()
	self.paddle:render()

	renderScore(self.score)
	renderHealth(self.health)
	love.graphics.setFont(gFonts['medium'])
	-- Draw shadow first
	love.graphics.setColor(0, 0, 0, 0.5)
	love.graphics.printf('Press Enter to start!', 1, VIRTUAL_HEIGHT / 2 + 1, VIRTUAL_WIDTH, 'center')
	-- Draw main text
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf('Press Enter to start!', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
end
