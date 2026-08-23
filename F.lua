-- Configuração de Hardware
local mon = peripheral.find("monitor")
if not mon then
    print("Erro: Conecte um monitor avançado 3x3!")
    return
end

-- Ativando o CC: Graphics
term.redirect(mon)
if not term.setGraphicsMode then
    term.restore()
    print("Erro: CC: Graphics não detectado.")
    return
end

-- Modo 1: Desenho de pixels com a paleta de 16 cores
term.setGraphicsMode(1)
local w, h = term.getSize()

-- Variáveis de Física e Estado
local playerY = h / 2
local velocity = 0
local gravity = 0.8
local jumpForce = -6
local obstacles = {}
local score = 0
local isAlive = true
local frames = 0

-- Função utilitária para desenhar blocos de pixels
local function drawRect(x, y, width, height, color)
    for i = 0, width - 1 do
        for j = 0, height - 1 do
            if (x+i) >= 1 and (x+i) <= w and (y+j) >= 1 and (y+j) <= h then
                term.setPixel(math.floor(x + i), math.floor(y + j), color)
            end
        end
    end
end

-- Motor Gráfico e Lógica (Roda no Monitor)
local function gameLoop()
    while isAlive do
        frames = frames + 1
        velocity = velocity + gravity
        playerY = playerY + velocity

        -- Gerador de Pilares
        if frames % 40 == 0 then
            local gapCenter = math.random(30, h - 30)
            table.insert(obstacles, {x = w, gapTop = gapCenter - 20, gapBottom = gapCenter + 20})
        end

        term.setBackgroundColor(colors.black)
        term.clear()

        -- Fundo Parallax (Estrelas em movimento)
        for i = 1, 20 do
            local starX = ((frames * -0.5 + i * 15) % w) + 1
            local starY = (i * 37) % h + 1
            term.setPixel(math.floor(starX), math.floor(starY), colors.lightGray)
        end

        -- Renderização dos Obstáculos
        for i = #obstacles, 1, -1 do
            local obs = obstacles[i]
            obs.x = obs.x - 4
            
            -- Pilares Cyan Neon
            drawRect(obs.x, 1, 10, obs.gapTop, colors.cyan)
            drawRect(obs.x, obs.gapBottom, 10, h - obs.gapBottom, colors.cyan)

            -- Sistema de Colisão Simples
            local px = w / 4
            if px + 6 >= obs.x and px <= obs.x + 10 then
                if playerY <= obs.gapTop or playerY + 6 >= obs.gapBottom then
                    isAlive = false
                end
            end

            -- Contagem de Pontos
            if obs.x < -10 then
                table.remove(obstacles, i)
                score = score + 1
            end
        end

        -- Colisão com teto e chão
        if playerY > h or playerY < 0 then isAlive = false end

        -- Efeito Neon do Jogador (Borda verde, centro branco)
        drawRect(w/4, playerY, 6, 6, colors.lime)
        drawRect((w/4)+1, playerY+1, 4, 4, colors.white)

        sleep(0.05) -- Trava o jogo em 20 FPS para evitar lag no servidor
    end
    
    -- Finalização
    term.setBackgroundColor(colors.black)
    term.clear()
    term.restore()
    mon.setGraphicsMode(0) -- Desliga os gráficos
    print("Fim de Jogo! Você passou por " .. score .. " obstaculos.")
end

-- Sistema de Controles (Roda no Terminal)
local function inputLoop()
    term.restore()
    print("O jogo esta rodando no monitor!")
    print("--------------------------------")
    print(">>> Pressione ESPACO para pular <<<")
    
    while isAlive do
        local event, key = os.pullEvent("key")
        if key == keys.space then
            velocity = jumpForce
        end
    end
end

-- Executa o gráfico e os controles simultaneamente
parallel.waitForAny(gameLoop, inputLoop)
