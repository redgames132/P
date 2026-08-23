local mon = peripheral.find("monitor")
local speaker = peripheral.find("speaker")

if not mon then print("Erro: Conecte um monitor!") return end
if not speaker then print("Aviso: Speaker nao encontrado para os sons!") end

-- Configuração da Tela
mon.setTextScale(0.5)
term.redirect(mon)
local w, h = term.getSize()

-- Variáveis do Jogo
local player = { hp = 50, maxHp = 50, mp = 20, maxMp = 20 }
local boss = { name = "Mecha-Olho", hp = 150, maxHp = 150 }
local gameState = "PLAYER_TURN"
local message = "O Mecha-Olho bloqueia o caminho!"

-- Paleta de cores para o Sprite do Chefe (Pixels grandes)
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

-- Função para tocar som
local function playSound(sound, pitch)
    if speaker then
        -- Toca sons nativos do Minecraft
        speaker.playSound(sound, 1.0, pitch or 1.0)
    end
end

-- Desenha o Sprite do Chefe na tela
local function drawBoss(x, y)
    for row = 1, #boss_sprite do
        local line = boss_sprite[row]
        term.setCursorPos(x, y + row - 1)
        for col = 1, #line do
            local colorChar = line:sub(col, col)
            if colorChar ~= "0" then
                local color = math.pow(2, tonumber(colorChar, 16))
                term.setBackgroundColor(color)
                term.write(" ")
            else
                term.setBackgroundColor(colors.black)
                term.write(" ")
            end
        end
    end
    term.setBackgroundColor(colors.black)
end

-- Desenha a Interface (Barras de Vida e Botões)
local function drawUI()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    -- Chefe
    term.setTextColor(colors.red)
    term.setCursorPos(w/2 - string.len(boss.name)/2, 2)
    print(boss.name)
    
    -- Barra do chefe
    term.setCursorPos(w/2 - 10, 3)
    term.setBackgroundColor(colors.gray)
    term.write(string.rep(" ", 20))
    term.setCursorPos(w/2 - 10, 3)
    term.setBackgroundColor(colors.red)
    term.write(string.rep(" ", math.floor((boss.hp / boss.maxHp) * 20)))
    term.setBackgroundColor(colors.black)

    -- Desenha o sprite
    drawBoss(w/2 - 6, 6)

    -- Caixa de Mensagem
    term.setCursorPos(2, h - 8)
    term.setTextColor(colors.white)
    print(message)

    -- Status do Jogador
    term.setCursorPos(2, h - 5)
    term.setTextColor(colors.lime)
    print("HP: " .. player.hp .. "/" .. player.maxHp)
    term.setCursorPos(2, h - 4)
    term.setTextColor(colors.lightBlue)
    print("MP: " .. player.mp .. "/" .. player.maxMp)

    -- Botões de Ação
    if gameState == "PLAYER_TURN" then
        term.setBackgroundColor(colors.orange)
        term.setTextColor(colors.black)
        term.setCursorPos(w - 15, h - 5)
        term.write(" [ ATACAR ] ")
        
        term.setBackgroundColor(colors.blue)
        term.setTextColor(colors.white)
        term.setCursorPos(w - 15, h - 3)
        term.write(" [ MAGIA  ] ")
    end
    
    term.setBackgroundColor(colors.black)
end

-- Lógica de Batalha
local function playerAttack()
    gameState = "ANIMATION"
    playSound("entity.player.attack.crit", 1.0)
    local dmg = math.random(15, 25)
    boss.hp = math.max(0, boss.hp - dmg)
    message = "Voce atacou! Causou " .. dmg .. " de dano."
    drawUI()
    sleep(2)
end

local function playerMagic()
    if player.mp >= 10 then
        gameState = "ANIMATION"
        player.mp = player.mp - 10
        playSound("block.amethyst_block.chime", 1.5)
        local heal = math.random(15, 25)
        player.hp = math.min(player.maxHp, player.hp + heal)
        message = "Voce usou Cura! Recuperou " .. heal .. " HP."
        drawUI()
        sleep(2)
    else
        message = "MP Insuficiente!"
        drawUI()
        sleep(1)
        return false
    end
    return true
end

local function bossTurn()
    if boss.hp <= 0 then return end
    gameState = "BOSS_TURN"
    message = "Mecha-Olho esta preparando um laser..."
    drawUI()
    playSound("entity.ender_dragon.growl", 2.0)
    sleep(2)
    
    playSound("entity.generic.explode", 1.5)
    local dmg = math.random(10, 20)
    player.hp = math.max(0, player.hp - dmg)
    message = "Laser atingiu voce! -" .. dmg .. " HP."
    drawUI()
    sleep(2)
    
    if player.hp > 0 then
        gameState = "PLAYER_TURN"
        message = "Seu turno! O que voce vai fazer?"
        drawUI()
    end
end

-- Loop Principal
drawUI()
playSound("entity.wither.spawn", 0.5) -- Som de entrada do chefe

while player.hp > 0 and boss.hp > 0 do
    if gameState == "PLAYER_TURN" then
        -- Espera o jogador tocar no monitor
        local event, side, x, y = os.pullEvent("monitor_touch")
        
        -- Verifica colisão com o botão ATACAR
        if x >= w - 15 and x <= w - 3 and y == h - 5 then
            playerAttack()
            bossTurn()
        -- Verifica colisão com o botão MAGIA
        elseif x >= w - 15 and x <= w - 3 and y == h - 3 then
            if playerMagic() then
                bossTurn()
            end
        end
    end
end

-- Fim de jogo
term.clear()
term.setCursorPos(w/2 - 5, h/2)
if player.hp <= 0 then
    term.setTextColor(colors.red)
    print("GAME OVER")
    playSound("entity.player.death", 1.0)
else
    term.setTextColor(colors.yellow)
    print("VOCE VENCEU!")
    playSound("ui.toast.challenge_complete", 1.0)
end
sleep(3)
term.restore()
