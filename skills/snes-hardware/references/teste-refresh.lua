-- Teste da ROM teste-refresh.asm no MesenCE (modo --testRunner).
-- Lê os resultados em $7E0080, refaz a conta a partir das amostras cruas
-- e compara com a posição do refresh que o próprio Mesen usou em cada linha.
-- Rodar: Mesen.exe --testRunner teste-refresh.sfc teste-refresh.lua
-- Sai com 0 se tudo bateu e 1 se não.

local AMOSTRAS = 1800
local R_por_linha = {}
local chave_vista = false

local function r8(a) return emu.read(a, emu.memType.snesWorkRam, false) end

emu.addMemoryCallback(function()
  if r8(0x8F) == 0xA5 then return end
  local s = emu.getState()
  local r = s["memoryManager.dramRefreshPosition"]
  if r ~= nil then chave_vista = true end
  R_por_linha[s["ppu.scanline"]] = r
end, emu.callbackType.read, 0x2137, 0x2137)

local function amostra(k)
  local lo = r8(0x1FFF - 2 * k)
  local hi = r8(0x1FFE - 2 * k) & 1
  return hi * 256 + lo
end

local function refaz()
  local g, voltas = 0, 0
  local cnt, L, U = {0, 0}, {0, 0}, {0xFFFF, 0xFFFF}
  local ant = amostra(0)
  for k = 1, AMOSTRAS - 1 do
    local h = amostra(k)
    local d = h - ant
    if d < 0 then
      voltas = voltas + 1
      g = 1 - g
    elseif d >= 42 then
      cnt[g + 1] = cnt[g + 1] + 1
      if ant > L[g + 1] then L[g + 1] = ant end
      if h - 10 < U[g + 1] then U[g + 1] = h - 10 end
    end
    ant = h
  end
  return voltas + 1, cnt, L, U
end

local falhou = false
local function confere(ok, msg)
  print((ok and "ok    " or "FALHOU") .. "  " .. msg)
  if not ok then falhou = true end
end

local quadros, terminou = 0, false
emu.addEventCallback(function()
  if terminou then return end
  quadros = quadros + 1
  if r8(0x8F) ~= 0xA5 then
    if quadros > 120 then print("a ROM não terminou"); emu.stop(1) end
    return
  end
  terminou = true
  local res = {}
  for i = 0, 15 do res[i] = r8(0x80 + i) end
  print(string.format("versões: CPU %X  PPU1 %X  PPU2 %X", res[0], res[1], res[2]))
  print(string.format("linhas %d (%02X)", res[3], res[3]))
  print(string.format("V par:   %d linhas  L %d (%02X)  U %d (%02X)", res[4], res[5], res[5], res[6], res[6]))
  print(string.format("V ímpar: %d linhas  L %d (%02X)  U %d (%02X)", res[7], res[8], res[8], res[9], res[9]))
  print(string.format("diferença normal %d a %d, com refresh %d a %d", res[10], res[11], res[12], res[13]))

  local linhas, cnt, L, U = refaz()
  confere(linhas == res[3] and cnt[1] == res[4] and cnt[2] == res[7]
    and (L[1] & 0xFF) == res[5] and (U[1] & 0xFF) == res[6]
    and (L[2] & 0xFF) == res[8] and (U[2] & 0xFF) == res[9],
    "conta da ROM igual à conta do Lua sobre as amostras cruas")
  local saltos = cnt[1] + cnt[2]
  confere(saltos == linhas or saltos == linhas - 1, "um salto de refresh por linha (a última pode acabar antes do refresh)")

  confere(chave_vista, "chave memoryManager.dramRefreshPosition existe no getState")
  if chave_vista then
    for grupo = 0, 1 do
      local vistos, Lp, Up = {}, 0, 0xFFFF
      for v = 20 + grupo, 20 + linhas - 1, 2 do
        local r = R_por_linha[v] or 0
        vistos[#vistos + 1] = r
        local lp, up = (r - 2) // 4, r // 4
        if lp > Lp then Lp = lp end
        if up < Up then Up = up end
      end
      local unicos = {}
      for _, r in ipairs(vistos) do unicos[r] = true end
      local lista = {}
      for r in pairs(unicos) do lista[#lista + 1] = r end
      table.sort(lista)
      print(string.format("grupo %s: refresh do Mesen em master clock %s; previsto L %d, U %d",
        grupo == 0 and "par" or "ímpar", table.concat(lista, ","), Lp, Up))
      confere(Lp == res[5 + 3 * grupo] and Up == res[6 + 3 * grupo], "L e U da ROM batem com o previsto pelo Mesen")
    end
  end
  emu.stop(falhou and 1 or 0)
end, emu.eventType.endFrame)
