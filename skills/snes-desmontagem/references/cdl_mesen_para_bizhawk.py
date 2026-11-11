#!/usr/bin/env python3
"""Converte o CDL de SNES do Mesen 2 / MesenCE para o CDL do BizHawk que o DiztinGUIsh importa.

Uso:
  cdl_mesen_para_bizhawk.py jogo.cdl jogo.sfc saida-bizhawk.cdl

- A ROM é obrigatória: o CDL do Mesen marca opcode e operando com a mesma flag, então o
  tamanho de cada instrução sai do byte do opcode na ROM e do M e X gravados no CDL.
- Cabeçalho de copiadora (tamanho com resto 512 na divisão por 1024) é descartado antes.
- O arquivo gerado tem só o bloco CARTROM, que é o que o DiztinGUIsh lê. O BizHawk
  recusa abrir um CDL com blocos diferentes dos dele.
- Só Python 3, sem dependências.
"""
import argparse
import struct
import sys
import zlib

MESEN_CABECALHO = b"CDLv2"
MESEN_TAMANHO_CABECALHO = 9

MESEN_CODIGO = 0x01
MESEN_DADO = 0x02
MESEN_INDICE_8_BITS = 0x10
MESEN_ACUMULADOR_8_BITS = 0x20
MESEN_GSU = 0x40
MESEN_CX4 = 0x80

BIZHAWK_PRIMEIRO_BYTE = 0x01
BIZHAWK_OPERANDO = 0x02
BIZHAWK_DADO_CPU = 0x04
BIZHAWK_FLAGS_MX = 0x30

BIZHAWK_ASSINATURA = "BIZHAWK-CDL-2"
BIZHAWK_SISTEMA = "SNES"
BIZHAWK_BLOCO_ROM = "CARTROM"

TAMANHO_CABECALHO_COPIADORA = 512

IMEDIATO_M = "imediato_m"
IMEDIATO_X = "imediato_x"

OPCODES_IMEDIATO_M = {0x09, 0x29, 0x49, 0x69, 0x89, 0xA9, 0xC9, 0xE9}
OPCODES_IMEDIATO_X = {0xA0, 0xA2, 0xC0, 0xE0}
OPCODES_1_BYTE = {
    0x08, 0x0A, 0x0B, 0x18, 0x1A, 0x1B, 0x28, 0x2A, 0x2B, 0x38, 0x3A, 0x3B,
    0x40, 0x48, 0x4A, 0x4B, 0x58, 0x5A, 0x5B, 0x60, 0x68, 0x6A, 0x6B, 0x78,
    0x7A, 0x7B, 0x88, 0x8A, 0x8B, 0x98, 0x9A, 0x9B, 0xA8, 0xAA, 0xAB, 0xB8,
    0xBA, 0xBB, 0xC8, 0xCA, 0xCB, 0xD8, 0xDA, 0xDB, 0xE8, 0xEA, 0xEB, 0xF8,
    0xFA, 0xFB,
}
OPCODES_4_BYTES = {
    0x0F, 0x1F, 0x22, 0x2F, 0x3F, 0x4F, 0x5C, 0x5F, 0x6F, 0x7F, 0x8F, 0x9F,
    0xAF, 0xBF, 0xCF, 0xDF, 0xEF, 0xFF,
}
OPCODES_3_BYTES = {
    0x0C, 0x0D, 0x0E, 0x19, 0x1C, 0x1D, 0x1E, 0x20, 0x2C, 0x2D, 0x2E, 0x39,
    0x3C, 0x3D, 0x3E, 0x44, 0x4C, 0x4D, 0x4E, 0x54, 0x59, 0x5D, 0x5E, 0x62,
    0x6C, 0x6D, 0x6E, 0x79, 0x7C, 0x7D, 0x7E, 0x82, 0x8C, 0x8D, 0x8E, 0x99,
    0x9C, 0x9D, 0x9E, 0xAC, 0xAD, 0xAE, 0xB9, 0xBC, 0xBD, 0xBE, 0xCC, 0xCD,
    0xCE, 0xD9, 0xDC, 0xDD, 0xDE, 0xEC, 0xED, 0xEE, 0xF4, 0xF9, 0xFC, 0xFD,
    0xFE,
}


def tamanho_da_instrucao(opcode, flags_mesen):
    if opcode in OPCODES_IMEDIATO_M:
        acumulador_8_bits = flags_mesen & MESEN_ACUMULADOR_8_BITS
        return 2 if acumulador_8_bits else 3
    if opcode in OPCODES_IMEDIATO_X:
        indice_8_bits = flags_mesen & MESEN_INDICE_8_BITS
        return 2 if indice_8_bits else 3
    if opcode in OPCODES_1_BYTE:
        return 1
    if opcode in OPCODES_3_BYTES:
        return 3
    if opcode in OPCODES_4_BYTES:
        return 4
    return 2


def ler_cdl_mesen(conteudo):
    """Devolve (flags, crc32 ou None). None indica o formato antigo, sem cabeçalho."""
    if conteudo[:len(MESEN_CABECALHO)] == MESEN_CABECALHO:
        if len(conteudo) < MESEN_TAMANHO_CABECALHO:
            raise ValueError("CDL do Mesen truncado: cabeçalho incompleto")
        crc32 = struct.unpack_from("<I", conteudo, len(MESEN_CABECALHO))[0]
        return conteudo[MESEN_TAMANHO_CABECALHO:], crc32
    return conteudo, None


def tirar_cabecalho_de_copiadora(rom):
    tem_cabecalho = len(rom) % 1024 == TAMANHO_CABECALHO_COPIADORA
    if tem_cabecalho:
        return rom[TAMANHO_CABECALHO_COPIADORA:]
    return rom


def eh_codigo_do_65816(flags_mesen):
    marcado_como_codigo = flags_mesen & MESEN_CODIGO
    executado_por_coprocessador = flags_mesen & (MESEN_GSU | MESEN_CX4)
    return bool(marcado_como_codigo) and not executado_por_coprocessador


class Resultado:
    def __init__(self, flags_bizhawk):
        self.flags_bizhawk = flags_bizhawk
        self.instrucoes = 0
        self.bytes_de_operando = 0
        self.bytes_de_dado = 0
        self.bytes_de_coprocessador = 0
        self.operandos_sem_marca = []
        self.instrucoes_cortadas = []


def converter_flags(flags_mesen, rom):
    total = len(flags_mesen)
    saida = bytearray(total)
    resultado = Resultado(saida)

    for posicao, flags in enumerate(flags_mesen):
        if flags & MESEN_DADO:
            saida[posicao] |= BIZHAWK_DADO_CPU
            resultado.bytes_de_dado += 1
        codigo_de_coprocessador = flags & MESEN_CODIGO and not eh_codigo_do_65816(flags)
        if codigo_de_coprocessador:
            resultado.bytes_de_coprocessador += 1

    posicao = 0
    while posicao < total:
        flags = flags_mesen[posicao]
        if not eh_codigo_do_65816(flags):
            posicao += 1
            continue
        if posicao >= len(rom):
            resultado.instrucoes_cortadas.append(posicao)
            break

        tamanho = tamanho_da_instrucao(rom[posicao], flags)
        saida[posicao] |= BIZHAWK_PRIMEIRO_BYTE | (flags & BIZHAWK_FLAGS_MX)
        resultado.instrucoes += 1

        fim_da_instrucao = posicao + tamanho
        if fim_da_instrucao > total:
            resultado.instrucoes_cortadas.append(posicao)
        for posicao_operando in range(posicao + 1, min(fim_da_instrucao, total)):
            if flags_mesen[posicao_operando] & MESEN_CODIGO:
                saida[posicao_operando] |= BIZHAWK_OPERANDO
                resultado.bytes_de_operando += 1
            else:
                resultado.operandos_sem_marca.append(posicao_operando)
        posicao = fim_da_instrucao

    return resultado


def string_do_dotnet(texto):
    """Mesmo formato do BinaryWriter.Write(string): tamanho em 7 bits por byte, depois UTF-8."""
    dados = texto.encode("utf-8")
    tamanho = len(dados)
    prefixo = bytearray()
    while True:
        byte = tamanho & 0x7F
        tamanho >>= 7
        if tamanho:
            prefixo.append(byte | 0x80)
        else:
            prefixo.append(byte)
            break
    return bytes(prefixo) + dados


def montar_cdl_bizhawk(flags_cartrom):
    partes = [
        string_do_dotnet(BIZHAWK_ASSINATURA),
        string_do_dotnet(BIZHAWK_SISTEMA.ljust(15)),
        struct.pack("<i", 1),
        string_do_dotnet(BIZHAWK_BLOCO_ROM),
        struct.pack("<i", len(flags_cartrom)),
        bytes(flags_cartrom),
    ]
    return b"".join(partes)


def converter(conteudo_cdl_mesen, conteudo_rom):
    flags_mesen, crc32_gravado = ler_cdl_mesen(conteudo_cdl_mesen)
    rom = tirar_cabecalho_de_copiadora(conteudo_rom)
    avisos = []

    if crc32_gravado is None:
        avisos.append("CDL sem cabeçalho CDLv2 (formato antigo): CRC32 não conferido")
    else:
        crc32_da_rom = zlib.crc32(rom) & 0xFFFFFFFF
        if crc32_da_rom != crc32_gravado:
            avisos.append(
                f"CRC32 da ROM ({crc32_da_rom:08X}) difere do gravado no CDL ({crc32_gravado:08X}):"
                " confira se é a mesma revisão do jogo"
            )
    if len(rom) != len(flags_mesen):
        avisos.append(f"ROM com {len(rom)} bytes e CDL com {len(flags_mesen)} flags")

    resultado = converter_flags(flags_mesen, rom)
    if resultado.operandos_sem_marca:
        primeiro = resultado.operandos_sem_marca[0]
        avisos.append(
            f"{len(resultado.operandos_sem_marca)} byte(s) de operando sem a marca de código no Mesen"
            f" (o primeiro no offset ${primeiro:06X}): M ou X misturados ou código sobreposto"
        )
    if resultado.instrucoes_cortadas:
        primeiro = resultado.instrucoes_cortadas[0]
        avisos.append(f"instrução cortada pelo fim da ROM ou do CDL no offset ${primeiro:06X}")

    return montar_cdl_bizhawk(resultado.flags_bizhawk), resultado, avisos


def main(argumentos=None):
    parser = argparse.ArgumentParser(description="CDL do Mesen (SNES) para CDL do BizHawk (DiztinGUIsh)")
    parser.add_argument("cdl_mesen", help="arquivo .cdl salvo pelo Mesen")
    parser.add_argument("rom", help="ROM usada na sessão (.sfc ou .smc)")
    parser.add_argument("saida", help="arquivo .cdl no formato do BizHawk")
    opcoes = parser.parse_args(argumentos)

    with open(opcoes.cdl_mesen, "rb") as arquivo:
        conteudo_cdl = arquivo.read()
    with open(opcoes.rom, "rb") as arquivo:
        conteudo_rom = arquivo.read()

    try:
        cdl_bizhawk, resultado, avisos = converter(conteudo_cdl, conteudo_rom)
    except ValueError as erro:
        print(f"erro: {erro}", file=sys.stderr)
        return 1

    with open(opcoes.saida, "wb") as arquivo:
        arquivo.write(cdl_bizhawk)

    for aviso in avisos:
        print(f"aviso: {aviso}", file=sys.stderr)
    print(
        f"{resultado.instrucoes} instruções, {resultado.bytes_de_operando} bytes de operando,"
        f" {resultado.bytes_de_dado} bytes de dado, {resultado.bytes_de_coprocessador} bytes de"
        f" código do GSU ou do Cx4 ignorados -> {opcoes.saida}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
