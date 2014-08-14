TIME_HERO_SELECTION , TIME_PRE_GAME , TIME_POST_GAME = 10.0 , 10.0 , 10.0

TIME_ROUND_REST = 10.0
TOTAL_ROUNDS = 11

GOLD_TICK_TIME = 60.0
GOLD_PER_TICK = 0


CUSTOM_STATE_PREPARE = 0
CUSTOM_STATE_IN_ROUND = 1
CUSTOM_STATE_ROUND_REST = 2
CUSTOM_STATE_GAME_END = 3


BASE_RAZE_DAMAGE = 200
BASE_RAZE_RADIUS = 250

BASE_RAZE_PARTIC = {
	'particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf'
}

RAZE_DATA = {}
for i=0,9 do
	RAZE_DATA[i] = {}
	RAZE_DATA[i].RazeDamage = BASE_RAZE_DAMAGE
	RAZE_DATA[i].RazeRadius = BASE_RAZE_RADIUS
	RAZE_DATA[i].RazePartic = BASE_RAZE_PARTIC
end

RAZE_BUILD = {}
for i=0,9 do
	RAZE_BUILD[i] = 
	{
		["moonlight_raze"] = 0,
		["sensitive_raze"] = 0,
		["overpower_raze"] = 0
	}
end

--require('sfwarshero')

if SFWarsMode == nil then
	SFWarsMode = class({})
end

function Activate()
	SFWarsMode:InitGameMode()
end

function SFWarsMode:InitGameMode()
	self.eGameEntity = GameRules:GetGameModeEntity()

	self:InitPara()
	self:SetGameRules()
	self:RegisterEventListener()
	self:StartThink()

	self.RazeData = {}

end

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "particles/units/heroes/hero_mirana/mirana_starfall_attack.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
	PrecacheResource( "particle", "particles/units/heroes/hero_mirana/mirana_starfall_attack.vpcf", context )

end

function SFWarsMode:InitPara()
	self.nCurrState = CUSTOM_STATE_PREPARE
	self.RoundCount = 0
	self.nGoodWinRounds = 0
	self.nBadWinRounds  = 0
	self._hideHud = {}
end

function SFWarsMode:SetGameRules()
	GameRules:SetTimeOfDay( 0.75 )
	GameRules:SetHeroRespawnEnabled( false )
	GameRules:SetUseUniversalShopMode( false )
	GameRules:SetHeroSelectionTime( TIME_HERO_SELECTION )
	GameRules:SetPreGameTime( TIME_PRE_GAME )
	GameRules:SetPostGameTime( TIME_POST_GAME )
	GameRules:SetTreeRegrowTime( 60.0 )
	GameRules:SetGoldTickTime( GOLD_TICK_TIME )
	GameRules:SetGoldPerTick( GOLD_PER_TICK )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride( true )
end

function SFWarsMode:RegisterEventListener()
	--ListenToGameEvent( "entity_killed", Dynamic_Wrap( SFWarsMode, "OnEntityKilled" ), self )
	ListenToGameEvent('npc_spawned',Dynamic_Wrap(SFWarsMode,"OnNPCSpawned"),self)

	--ListenToGameEvent('sf_wars_increase_raze_damage0',Dynamic_Wrap(SFWarsMode,"OnInCreaseRazeDamagez"),self)
	--ListenToGameEvent('sf_wars_increase_raze_damage',Dynamic_Wrap(SFWarsMode,"OnInCreaseRazeDamage"),self)
end

function SFWarsMode:OnInCreaseRazeDamage(keys)
	print('HUD CALL INCREASE RAZE DAMAGE SUCCESS')
end
function SFWarsMode:OnInCreaseRazeDamagez(keys)
	print('HUD CALL INCREASE RAZE DAMAGE SUCCESS zzzzzzzzzzzzzz')
end

function SFWarsMode:StartThink()
	self.eGameEntity:SetThink('OnThink' , self , 1 )
end

function SFWarsMode:OnThink()
	if self.t0 == nil then
		self.t0 = GameRules:GetGameTime()
	end
	local time = GameRules:GetGameTime()
	local dt = time - self.t0
	self.t0 = time
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then return nil else

		if self.nCurrState == CUSTOM_STATE_PREPARE then
			self:ThinkPrePare(dt)		
		elseif self.nCurrState == CUSTOM_STATE_IN_ROUND then
			self:ThinkInRound(dt)	
		elseif self.nCurrState == CUSTOM_STATE_ROUND_REST then
			self:ThinkRoundRest(dt)
		elseif self.nCurrState == CUSTOM_STATE_GAME_END then
			self:ThinkGameEnd()
		end
		return 1
	end
end

function SFWarsMode:ThinkPrePare(dt)
	if GameRules:State_Get() > DOTA_GAMERULES_STATE_PRE_GAME then
		
		self.nCurrState = CUSTOM_STATE_ROUND_REST
		
		local center_msg = {
			message = 'sfwars_game_start_in_10',
			duration = 5
		}
		FireGameEvent('show_center_message',center_message)
	end
end

function SFWarsMode:ThinkRoundRest(dt)
	if self.fTimeRested == nil then
		self.fTimeRested = 0
	end
	self.fTimeRested = self.fTimeRested + dt
	if self.fTimeRested >= TIME_ROUND_REST then
		self.RoundCount = self.RoundCount + 1
		self.nCurrState = CUSTOM_STATE_IN_ROUND
		self.fTimeRested = nil
	else
		local fTimeLeft = TIME_ROUND_REST - self.fTimeRested
		if fTimeLeft < 1 then
			self:ShowCenterMessage('1',0.9)
			do return end
		elseif fTimeLeft < 2 then
			self:ShowCenterMessage('2',0.9)
			do return end
		elseif fTimeLeft < 3 then
			self:ShowCenterMessage('3',0.9)
			do return end
		end
	end
end

function SFWarsMode:ThinkInRound(dt)
	local nGoodAlive = 0
	local nBadAlive = 0
	for i = 0,9 do
		local hPlayer = PlayerResource:GetPlayer(i)
		if hPlayer then
			local hHero = hPlayer:GetAssignedHero()
			if hHero then
				if hHero:IsAlive() then
					if hPlayer:GetTeam() == DOTA_TEAM_GOODGUYS then
						nGoodAlive = nGoodAlive + 1
					elseif hPlayer:GetTeam() == DOTA_TEAM_BADGUYS then
						nBadAlive = nBadAlive  + 1
					end
				end
			end
		end
	end
	if nGoodAlive == 0 then
		self.nBadWinRounds = self.nBadWinRounds + 1
		self.eGameEntity:SetTopBarTeamValue(DOTA_TEAM_GOODGUYS,self.nGoodWinRounds)
		self.eGameEntity:SetTopBarTeamValue(DOTA_TEAM_BADGUYS,self.nBadWinRounds)
	end
	if nBadAlive == 0 then
		self.nGoodWinRounds = self.nGoodWinRounds + 1
		self.eGameEntity:SetTopBarTeamValue(DOTA_TEAM_GOODGUYS,self.nGoodWinRounds)
		self.eGameEntity:SetTopBarTeamValue(DOTA_TEAM_BADGUYS,self.nBadWinRounds)
	end
	local bIsRoundEnd = false
	if nGoodAlive == 0 or nBadAlive == 0 then
		bIsRoundEnd = true
	end
	if bIsRoundEnd then
		if self.RoundCount > TOTAL_ROUNDS then
			self.nCurrState = CUSTOM_STATE_GAME_END
		else
			self.nCurrState = CUSTOM_STATE_ROUND_REST
		end
	end
end

function SFWarsMode:IsRoundEnd(goodalive,badalive)
	if goodalive == 0 then
		self.nBadWinRounds = self.nBadWinRounds + 1
		self.eGameEntity:SetTopBarTeamValue(DOTA_TEAM_GOODGUYS,self.nGoodWinRounds)
		self.eGameEntity:SetTopBarTeamValue(DOTA_TEAM_BADGUYS,self.nBadWinRounds)
	end
	if badalive == 0 then
		self.nGoodWinRounds = self.nGoodWinRounds + 1
		self.eGameEntity:SetTopBarTeamValue(DOTA_TEAM_GOODGUYS,self.nGoodWinRounds)
		self.eGameEntity:SetTopBarTeamValue(DOTA_TEAM_BADGUYS,self.nBadWinRounds)
	end
	if goodalive == 0 or goodalive == 0 then
		return true
	end
	return false
end

function SFWarsMode:ThinkGameEnd()

	local WINNER = nil
	if self.nGoodWinRounds > self.nBadWinRounds then
		WINNER = DOTA_TEAM_GOODGUYS
	else
		WINNER = DOTA_TEAM_BADGUYS
	end

	GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)

	GameRules:SetSafeToLeave(true)
end

function SFWarsMode:SetAbilityPoints(hero)
	for i = 1,hero:GetAbilityCount() do
		local ABILITY = hero:GetAbilityByIndex(i)
		if ABILITY then ABILITY:SetLevel(1) end
	end
	hero:SetAbilityPoints(0)
end


function SFWarsMode:ShowCenterMessage(msg,dt)
	if msg and dt then
		local center_message = {
			message = msg,
			duration = dt
		}
		FireGameEvent('show_center_message',center_message)
	end
end

function SFWarsMode:OnNPCSpawned(keys)
	print('FUNCTION NPC SPAWN CALLED')
	local entity = EntIndexToHScript(keys.entindex)
	if entity then print(entity:GetUnitName()) else return end
	if entity:GetUnitName() == 'npc_dota_hero_nevermore' then
		for i = 0,4 do
			local ability = entity:GetAbilityByIndex(i)
			if ability then ability:SetLevel(1) end
		end
		entity:SetAbilityPoints(0)
	end
end

-- ABILITY HOOKS
function OnRaze(keys)
	local caster = keys.caster or EntIndexToHScript(keys.caster_entindex)
	local ABILITY = keys.ability

	local casterOrigin = caster:GetOrigin()
	local casterFV = caster:GetForwardVector()
	
	local playerid = caster:GetPlayerID() 


	local nRazeDamage = RAZE_DATA[playerid].RazeDamage
	local nRazeRadius = RAZE_DATA[playerid].RazeRadius
	local vRazeParticles = RAZE_DATA[playerid].RazePartic

	local nRazeRange = 0
	if ABILITY:GetName() == 'sfwars_shadowraze_1' then
		nRazeRange = 200
	elseif ABILITY:GetName() == 'sfwars_shadowraze_2' then
		nRazeRange = 450
	elseif ABILITY:GetName() == 'sfwars_shadowraze_3' then
		nRazeRange = 700
	end

	local vCenter = casterOrigin + (casterFV * nRazeRange)
	for k,v in pairs(vRazeParticles) do
		local nPIndex = ParticleManager:CreateParticle( 
			v ,
			PATTACH_CUSTOMORIGIN,caster)

		ParticleManager:SetParticleControl(nPIndex,0,vCenter)
		ParticleManager:SetParticleControl(nPIndex,3,Vector(nRazeRadius,nRazeRadius,nRazeRadius))
		ParticleManager:ReleaseParticleIndex(nPIndex)
	end
	
	
	local targets = FindUnitsInRadius(
		caster:GetTeam(),       --caster team
        vCenter,       --find position
        nil,                    --find entity
        nRazeRadius,                    --find radius
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        0, FIND_CLOSEST,
        false
	)

	print('RAZE DAMAGE'..nRazeDamage)
	print('RAZE RADIUS'..nRazeRadius)

	if targets then
		for k,v in pairs(targets) do
			local damage_dealt = ApplyDamage({
				victim = v,
				attacker = caster,
				damage = nRazeDamage,
				damage_type = DAMAGE_TYPE_MAGICAL,
				damage_flags = 0,
				ability = ABILITY
			})
			if damage_dealt then
				print('damage_deal .. '..damage_dealt)
			end
		end
	end
end





-- ITEMS
function OnItemShengjieWangePurchased(keys)
    local caster = keys.caster
    if not caster:FindAbilityByName('ability_shengjiewange') then
        caster:AddAbility('sfwars_requiem_holy') 
    end
    caster:SwapAbilities('sfwars_requiem_init','sfwars_requiem_holy',false,true)
    caster:FindAbilityByName('sfwars_requiem_holy'):SetLevel(1)
end

function OnItemJingzhunYingyaPurchased(keys)
    local plyid = keys.caster:GetPlayerID()
    RAZE_DATA[plyid].RazeDamage = RAZE_DATA[plyid].RazeDamage + tonumber(keys.BonusDamage)
    RAZE_DATA[plyid].RazeRadius = RAZE_DATA[plyid].RazeRadius - tonumber(keys.RaduceRadius)
end

function OnItemLiuxingYingyaPurchased(keys)
    local plyid = keys.caster:GetPlayerID()
	table.insert(RAZE_DATA[plyid].RazePartic ,"particles/units/heroes/hero_mirana/mirana_starfall_attack.vpcf")
	for i=0,2 do
		local ABILITY = keys.caster:GetAbilityByIndex(i)
		local castpoint = ABILITY:GetCastPoint()
		ABILITY:SetOverrideCastPoint(castpoint + tonumber(keys.ReduceCastPoint))
	end
	 RAZE_DATA[plyid].RazeRadius = RAZE_DATA[plyid].RazeRadius + tonumber(keys.BonusRadius)
end

function OnItemChaojiYingyaPurchased(keys)
	local plyid = keys.caster:GetPlayerID()
    RAZE_DATA[plyid].RazeDamage = RAZE_DATA[plyid].RazeDamage + tonumber(keys.BonusDamage)
    RAZE_DATA[plyid].RazeRadius = RAZE_DATA[plyid].RazeRadius + tonumber(keys.BonusRadius)
end

function OnItemFanweitishengPurchased(keys)
	local caster = keys.caster
	local plyid = caster:GetPlayerID()

	local modifier_count = caster:GetModifierCount()

	local chaojiyingya_count = 0
	local jingzhunyingya = false
	for i=0,modifier_count -1 do
		local modifiername = caster:GetModifierNameByIndex(i)
		print("MODIFIER CATCHED,NAME:"..modifiername)
		if modifiername == "modifier_fanweitisheng_counter" then
			chaojiyingya_count = chaojiyingya_count + 1
		end
		if modifiername == 'modifier_jingzhunyingya_interlock' then
			jingzhunyingya = true
		end
	end
	if jingzhunyingya then
		SendCustomMessage('JIGNZHUN', caster:GetTeam() , 0)
		return
	end
	if chaojiyingya_count > 5 then
		SendCustomMessage('GOULE', caster:GetTeam() , 0)
	else
		RAZE_DATA[plyid].RazeRadius = RAZE_DATA[plyid].RazeRadius + tonumber(keys.BonusRadius)
	end
end