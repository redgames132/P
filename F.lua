local mon = peripheral.find("monitor")
local speaker = peripheral.find("speaker")

if not mon then
    print("Erro: Monitor nao encontrado!")
    return
end

-- Envolvemos o jogo inteiro em uma funcao para capturar os erros
local function startRPG()
    mon.setTextScale(1)
    local w, h = mon.getSize()
    
    local player = { hp = 50, maxHp = 50, mp = 20 }
    local boss = { hp = 150, maxHp = 150 }
    local state = "TURNO"
    local msg = "O Mecha-Olho bloqueia o caminho!"
    
    -- Usando o formato nativo do CC: f=preto, 8=cinza claro, 7=cinza, e=vermelho, 4=amarelo
    local boss_sprite = {
        "ffff8888ffff",
        "ff88777788ff",
        "f877eeee778f",
        "877ee44ee778",
        "87ee4444ee78",
        "87ee4444ee78",
        "877ee44ee778",
        "f877eeee778f",
        "ff88777788ff",
        "ffff8888ffff"
    }
    
    local function draw()
        mon.setBackgroundColor(colors.black)
        mon.clear()
        
        -- Titulo
        mon.setCursorPos(math.floor(w/2 - 4), 2)
        mon.setTextColor(colors.red)
        mon.write("Mecha-Olho")
        
        -- Sprite desenhado de forma 100% segura com blit
        local x = math.floor(w/2 - 6)
        local y = 4
        for i = 1, #boss_sprite do
            mon.setCursorPos(x, y + i - 1)
            mon.blit(string.rep(" ", 12), string.rep("f", 12), boss_sprite[i])
        end
        
        -- Textos de Status
        mon.setCursorPos(2, h - 5)
        mon.setTextColor(colors.white)
        mon.setBackgroundColor(colors.black)
        mon.write(msg)
        
        mon.setCursorPos(2, h - 2)
        mon.setTextColor(colors.lime)
        mon.write("HP: " .. player.hp .. "/" .. player.maxHp)
        
        mon.setCursorPos(2, h - 1)
        mon.setTextColor(colors.lightBlue)
        mon.write("MP: " .. player.mp)
        
        -- Botoes
        if state == "TURNO" then
            mon.setCursorPos(w - 12, h - 3)
            -- Fundo laranja (1), texto preto (f)
            mon.blit("[ ATACAR ]", "ffffffffff", "1111111111") 
            
            mon.setCursorPos(w - 12, h - 1)
            -- Fundo azul (b), texto branco (0)
            mon.blit("[ CURAR  ]", "0000000000", "bbbbbbbbbb") 
        end
    end
    
    -- Inicia o desenho
    draw()
    print("O jogo esta rodando! Clique na tela do monitor.")
    
    while player.hp > 0 and boss.hp > 0 do
        if state == "TURNO" then
            local event, side, mx, my = os.pullEvent("monitor_touch")
            
            -- Lógica de clique nos botões
            if mx >= w - 12 and mx <= w - 2 then
                if my == h - 3 then
                    msg = "Voce atacou! -25 HP"
                    boss.hp = boss.hp - 25
                    state = "BOSS"
                elseif my == h - 1 and player.mp >= 10 then
                    msg = "Cura usada! +20 HP"
                    player.hp = math.min(player.maxHp, player.hp + 20)
                    player.mp = player.mp - 10
                    state = "BOSS"
                end
            end
            
            -- Turno do Chefe
            if state == "BOSS" then
                draw()
                if speaker then pcall(function() speaker.playSound("entity.player.attack.crit", 1, 1) end) end
                sleep(1.5)
                
                if boss.hp > 0 then
                    msg = "Laser inimigo! -15 HP"
                    player.hp = player.hp - 15
                    if speaker then pcall(function() speaker.playSound("entity.generic.explode", 1, 1) end) end
                    draw()
                    sleep(1.5)
                    
                    state = "TURNO"
                    msg = "Seu turno! Escolha uma acao."
                    draw()
                end
            end
        else
            sleep(0.1) -- Evita lag
        end
    end
    
    -- Fim de Jogo
    mon.setBackgroundColor(colors.black)
    mon.clear()
    mon.setCursorPos(math.floor(w/2 - 4), math.floor(h/2))
    if player.hp <= 0 then
        mon.setTextColor(colors.red)
        mon.write("GAME OVER")
    else
        mon.setTextColor(colors.yellow)
        mon.write("VITORIA!")
    end
end

-- Aqui é onde o erro é interceptado e exibido
local ok, err = pcall(startRPG)
if not ok then
    print("O programa falhou. Aqui esta o erro:")
    print(err)
end
