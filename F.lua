local mon = peripheral.find("monitor")
local speaker = peripheral.find("speaker")

if not mon then
    print("Erro: Monitor nao encontrado!")
    return
end

-- Garante que os comandos vao direto para o monitor com escala padrao
mon.setTextScale(1)
local w, h = mon.getSize()

local player = { hp = 50, maxHp = 50, mp = 20, maxMp = 20 }
local boss = { name = "Mecha-Olho", hp = 150, maxHp = 150 }
local gameState = "PLAYER_TURN"
local message = "O Mecha-Olho bloqueia o caminho!"

local boss_sprite = {
    "000088880000",
    "008877778800",
    "087711117780",
    "877114411778",
    "871144441178",
    "871144441178",
    "877114411778",
    "087711117780",
    "008877778800",
    "000088880000"
}

local function playSound(sound, pitch)
    if speaker and speaker.playSound then
        -- pcall previne que um som invalido trave o jogo
        pcall(function() speaker.playSound(sound, 1.0, pitch or 1.0) end)
    end
end

local function drawBoss(x, y)
    for row = 1, #boss_sprite do
        local line = boss_sprite[row]
        mon.setCursorPos(math.floor(x), math.floor(y + row - 1))
        for col = 1, #line do
            local colorChar = line:sub(col, col)
            if colorChar ~= "0" then
                -- Usando ^ no lugar de math.pow para compatibilidade total
                local color = 2 ^ tonumber(colorChar, 16)
                mon.setBackgroundColor(color)
                mon.write(" ")
            else
                mon.setBackgroundColor(colors.black)
                mon.write(" ")
            end
        end
    end
    mon.setBackgroundColor(colors.black)
end

local function drawUI()
    mon.setBackgroundColor(colors.black)
    mon.clear()
    
    mon.setTextColor(colors.red)
    mon.setCursorPos(math.floor(w/2 - string.len(boss.name)/2), 2)
    mon.write(boss.name)
    
    -- Barra de Vida do Chefe
    local barX = math.floor(w/2 - 10)
    mon.setCursorPos(barX, 3)
    mon.setBackgroundColor(colors.gray)
    mon.write(string.rep(" ", 20))
    mon.setCursorPos(barX, 3)
    mon.setBackgroundColor(colors.red)
    local hpLength = math.floor((boss.hp / boss.maxHp) * 20)
    if hpLength > 0 then mon.write(string.rep(" ", hpLength)) end
    mon.setBackgroundColor(colors.black)

    drawBoss(w/2 - 6, 5)

    -- Caixa de texto
    mon.setCursorPos(2, h - 5)
    mon.setTextColor(colors.white)
    mon.write(message)

    -- Status do Jogador
    mon.setCursorPos(2, h - 2)
    mon.setTextColor(colors.lime)
    mon.write("HP: " .. player.hp .. "/" .. player.maxHp)
    mon.setCursorPos(2, h - 1)
    mon.setTextColor(colors.lightBlue)
    mon.write("MP: " .. player.mp .. "/" .. player.maxMp)

    -- Botoes (Apenas no turno do jogador)
    if gameState == "PLAYER_TURN" then
        mon.setBackgroundColor(colors.orange)
        mon.setTextColor(colors.black)
        mon.setCursorPos(w - 13, h - 3)
        mon.write("[ ATACAR ]")
        
        mon.setBackgroundColor(colors.blue)
        mon.setTextColor(colors.white)
        mon.setCursorPos(w - 13, h - 1)
        mon.write("[ MAGIA  ]")
    end
    
    mon.setBackgroundColor(colors.black)
end

local function playerAttack()
    gameState = "ANIMATION"
    playSound("entity.player.attack.crit", 1.0)
    local dmg = math.random(15, 25)
    boss.hp = math.max(0, boss.hp - dmg)
    message = "Voce atacou! -" .. dmg .. " HP."
    drawUI()
    sleep(1.5)
end

local function playerMagic()
    if player.mp >= 10 then
        gameState = "ANIMATION"
        player.mp = player.mp - 10
        playSound("block.amethyst_block.chime", 1.5)
        local heal = math.random(15, 25)
        player.hp = math.min(player.maxHp, player.hp + heal)
        message = "Cura usada! +" .. heal .. " HP."
        drawUI()
        sleep(1.5)
        return true
    else
        message = "MP Insuficiente!"
        drawUI()
        sleep(1)
        return false
    end
end

local function bossTurn()
    if boss.hp <= 0 then return end
    gameState = "BOSS_TURN"
    message = "Mecha-Olho carrega um laser..."
    drawUI()
    playSound("entity.ender_dragon.growl", 2.0)
    sleep(1.5)
    
    playSound("entity.generic.explode", 1.5)
    local dmg = math.random(10, 20)
    player.hp = math.max(0, player.hp - dmg)
    message = "O laser te atingiu! -" .. dmg .. " HP."
    drawUI()
    sleep(1.5)
    
    if player.hp > 0 then
        gameState = "PLAYER_TURN"
        message = "Seu turno! Escolha uma acao."
        drawUI()
    end
end

-- Inicializacao
print("O jogo esta rodando! Clique nos botoes do monitor.")
drawUI()
playSound("entity.wither.spawn", 0.5)

-- Loop Principal de Batalha
while player.hp > 0 and boss.hp > 0 do
    if gameState == "PLAYER_TURN" then
        local event, side, x, y = os.pullEvent("monitor_touch")
        
        -- Verifica se o toque foi na area dos botoes (Direita da tela)
        if x >= w - 13 and x <= w - 3 then
            if y == h - 3 then
                playerAttack()
                bossTurn()
            elseif y == h - 1 then
                if playerMagic() then
                    bossTurn()
                end
            end
        end
    else
        sleep(0.1)
    end
end

-- Tela Final
mon.clear()
mon.setCursorPos(math.floor(w/2 - 4), math.floor(h/2))
if player.hp <= 0 then
    mon.setTextColor(colors.red)
    mon.write("GAME OVER")
    playSound("entity.player.death", 1.0)
else
    mon.setTextColor(colors.yellow)
    mon.write("VOCE VENCEU!")
    playSound("ui.toast.challenge_complete", 1.0)
end
print("Batalha encerrada.")
