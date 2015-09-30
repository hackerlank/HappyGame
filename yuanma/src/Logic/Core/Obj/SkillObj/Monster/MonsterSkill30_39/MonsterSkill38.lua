--===================================================
-- (c) copyright 2014 - 2015, www.cfanim.cn
-- All Rights Reserved.
--==================================================
-- filename:  MonsterSkill38.lua
-- author:    taoye
-- e-mail:    553681974@qq.com
-- created:   2015/7/22
-- descrip:   怪物技能攻击38  判官
--===================================================
local MonsterSkill38 = class("MonsterSkill38",function(master, skillInfo)
    return require("SkillObj"):create(master, skillInfo)
end)

-- 构造函数
function MonsterSkill38:ctor()
    self._strName = "MonsterSkill38"                            -- 技能名称
    self._kTypeID = kType.kSkill.kID.kMonsterSkill38            -- 技能对象类型
    self._pCurState = nil                                      -- 技能当前的状态机状态
    
    self._nRoleAttackActionIndex = 6                           -- 角色攻击动作index
    self._fChantDelayTime = 0.85                               -- 吟唱动作持续时间s
    
end

-- 创建函数
function MonsterSkill38:create(master,skillInfo)
    local skill = MonsterSkill38.new(master, skillInfo)
    skill:dispose()
    return skill
end

-- 处理函数
function MonsterSkill38:dispose()
    ------------------- 初始化 ------------------------  
    -- 创建状态机
    self:initStateMachine()
    
    ------------------- 结点事件------------------------
    local function onNodeEvent(event)
        if event == "exit" then
            self:onExitMonsterSkill38()
        end
    end
    self:registerScriptHandler(onNodeEvent)
    
    return
end

-- 退出函数
function MonsterSkill38:onExitMonsterSkill38()    
    self:onExitSkillObj()
end

-- 循环更新
function MonsterSkill38:update(dt)
    self:updateSkillObj(dt)
end

-- 创建状态机
function MonsterSkill38:initStateMachine()
    self._pStateMachineDelegate = require("StateMachineDelegate"):create()
    local pStateMachine = require("BattleSkillStateMachine"):create(self)
    self._pStateMachineDelegate:addStateMachine(pStateMachine)
end


-- 技能使用接口
function MonsterSkill38:onUse() 
    -- 立即手动切换到吟唱状态
    if self._pCurState._kTypeID == kType.kState.kBattleSkill.kIdle then
        self._fCDCounter = 0   -- CD时间清空     
        self._pCurState._pOwnerMachine:setCurStateByTypeID(kType.kState.kBattleSkill.kChant)
    end
end

-- 初始化动作帧事件回调
function MonsterSkill38:initActionsFrameEvents(index, action)
    if index == 1 then
        local function onFrameEvent1(frame)
            if nil == frame then
                return
            end
            self._strFrameEventName = frame:getEvent()
        end
        action:setFrameEventCallFunc(onFrameEvent1)
    end

end

-- 帧事件的处理
function MonsterSkill38:procActionsFrameEvents()
    if self._strFrameEventName == "" then
    elseif self._strFrameEventName == "start1" then
    elseif self._strFrameEventName == "hurt1_1" then
        self:setCurAttackFrameEventInfo(1,1)
        self:getAIManager():skillCollidingOnEnemysAndHurt(self:getMaster(), self)
    elseif self._strFrameEventName == "end1" then
        self:clearCurAttackFrameEventInfo()
        self._pCurState._pOwnerMachine:setCurStateByTypeID(kType.kState.kBattleSkill.kIdle)
    end
    self._strFrameEventName = ""
end
-------------------------------------------------------------------------------------------------
-- 技能待机状态onEnter时技能操作
function MonsterSkill38:onEnterIdleDo(state)
    self._pCurState = state
    self:setVisible(false)
    
end

-- 技能待机状态onExit时技能操作
function MonsterSkill38:onExitIdleDo()

end

-- 技能待机状态onUpdate时技能操作
function MonsterSkill38:onUpdateIdleDo(dt)

end
-------------------------------------------------------------------------------------------------
-- 技能吟唱状态onEnter时技能操作
function MonsterSkill38:onEnterChantDo(state)
    self._pCurState = state
    
    -- 刷新方向（考虑野怪是否有指定转向）
    --[[
    if TableTempleteMonster[self:getMaster()._pRoleInfo.TempleteID].AppointedRotation == -1 then
        self:getAIManager():roleRefreshDirectionWhenAttackEnemys(self:getMaster(), self)
    end
    ]]
    
    -- 播放攻击时的人物动作
    self:getMaster():playAttackAction(self._nRoleAttackActionIndex)

    -- 人物动作结束
    local roleActOver = function()
        -- 人物动作结束后，可以开始释放下一个技能
        if self:getMaster():getStateMachineByTypeID(kType.kStateMachine.kBattleMonster)._pCurState._kTypeID == kType.kState.kBattleMonster.kSkillAttack then
            self:getMaster():getStateMachineByTypeID(kType.kStateMachine.kBattleMonster)._pCurState._bToNextSkill = true
        end
    end
    local duration = self:getMaster():getAttackActionTime(self._nRoleAttackActionIndex)
    self._pSkillActOverActionNode:stopAllActions()
    self._pSkillActOverActionNode:runAction(cc.Sequence:create(cc.DelayTime:create(duration), cc.CallFunc:create(roleActOver)))

    ---人物吟唱动作播放到一段时间时进入到process阶段---------------------------------------------------------------------------
    local chantOver = function()
        self._pCurState._pOwnerMachine:setCurStateByTypeID(kType.kState.kBattleSkill.kProcess)
    end
    self._pChantOverActionNode:stopAllActions()
    self._pChantOverActionNode:runAction(cc.Sequence:create(cc.DelayTime:create(self._fChantDelayTime), cc.CallFunc:create(chantOver)))  -- 0.1秒动作后放出技能  
    
end

-- 技能吟唱状态onExit时技能操作
function MonsterSkill38:onExitChantDo()

end

-- 技能吟唱状态onUpdate时技能操作
function MonsterSkill38:onUpdateChantDo(dt)

end
-------------------------------------------------------------------------------------------------
-- 技能执行状态onEnter时技能操作
function MonsterSkill38:onEnterProcessDo(state)
    self._pCurState = state
    self._pCurState._pOwnerMachine:setCurStateByTypeID(kType.kState.kBattleSkill.kRelease)

end

-- 技能执行状态onExit时技能操作
function MonsterSkill38:onExitProcessDo()

end

-- 技能执行状态onUpdate时技能操作
function MonsterSkill38:onUpdateProcessDo(dt)

end
-----------------------------------------------------------------------------------------------------
-- 技能释放状态onEnter时技能操作
function MonsterSkill38:onEnterReleaseDo(state)
    self._pCurState = state
    
    self:setVisible(true)
    
    self._nSettledZorder = kZorder.kMaxSkill
    
    local posX, posY = self:getMaster():getPosition()
    self:setPosition(posX, posY + self:getMaster():getHeight()/2)
    self:playActionByIndex(1)
    
    -- 技能释放音效
    AudioManager:getInstance():playEffect(self._tTempleteInfo.SkillReleaseSound)
    
end

-- 技能释放状态onExit时技能操作
function MonsterSkill38:onExitReleaseDo()

end

-- 技能释放状态onUpdate时技能操作
function MonsterSkill38:onUpdateReleaseDo(dt)

end

---------------------------------------------------------------------------------------------------------
return MonsterSkill38
