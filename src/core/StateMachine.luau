--[[
    SmartNPC :: StateMachine
    Finite state machine for NPC behavioral states.
    
    States: Idle, Approaching, Talking, Acting, Cooldown
    Handles transitions, enter/exit callbacks, and timers.
]]

local StateMachine = {}
StateMachine.__index = StateMachine

export type StateConfig = {
    enter: ((self: any, data: any?) -> ())?,
    exit: ((self: any) -> ())?,
    update: ((self: any, dt: number) -> ())?,
    timeout: number?,
    transitions: {[string]: string}?,
}

function StateMachine.new(states: {[string]: StateConfig}, initialState: string)
    local self = setmetatable({}, StateMachine)
    self._states = states
    self._currentState = initialState
    self._stateTime = 0
    self._data = nil
    self._locked = false
    
    -- Enter initial state
    local state = self._states[initialState]
    if state and state.enter then
        state.enter(self, nil)
    end
    
    return self
end

function StateMachine:getState(): string
    return self._currentState
end

function StateMachine:getStateTime(): number
    return self._stateTime
end

function StateMachine:transition(event: string, data: any?)
    if self._locked then return false end
    
    local current = self._states[self._currentState]
    if not current or not current.transitions then return false end
    
    local nextState = current.transitions[event]
    if not nextState then return false end
    
    if not self._states[nextState] then
        warn("[SmartNPC] StateMachine: Unknown state '" .. nextState .. "'")
        return false
    end
    
    -- Exit current state
    if current.exit then
        current.exit(self)
    end
    
    local prevState = self._currentState
    self._currentState = nextState
    self._stateTime = 0
    self._data = data
    
    -- Enter new state
    local newState = self._states[nextState]
    if newState and newState.enter then
        newState.enter(self, data)
    end
    
    return true, prevState
end

function StateMachine:forceState(stateName: string, data: any?)
    if not self._states[stateName] then
        warn("[SmartNPC] StateMachine: Unknown state '" .. stateName .. "'")
        return
    end
    
    local current = self._states[self._currentState]
    if current and current.exit then
        current.exit(self)
    end
    
    self._currentState = stateName
    self._stateTime = 0
    self._data = data
    
    local newState = self._states[stateName]
    if newState and newState.enter then
        newState.enter(self, data)
    end
end

function StateMachine:update(dt: number)
    self._stateTime += dt
    
    local current = self._states[self._currentState]
    if not current then return end
    
    -- Check timeout
    if current.timeout and self._stateTime >= current.timeout then
        if current.transitions and current.transitions["timeout"] then
            self:transition("timeout")
            return
        end
    end
    
    -- Run update
    if current.update then
        current.update(self, dt)
    end
end

function StateMachine:lock()
    self._locked = true
end

function StateMachine:unlock()
    self._locked = false
end

function StateMachine:getData()
    return self._data
end

-- Pre-built NPC state machine configuration
function StateMachine.createNPCStates(callbacks: {[string]: (...any) -> any}): {[string]: StateConfig}
    return {
        Idle = {
            enter = callbacks.onIdle,
            transitions = {
                playerNearby = "Approaching",
                startConversation = "Talking",
            },
        },
        Approaching = {
            enter = callbacks.onApproach,
            timeout = 5,
            transitions = {
                reachedPlayer = "Talking",
                playerLeft = "Idle",
                timeout = "Idle",
            },
        },
        Talking = {
            enter = callbacks.onStartTalking,
            exit = callbacks.onStopTalking,
            update = callbacks.onTalkingUpdate,
            transitions = {
                conversationEnd = "Cooldown",
                playerLeft = "Idle",
                actionTriggered = "Acting",
            },
        },
        Acting = {
            enter = callbacks.onAct,
            timeout = 10,
            transitions = {
                actionComplete = "Talking",
                timeout = "Idle",
            },
        },
        Cooldown = {
            enter = callbacks.onCooldown,
            timeout = 3,
            transitions = {
                timeout = "Idle",
                playerNearby = "Approaching",
            },
        },
    }
end

return StateMachine
