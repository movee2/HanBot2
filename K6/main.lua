local version = "1.05"

local common = module.load("CyrexKha6", "common")
local ts = module.internal("TS")
local orb = module.internal("orb")
local gpred = module.internal("pred")
local minionmanager = objManager.minions

local QlvlDmg = {50, 75, 100, 125, 150}
local WlvlDmg = {85, 115, 145, 165, 205}
local ElvlDmg = {65, 100, 135, 170, 205}
local IsoDmg = {14, 22, 30, 38, 46, 54, 62, 70, 78, 86, 94, 102, 110, 118, 126, 134, 142, 150}
local QRange, ERange = 0, 0
local Isolated = false

local ePred = { delay = 0.25, radius = 300, speed = 1650, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local wPred = { delay = 0.25, width = 70, speed = 1650, boundingRadiusMod = 1, collision = { hero = true, minion = true, wall = true } }

local menu = menu("k6", "Khantum Phyzix")
	menu:header("script", "Khantum Phyzix")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("combo", "Combo Key", "Space", false)
		menu.keys:keybind("harass", "Harass Key", "C", false)
		menu.keys:keybind("clear", "Clear Key", "V", false)
		menu.keys:keybind("run", "Marathon Mode", "S", false)

	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Q Settings")
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:header("xd", "W Settings")
		menu.combo:boolean("w", "Use W", true)
		menu.combo:header("xd", "E Settings")
		menu.combo:boolean("e", "Use E in Combo", false)
		menu.combo:dropdown("ed", "E Mode", 2, {"Mouse Pos", "With Prediction"})
		menu.combo:header("xd", "R Settings")
		menu.combo:boolean("r", "Use R", true)
		menu.combo:dropdown("rm", "Ultimate Mode: ", 2, {"Always Ultimate", "Smart Ultimate"})

	menu:menu("harass", "Harass Settings")
		menu.harass:header("xd", "Harass Settings")
		menu.harass:boolean("q", "Use Q", true)
		menu.harass:boolean("w", "Use W", true)
		menu.harass:slider("Mana", "Min. Mana Percent: ", 10, 0, 100, 10)

	menu:menu("jg", "Jungle Clear Settings")
		menu.jg:header("xd", "Jungle Settings")
		menu.jg:boolean("q", "Use Q", true)
		menu.jg:boolean("w", "Use W", true)

	menu:menu("auto", "Automatic Settings")
		menu.auto:header("xd", "KillSteal Settings")
		menu.auto:boolean("uks", "Use Smart Killsteal", true)
		menu.auto:boolean("ukse", "Use E in Killsteal", false)
		menu.auto:slider("mhp", "Min. HP to E: ", 30, 0, 100, 10)

	menu:menu("draws", "Draw Settings")
		menu.draws:header("xd", "Drawing Options")
		menu.draws:boolean("q", "Draw Q Range", true)
		menu.draws:boolean("e", "Draw E Range", true)
	ts.load_to_menu();
	menu:header("version", "Version: 1.05")
	menu:header("author", "Author: Coozbie")

local function select_etarget(res, obj, dist)
	if dist > 970 then return end
	res.obj = obj
	return true
end

local function select_target(res, obj, dist)
	if dist > 375 then return end
	res.obj = obj
	return true
end
-- Get target selector result

local function get_target(func)
	return ts.get_result(func).obj
end

local function qDmg(target)
	if player:spellSlot(0).level > 0 then
	 	local damage = QlvlDmg[player:spellSlot(0).level] + (common.GetBonusAD() * 1.3) or 0
	  	if Isolated then
	    	damage = damage + damage
	  	end
	  	return common.CalculatePhysicalDamage(target, damage)
	end
end

local function wDmg(target)
	if player:spellSlot(1).level > 0 then
	    local damage = WlvlDmg[player:spellSlot(1).level] + (common.GetBonusAD() * 1) or 0
	    return common.CalculatePhysicalDamage(target, damage)
	end
end

local function eDmg(target)
	if player:spellSlot(2).level > 0 then
		local damage = ElvlDmg[player:spellSlot(2).level] + (common.GetBonusAD() * 0.2) or 0
		return common.CalculatePhysicalDamage(target, damage)
	end
end

local function CastE(target)
	if player:spellSlot(2).state == 0 then
		if player:spellSlot(2).name == "KhazixE" then
			local res = gpred.circular.get_prediction(ePred, target)
			if res and res.startPos:dist(res.endPos) < 600 and res.startPos:dist(res.endPos) > 325 and not navmesh.isWall(vec3(res.endPos.x, game.mousePos.y, res.endPos.y)) then
				player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
			end
		elseif player:spellSlot(2).name == "KhazixELong" then
			local res = gpred.circular.get_prediction(ePred, target)
			if res and res.startPos:dist(res.endPos) < 900 and res.startPos:dist(res.endPos) > 400 and not navmesh.isWall(vec3(res.endPos.x, game.mousePos.y, res.endPos.y)) then
				player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
			end
		end
	end
end

local function CastGPE(target)
	if player:spellSlot(2).name == "KhazixELong" then
		if vec3(target.x, target.y, target.z):dist(player) < 1100 and target.pos:dist(player.pos) > 900 and player:spellSlot(2).state == 0 and not navmesh.isWall(target.pos) then
			player:castSpell("pos", 2, target.pos)
		end
	elseif player:spellSlot(2).name == "KhazixE" then
		if vec3(target.x, target.y, target.z):dist(player) < 900 and target.pos:dist(player.pos) > 600 and player:spellSlot(2).state == 0 and not navmesh.isWall(target.pos) then
			player:castSpell("pos", 2, target.pos)
		end
	end
end

local function CastW(target)
	if player:spellSlot(1).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (970 * 970) then
		local seg = gpred.linear.get_prediction(wPred, target)
		if seg and seg.startPos:dist(seg.endPos) < 970 then
			if not gpred.collision.get_prediction(wPred, seg, target) then
				player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	end
end

local function CastR(target)
	if player:spellSlot(3).state == 0 then
		player:castSpell("self", 3)
	end
end

local function CastQ(target)
	if player:spellSlot(0).state == 0 then
		if player:spellSlot(0).name == "KhazixQ" then
			if target.pos:dist(player.pos) <= 325 then
				player:castSpell("obj", 0, target)
			end
		elseif player:spellSlot(0).name == "KhazixQLong" then
			if target.pos:dist(player.pos) <= 375 then
				player:castSpell("obj", 0, target)
			end
		end
	end
end

local function PlayerAD()
	if Isolated == false then
    	return player.flatPhysicalDamageMod + player.baseAttackDamage
    else
    	return player.flatPhysicalDamageMod + player.baseAttackDamage + (IsoDmg[player.levelRef] + player.flatPhysicalDamageMod * .2 )
    end
end

local function HasSionBuff(e)
	for i = 0, e.buffManager.count - 1 do
		local buff = e.buffManager:get(i)
		if buff and buff.valid and buff.name == 'sionpassivezombie' then
			return true
		end
	end
end

local function HasKhazixBuff(k)
	for i = 0, k.buffManager.count - 1 do
		local buff = k.buffManager:get(i)
		if buff and buff.valid and buff.name == 'khazixrstealth' then
			return true
		end
	end
end

local function KillSteal()
	for i = 0, objManager.enemies_n - 1 do

		if enemy and common.IsValidTarget(enemy) and menu.auto.uks:get() and not HasSionBuff(enemy) then
			local hp = enemy.health;
			local d = enemy.pos:dist(player.pos)
			local q = player:spellSlot(0).state == 0
 			local e = player:spellSlot(2).state == 0
 			local w = player:spellSlot(1).state == 0
			if hp == 0 then return end
			if player:spellSlot(0).level > 0 and qDmg(enemy) + PlayerAD() > hp and d < 325 then
				CastQ(enemy);
			elseif qDmg(enemy) + PlayerAD() > hp and menu.auto.ukse:get() and d < 1000 and d > 600 then
				CastGPE(enemy)
				CastQ(enemy)
			elseif player:spellSlot(1).level > 0 and wDmg(enemy) > hp and enemy.pos:dist(player.pos) < 960 then
				CastW(enemy);
			elseif player:spellSlot(1).level > 0 and wDmg(enemy) + qDmg(enemy) > hp and d < 500 then
				CastQ(enemy)
				CastW(enemy)
			elseif e and qDmg(enemy) + eDmg(enemy) + PlayerAD() > hp and menu.auto.ukse:get() and common.GetPercentHealth(player) >= menu.auto.mhp:get() and d < 990 then
				CastE(enemy)
				CastQ(enemy)
			elseif player:spellSlot(1).level > 0 and e and qDmg(enemy) + eDmg(enemy) + wDmg(enemy) + PlayerAD() > hp and menu.auto.ukse:get() and common.GetPercentHealth(player) >= menu.auto.mhp:get() and d < 990 then
				CastE(enemy)
				CastQ(enemy)
				if enemy.pos:dist(player.pos) <= 700 then
					CastW(enemy)
				end
			end
		end
	end
end

local function Combo()
	local target = get_target(select_etarget)
	if target and common.IsValidTarget(target) and not HasSionBuff(target) then
		local q = player:spellSlot(0).state == 0
 		local e = player:spellSlot(2).state == 0
		local w = player:spellSlot(1).state == 0
		if menu.combo.e:get() then
			if menu.combo.ed:get() == 1 then
				if e and target.pos:dist(player.pos) <= 700 then
					common.DelayAction(function()player:castSpell("pos", 2, (game.mousePos)) end, 0.2)
				end
			elseif menu.combo.ed:get() == 2 then
				CastE(target)
			end
		end
		if menu.combo.q:get() and not HasKhazixBuff(player) then
			local target = get_target(select_target)
			if target and common.IsValidTarget(target) and not HasSionBuff(target) then
				CastQ(target)
			end
		end
		if menu.combo.w:get() and target.pos:dist(player.pos) >= 380 and player:spellSlot(2).state == 32 and not HasKhazixBuff(player) then
			CastW(target)
		elseif menu.combo.w:get() and player:spellSlot(2).state == 32 and Isolated == true or player:spellSlot(0).state ~= 0 and not HasKhazixBuff(player) then
			CastW(target)
		end
		if menu.combo.r:get() and player:spellSlot(3).state == 0 then
			if menu.combo.rm:get() == 2 then
				if #common.GetEnemyHeroesInRange(500) > 2 then
	                if target.pos:dist(player.pos) <= 600 then
	                    if player:spellSlot(3).state == 0 then player:castSpell("self", 3) end
	                end
	            end
	        elseif menu.combo.rm:get() == 1 then
	            if target.pos:dist(player.pos) <= 500 then 
	                if player:spellSlot(3).state == 0 then player:castSpell("self", 3) end
	            end
	        end
		end
	end
end

local function Harass()
	local target = get_target(select_target)
	if target and common.IsValidTarget(target) then
		if menu.keys.harass:get() then
			if player.par / player.maxPar * 100 >= menu.harass.Mana:get() then
				if menu.harass.q:get() then
					local target = get_target(select_etarget)
					if target and common.IsValidTarget(target) and not HasSionBuff(target) then
						CastQ(target)
					end
				end
				if menu.harass.w:get() then
					CastW(target)
				end
			end
		end
	end
end

local function Clear()
	local target = { obj = nil, health = 0, mode = "jungleclear" }
	local aaRange = player.attackRange + player.boundingRadius + 200
	for i = 0, minionmanager.size[TEAM_NEUTRAL] - 1 do
		local obj = minionmanager[TEAM_NEUTRAL][i]
		if player.pos:dist(obj.pos) <= aaRange and obj.maxHealth > target.health then
			target.obj = obj
			target.health = obj.maxHealth
		end
	end
	if target.obj then
		if target.mode == "jungleclear" then
			if menu.jg.q:get() and player:spellSlot(0).state == 0 then
				player:castSpell("obj", 0, target.obj)
			end
			if menu.jg.w:get() and player:spellSlot(1).state == 0 then
				CastW(target.obj)
			end
		end
	end
end


local function Run()
	if menu.keys.run:get() then
		player:move((game.mousePos))
		if player:spellSlot(2).state == 0 and not navmesh.isWall(game.mousePos) then
			player:castSpell("pos", 2, (game.mousePos))
		end
	end
end

local function EvolutionCheck()
    if player:spellSlot(0).name == "KhazixQ" then
        QRange = 325
    elseif player:spellSlot(0).name == "KhazixQLong" then
    	QRange = 375
    end 
    if player:spellSlot(2).name == "KhazixE" then
        ERange = 700
    elseif player:spellSlot(2).name == "KhazixELong" then
    	ERange = 900
    end 
end

local function oncreateobj(obj)
    if obj and obj.name and obj.type then
        --if obj and obj.name and obj.name:lower():find("indicator") then print("Created "..obj.name) end
        if obj.name:find("SingleEnemy_Indicator") then
            Isolated = true
        end
    end
end

local function ondeleteobj(obj)
    if obj and obj.name and obj.type then
    	if obj.name:find("SingleEnemy_Indicator") then
            Isolated = false
        end
    end
end


local function CountEnemyHeroInRange(range)
	local range, count = range*range, 0 
	for i = 0, objManager.enemies_n - 1 do
		if player.pos:distSqr(objManager.enemies[i].pos) < range then 
	 		count = count + 1 
	 	end 
	end 
	return count 
end

local function OnTick()
	if orb.combat.is_active() then Combo() end
	if orb.menu.hybrid.key:get() then Harass() end
	if menu.auto.uks:get() then KillSteal() end
	if menu.keys.run:get() then Run() end
	if menu.draws.q:get() or menu.draws.e:get() then EvolutionCheck() end
	if orb.menu.lane_clear.key:get() then
		Clear()
	end
end

local function OnDraw()
	if menu.draws.q:get() and player:spellSlot(0).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, QRange, 2, graphics.argb(255, 168, 0, 157), 50)
	end
	if menu.draws.e:get() and player:spellSlot(2).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, ERange, 2, graphics.argb(255, 0, 21, 255), 50)
	end
end

orb.combat.register_f_pre_tick(OnTick)
cb.add(cb.draw, OnDraw)
cb.add(cb.create_minion, oncreateobj)
cb.add(cb.create_particle, oncreateobj)
cb.add(cb.create_missile, oncreateobj)
cb.add(cb.delete_particle, ondeleteobj)
cb.add(cb.delete_missile, ondeleteobj)
cb.add(cb.delete_minion, ondeleteobj)
orb.combat.register_f_after_attack(
	function()
		if orb.combat.is_active() then
			if orb.combat.target and HasKhazixBuff(player) then
				if menu.combo.q:get() and orb.combat.target and common.IsValidTarget(orb.combat.target) and player.pos:dist(orb.combat.target.pos) < common.GetAARange(orb.combat.target) then
					if player:spellSlot(0).state == 0 then
						player:castSpell("obj", 0, orb.combat.target)
						orb.core.set_server_pause()
						orb.combat.set_invoke_after_attack(false)
						player:attack(orb.combat.target)
						orb.core.set_server_pause()
						orb.combat.set_invoke_after_attack(false)
						return "on_after_attack_hydra"
					end
				end
			end
		end
	end
)

print("Khantum Phyzix v"..version..": Loaded")