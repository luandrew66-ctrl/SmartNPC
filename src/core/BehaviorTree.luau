--[[
    SmartNPC :: BehaviorTree
    A lightweight behavior tree implementation for NPC decision-making.
    
    Supports: Selector, Sequence, Condition, Action, Decorator nodes.
    Returns: SUCCESS, FAILURE, or RUNNING.
]]

local BehaviorTree = {}
BehaviorTree.__index = BehaviorTree

-- Node status constants
BehaviorTree.SUCCESS = "success"
BehaviorTree.FAILURE = "failure"
BehaviorTree.RUNNING = "running"

export type NodeDef = {
    type: string,
    children: {NodeDef}?,
    check: string?,
    run: string?,
    decorator: string?,
    child: NodeDef?,
}

export type Context = {
    npc: any,
    player: Player?,
    blackboard: {[string]: any},
    conditions: {[string]: (ctx: Context) -> boolean},
    actions: {[string]: (ctx: Context) -> string},
}

-- Create a new BehaviorTree from a node definition table
function BehaviorTree.new(definition: NodeDef)
    local self = setmetatable({}, BehaviorTree)
    self._root = BehaviorTree._buildNode(definition)
    return self
end

-- Build a node recursively from definition
function BehaviorTree._buildNode(def: NodeDef)
    local node = {
        type = def.type,
    }

    if def.type == "selector" or def.type == "sequence" then
        node.children = {}
        if def.children then
            for _, childDef in ipairs(def.children) do
                table.insert(node.children, BehaviorTree._buildNode(childDef))
            end
        end

    elseif def.type == "condition" then
        node.check = def.check

    elseif def.type == "action" then
        node.run = def.run

    elseif def.type == "decorator" then
        node.decorator = def.decorator
        if def.child then
            node.child = BehaviorTree._buildNode(def.child)
        end

    elseif def.type == "inverter" then
        if def.child then
            node.child = BehaviorTree._buildNode(def.child)
        end

    elseif def.type == "repeater" then
        node.times = def.times or 1
        if def.child then
            node.child = BehaviorTree._buildNode(def.child)
        end
    end

    return node
end

-- Tick the tree once with context
function BehaviorTree:tick(context: Context): string
    return BehaviorTree._tickNode(self._root, context)
end

-- Internal node evaluation
function BehaviorTree._tickNode(node, context: Context): string
    local nodeType = node.type

    if nodeType == "selector" then
        -- Try each child until one succeeds
        for _, child in ipairs(node.children) do
            local result = BehaviorTree._tickNode(child, context)
            if result ~= BehaviorTree.FAILURE then
                return result
            end
        end
        return BehaviorTree.FAILURE

    elseif nodeType == "sequence" then
        -- Run each child; fail if any fails
        for _, child in ipairs(node.children) do
            local result = BehaviorTree._tickNode(child, context)
            if result ~= BehaviorTree.SUCCESS then
                return result
            end
        end
        return BehaviorTree.SUCCESS

    elseif nodeType == "condition" then
        local checkFn = context.conditions[node.check]
        if checkFn and checkFn(context) then
            return BehaviorTree.SUCCESS
        end
        return BehaviorTree.FAILURE

    elseif nodeType == "action" then
        local actionFn = context.actions[node.run]
        if actionFn then
            return actionFn(context)
        end
        return BehaviorTree.FAILURE

    elseif nodeType == "inverter" then
        if node.child then
            local result = BehaviorTree._tickNode(node.child, context)
            if result == BehaviorTree.SUCCESS then
                return BehaviorTree.FAILURE
            elseif result == BehaviorTree.FAILURE then
                return BehaviorTree.SUCCESS
            end
            return result
        end
        return BehaviorTree.FAILURE

    elseif nodeType == "repeater" then
        if node.child then
            for _ = 1, (node.times or 1) do
                BehaviorTree._tickNode(node.child, context)
            end
        end
        return BehaviorTree.SUCCESS
    end

    return BehaviorTree.FAILURE
end

-- Utility: Create common tree patterns
function BehaviorTree.ifThen(conditionName: string, actionName: string): NodeDef
    return {
        type = "sequence",
        children = {
            { type = "condition", check = conditionName },
            { type = "action", run = actionName },
        },
    }
end

function BehaviorTree.ifThenElse(conditionName: string, actionIfTrue: string, actionIfFalse: string): NodeDef
    return {
        type = "selector",
        children = {
            {
                type = "sequence",
                children = {
                    { type = "condition", check = conditionName },
                    { type = "action", run = actionIfTrue },
                },
            },
            { type = "action", run = actionIfFalse },
        },
    }
end

return BehaviorTree
