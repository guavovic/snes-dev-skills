-- Teste da ROM teste-sram.asm no MesenCE (modo --testRunner).
-- Lê o resultado em $7E0080 e, para cada sonda, pergunta ao próprio Mesen
-- (emu.convertAddress) em que byte da SRAM ele liga aquele endereço; monta as
-- classes esperadas (primeira sonda que cai no mesmo byte) e compara com as
-- da ROM. Depois dá reset e confere se o contador de boot somou 1.
-- Rodar: Mesen.exe --testRunner teste-sram.sfc teste-sram.lua
-- Sai com 0 se tudo bateu e 1 se não.

local function r8(a) return emu.read(a, emu.memType.snesWorkRam, false) end
local function r16(a) return r8(a) + r8(a + 1) * 256 end

local falhou = false
local function confere(ok, msg)
  print((ok and "ok    " or "FALHOU") .. "  " .. msg)
  if not ok then falhou = true end
end

local sondas = {}
for b = 0, 13 do
  sondas[#sondas + 1] = (0x70 + b) * 0x10000
  sondas[#sondas + 1] = (0x70 + b) * 0x10000 + 0x8000
end
sondas[#sondas + 1] = 0xF00000
sondas[#sondas + 1] = 0xFF0000

local function classe_txt(c) return c == 0xFF and "--" or string.format("%02X", c) end

local quadros, fase, cont1 = 0, 1, nil
emu.addEventCallback(function()
  quadros = quadros + 1
  if r8(0x8F) ~= 0xA5 then
    if quadros > 240 then print("a ROM não terminou"); emu.stop(1) end
    return
  end

  if fase == 2 then
    local cont2 = r16(0x85)
    if r8(0x88) == 0 then
      confere(cont2 == 1, string.format("sem SRAM o contador não guarda: %04X depois do reset", cont2))
    else
      confere(cont2 == cont1 + 1, string.format("contador depois do reset: %04X (antes %04X)", cont2, cont1))
    end
    emu.stop(falhou and 1 or 0)
    return
  end

  print(string.format("D7 %02X  D8 %02X  SRAM vista %d KB, %d KB no banco $70, sondas novas %d",
    r8(0x80), r8(0x81), r16(0x83), r8(0x82), r8(0x88)))
  for g = 0, 6 do
    local t = {}
    for k = 0, 3 do t[#t + 1] = classe_txt(r8(0x220 + g * 4 + k)) end
    print(string.format("%02X %s", 0x70 + g * 2, table.concat(t, " ")))
  end
  print(string.format("F0 %s   FF %s", classe_txt(r8(0x220 + 28)), classe_txt(r8(0x220 + 29))))
  cont1 = r16(0x85)
  print(string.format("contador %04X (veio da SRAM: %s)", cont1, r8(0x87) == 1 and "sim" or "não"))

  local fisico, divergentes, novas = {}, {}, 0
  for i, a in ipairs(sondas) do
    local info = emu.convertAddress(a, emu.memType.snesMemory, emu.cpuType.snes)
    if info ~= nil and info.memType == emu.memType.snesSaveRam then fisico[i] = info.address end
  end
  for i = 1, #sondas do
    local esperado = 0xFF
    if fisico[i] ~= nil then
      for j = 1, i do
        if fisico[j] == fisico[i] then esperado = j - 1; break end
      end
    end
    if i <= 28 and esperado == i - 1 then novas = novas + 1 end
    if r8(0x220 + i - 1) ~= esperado then
      divergentes[#divergentes + 1] = string.format("%06X (ROM %s, Mesen %s)", sondas[i],
        classe_txt(r8(0x220 + i - 1)), classe_txt(esperado))
    end
  end
  confere(#divergentes == 0, "classes da ROM iguais às do mapa do Mesen" ..
    (#divergentes == 0 and "" or ": " .. table.concat(divergentes, ", ")))
  confere(novas == r8(0x88), string.format("sondas novas: ROM %d, Mesen %d", r8(0x88), novas))

  emu.write(0x8F, 0, emu.memType.snesWorkRam)
  quadros = 0
  fase = 2
  emu.reset()
end, emu.eventType.endFrame)
