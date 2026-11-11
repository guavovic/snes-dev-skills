-- Teste da ROM teste-exlorom.asm no MesenCE (modo --testRunner).
-- Lê o resultado em $7E0080 e, para cada banco, pergunta ao próprio Mesen
-- (emu.convertAddress) que offset da ROM ele liga em $bb:FF00; compara o
-- bloco desse offset com o que a ROM leu e com o mapa ExLoROM esperado.
-- Rodar: Mesen.exe --testRunner teste-exlorom.sfc teste-exlorom.lua
-- Sai com 0 se tudo bateu e 1 se não.

local function r8(a) return emu.read(a, emu.memType.snesWorkRam, false) end

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

  local mb = r8(0x83)
  local blocos = mb * 32
  local nomes = { [0] = "--", "LOROM", "EXLOROM" }
  print(string.format("tamanho %d MB, EX %d, LO %d, veredito %s", mb, r8(0x80), r8(0x81), nomes[r8(0x82)] or "?"))
  for g = 0, 7 do
    local function grupo(i)
      local primeiro = r8(0xA0 + i) == 1 and string.format("%02X", r8(0x90 + i)) or "--"
      return string.format("%X %s %X", i, primeiro, r8(0xB0 + i))
    end
    print(grupo(g) .. "   " .. grupo(g + 8))
  end

  local ex, lo, iguais, sem_rom = 0, 0, 0, 0
  local divergentes = {}
  for b = 0, 255 do
    if b ~= 0x7E and b ~= 0x7F then
      local ok_rom = r8(0x300 + b) == 1
      local lido = r8(0x200 + b)
      local info = emu.convertAddress(b * 0x10000 + 0xFF00, emu.memType.snesMemory, emu.cpuType.snes)
      local bloco_mesen = nil
      if info ~= nil and info.memType == emu.memType.snesPrgRom then
        bloco_mesen = info.address // 0x8000
        if info.address % 0x8000 ~= 0x7F00 then bloco_mesen = -1 end
      else
        sem_rom = sem_rom + 1
      end
      if bloco_mesen ~= nil and bloco_mesen >= 0 and bloco_mesen < blocos then
        if ok_rom and lido == bloco_mesen then iguais = iguais + 1
        else divergentes[#divergentes + 1] = string.format("%02X", b) end
      elseif ok_rom then
        divergentes[#divergentes + 1] = string.format("%02X", b)
      end
      local esperado_ex = b ~ 0x80
      if esperado_ex < blocos and not (ok_rom and lido == esperado_ex) then ex = ex + 1 end
      if not (ok_rom and lido == (b & 0x7F)) then lo = lo + 1 end
    end
  end
  confere(#divergentes == 0, string.format(
    "o que a ROM leu bate com o mapa do Mesen em todos os bancos (%d com marca; divergentes: %s)",
    iguais, #divergentes == 0 and "nenhum" or table.concat(divergentes, " ")))
  confere(sem_rom == 0, "todo $bb:FF00 (menos $7E e $7F) cai na ROM no Mesen")
  confere(ex == r8(0x80) and lo == r8(0x81), "contas EX e LO da ROM iguais às do Lua")
  confere(r8(0x80) == 0 and r8(0x82) == 2, "Mesen mapeia como ExLoROM (EX = 0, veredito EXLOROM)")
  emu.stop(falhou and 1 or 0)
end, emu.eventType.endFrame)
