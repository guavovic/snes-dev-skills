#!/usr/bin/env python3
"""Testes do cdl_mesen_para_bizhawk.py com ROM e CDL sintéticos, montados aqui mesmo.

Rodar nesta pasta: python -m unittest test_cdl_mesen_para_bizhawk -v
"""
import contextlib
import io
import os
import re
import struct
import tempfile
import unittest
import zlib

import cdl_mesen_para_bizhawk as conversor

PASTA_DO_TESTE = os.path.dirname(os.path.abspath(__file__))
TABELA_DE_OPCODES = os.path.join(PASTA_DO_TESTE, "..", "..", "snes-assembly", "references", "instrucoes.md")

CODIGO = 0x01
DADO = 0x02
DESTINO_DE_SALTO = 0x04
ENTRADA_DE_SUBROTINA = 0x08
X8 = 0x10
M8 = 0x20
GSU = 0x40


def ler_string_do_dotnet(fluxo):
    tamanho = 0
    deslocamento = 0
    while True:
        byte = fluxo.read(1)[0]
        tamanho |= (byte & 0x7F) << deslocamento
        deslocamento += 7
        if not byte & 0x80:
            break
    return fluxo.read(tamanho).decode("utf-8")


def ler_como_o_diztinguish(conteudo):
    """Porta do BizHawkCdlImporter do DiztinGUIsh (LoadFromStream e CopyInto, commit 7484b87).

    Devolve, por byte, (tipo, m, x) com tipo em "opcode", "operando", "dado" ou None.
    """
    fluxo = io.BytesIO(conteudo)
    assinatura = ler_string_do_dotnet(fluxo)
    if assinatura != "BIZHAWK-CDL-2":
        raise ValueError("não é CDL do BizHawk")
    if ler_string_do_dotnet(fluxo).rstrip(" ") != "SNES":
        raise ValueError("CDL não é de SNES")
    quantidade = struct.unpack("<i", fluxo.read(4))[0]
    blocos = {}
    for _ in range(quantidade):
        nome = ler_string_do_dotnet(fluxo)
        tamanho = struct.unpack("<i", fluxo.read(4))[0]
        blocos[nome] = fluxo.read(tamanho)
    if fluxo.read():
        raise ValueError("sobrou byte depois do último bloco")

    m = x = False
    marcas = []
    for flags in blocos["CARTROM"]:
        tipo = None
        if flags & 0x01:
            tipo = "opcode"
            m = bool(flags & 0x20)
            x = bool(flags & 0x10)
        elif flags & 0x02:
            tipo = "operando"
        elif flags & 0x04 or flags & 0x08:
            tipo = "dado"
        executado = tipo in ("opcode", "operando")
        marcas.append((tipo, m, x) if executado else (tipo, None, None))
    return marcas


def cdl_mesen(flags, rom):
    crc32 = zlib.crc32(bytes(rom)) & 0xFFFFFFFF
    return b"CDLv2" + struct.pack("<I", crc32) + bytes(flags)


ROTINA_DE_EXEMPLO = [
    (bytes([0xC2, 0x30]), CODIGO | M8 | X8 | ENTRADA_DE_SUBROTINA, CODIGO | M8 | X8),
    (bytes([0xA9, 0x34, 0x12]), CODIGO, CODIGO),
    (bytes([0xA2, 0x00, 0x01]), CODIGO, CODIGO),
    (bytes([0xE2, 0x30]), CODIGO, CODIGO),
    (bytes([0xA9, 0x12]), CODIGO | M8 | X8, CODIGO | M8 | X8),
    (bytes([0xA0, 0x05]), CODIGO | M8 | X8, CODIGO | M8 | X8),
    (bytes([0x22, 0x00, 0x80, 0x00]), CODIGO | M8 | X8, CODIGO | M8 | X8),
    (bytes([0x54, 0x7E, 0x7F]), CODIGO | M8 | X8, CODIGO | M8 | X8),
    (bytes([0x80, 0x02]), CODIGO | M8 | X8, CODIGO | M8 | X8),
    (bytes([0xEA, 0xEA]), 0, 0),
    (bytes([0x60]), CODIGO | M8 | X8 | DESTINO_DE_SALTO, None),
    (bytes([0x12, 0x34, 0xEA]), DADO, DADO),
]

TAMANHOS_ESPERADOS = [2, 3, 3, 2, 2, 2, 4, 3, 2]


def montar_rotina():
    rom = bytearray()
    flags = bytearray()
    for bytes_da_instrucao, flag_primeiro, flag_resto in ROTINA_DE_EXEMPLO:
        rom += bytes_da_instrucao
        flags.append(flag_primeiro)
        flags += bytes([flag_resto if flag_resto is not None else flag_primeiro] * (len(bytes_da_instrucao) - 1))
    return bytes(rom), bytes(flags)


def ler_tabela_de_tamanhos():
    with open(TABELA_DE_OPCODES, encoding="utf-8") as arquivo:
        texto = arquivo.read()
    linha = re.compile(r"^\| [A-Z]{3} \| \$([0-9A-F]{2}) \| [^|]* \| [^|]* \| ([^|]*) \|", re.MULTILINE)
    return {int(opcode, 16): coluna.strip() for opcode, coluna in linha.findall(texto)}


class TamanhoDaInstrucao(unittest.TestCase):
    def test_bate_com_a_tabela_da_skill_snes_assembly_nos_256_opcodes(self):
        tabela = ler_tabela_de_tamanhos()
        self.assertEqual(len(tabela), 256)
        for opcode, coluna in tabela.items():
            if coluna == "3-m":
                esperado_8_bits, esperado_16_bits = 2, 3
                flag_8_bits = M8
            elif coluna == "3-x":
                esperado_8_bits, esperado_16_bits = 2, 3
                flag_8_bits = X8
            else:
                tamanho = int(coluna.split()[0])
                esperado_8_bits = esperado_16_bits = tamanho
                flag_8_bits = M8 | X8
            with self.subTest(opcode=f"${opcode:02X}"):
                self.assertEqual(conversor.tamanho_da_instrucao(opcode, CODIGO | flag_8_bits), esperado_8_bits)
                self.assertEqual(conversor.tamanho_da_instrucao(opcode, CODIGO), esperado_16_bits)

    def test_imediato_de_acumulador_depende_so_de_m(self):
        self.assertEqual(conversor.tamanho_da_instrucao(0xA9, CODIGO | X8), 3)
        self.assertEqual(conversor.tamanho_da_instrucao(0xA9, CODIGO | M8), 2)

    def test_imediato_de_indice_depende_so_de_x(self):
        self.assertEqual(conversor.tamanho_da_instrucao(0xA2, CODIGO | M8), 3)
        self.assertEqual(conversor.tamanho_da_instrucao(0xA2, CODIGO | X8), 2)


class Conversao(unittest.TestCase):
    def setUp(self):
        self.rom, self.flags = montar_rotina()
        cdl_bizhawk, self.resultado, self.avisos = conversor.converter(cdl_mesen(self.flags, self.rom), self.rom)
        self.cdl_bizhawk = cdl_bizhawk
        self.marcas = ler_como_o_diztinguish(cdl_bizhawk)

    def test_cabecalho_igual_ao_do_codedatalog_do_bizhawk(self):
        esperado = (
            b"\x0dBIZHAWK-CDL-2"
            + b"\x0fSNES           "
            + struct.pack("<i", 1)
            + b"\x07CARTROM"
            + struct.pack("<i", len(self.rom))
        )
        self.assertTrue(self.cdl_bizhawk.startswith(esperado))
        self.assertEqual(len(self.cdl_bizhawk), len(esperado) + len(self.rom))

    def test_cada_instrucao_vira_opcode_seguido_de_operandos(self):
        posicao = 0
        for tamanho in TAMANHOS_ESPERADOS:
            self.assertEqual(self.marcas[posicao][0], "opcode", f"offset {posicao}")
            for operando in range(posicao + 1, posicao + tamanho):
                self.assertEqual(self.marcas[operando][0], "operando", f"offset {operando}")
            posicao += tamanho
        self.assertEqual(self.resultado.instrucoes, len(TAMANHOS_ESPERADOS) + 1)

    def test_m_e_x_gravados_no_opcode_chegam_ao_diztinguish(self):
        self.assertEqual(self.marcas[0], ("opcode", True, True))
        self.assertEqual(self.marcas[2], ("opcode", False, False))
        self.assertEqual(self.marcas[4], ("operando", False, False))
        self.assertEqual(self.marcas[10], ("opcode", True, True))
        self.assertEqual(self.marcas[12], ("opcode", True, True))

    def test_operando_no_bizhawk_nao_leva_m_nem_x(self):
        flags_cartrom = self.cdl_bizhawk[-len(self.rom):]
        self.assertEqual(flags_cartrom[0], 0x31)
        self.assertEqual(flags_cartrom[1], 0x02)
        self.assertEqual(flags_cartrom[2], 0x01)

    def test_byte_nao_visto_e_dado_ficam_separados(self):
        nao_vistos = [23, 24]
        for posicao in nao_vistos:
            self.assertEqual(self.marcas[posicao][0], None)
        self.assertEqual(self.marcas[25][0], "opcode")
        for posicao in (26, 27, 28):
            self.assertEqual(self.marcas[posicao][0], "dado")

    def test_sem_avisos_quando_rom_e_cdl_batem(self):
        self.assertEqual(self.avisos, [])


class CasosDeBorda(unittest.TestCase):
    def test_cabecalho_de_copiadora_e_descartado(self):
        rom, flags = montar_rotina()
        rom_com_cabecalho = bytes(512) + rom + bytes(1024 - len(rom))
        rom_sem_cabecalho = rom + bytes(1024 - len(rom))
        flags = flags + bytes(1024 - len(flags))
        _, resultado, avisos = conversor.converter(cdl_mesen(flags, rom_sem_cabecalho), rom_com_cabecalho)
        self.assertEqual(avisos, [])
        self.assertEqual(resultado.instrucoes, len(TAMANHOS_ESPERADOS) + 1)

    def test_formato_antigo_sem_cabecalho_converte_com_aviso(self):
        rom, flags = montar_rotina()
        cdl_bizhawk, _, avisos = conversor.converter(bytes(flags), rom)
        self.assertEqual(len(avisos), 1)
        self.assertIn("formato antigo", avisos[0])
        self.assertEqual(ler_como_o_diztinguish(cdl_bizhawk)[0][0], "opcode")

    def test_crc_diferente_avisa(self):
        rom, flags = montar_rotina()
        outra_rom = bytes([rom[0] ^ 0xFF]) + rom[1:]
        _, _, avisos = conversor.converter(cdl_mesen(flags, outra_rom), rom)
        self.assertTrue(any("CRC32" in aviso for aviso in avisos))

    def test_codigo_do_gsu_nao_vira_codigo_do_65816(self):
        rom = bytes([0xA9, 0x12, 0x00])
        flags = bytes([CODIGO | GSU, CODIGO | GSU, CODIGO | GSU | DADO])
        cdl_bizhawk, resultado, _ = conversor.converter(cdl_mesen(flags, rom), rom)
        marcas = ler_como_o_diztinguish(cdl_bizhawk)
        self.assertEqual([marca[0] for marca in marcas], [None, None, "dado"])
        self.assertEqual(resultado.bytes_de_coprocessador, 3)

    def test_operando_sem_marca_de_codigo_gera_aviso(self):
        rom = bytes([0xA9, 0x34, 0x12])
        flags = bytes([CODIGO | X8, CODIGO | X8, DADO])
        cdl_bizhawk, resultado, avisos = conversor.converter(cdl_mesen(flags, rom), rom)
        self.assertEqual(resultado.operandos_sem_marca, [2])
        self.assertTrue(any("sem a marca de código" in aviso for aviso in avisos))
        self.assertEqual(ler_como_o_diztinguish(cdl_bizhawk)[2][0], "dado")

    def test_instrucao_cortada_no_fim_gera_aviso(self):
        rom = bytes([0xEA, 0x22, 0x00])
        flags = bytes([CODIGO, CODIGO, CODIGO])
        _, resultado, avisos = conversor.converter(cdl_mesen(flags, rom), rom)
        self.assertEqual(resultado.instrucoes_cortadas, [1])
        self.assertTrue(any("cortada" in aviso for aviso in avisos))

    def test_string_longa_usa_mais_de_um_byte_de_tamanho(self):
        self.assertEqual(conversor.string_do_dotnet("a" * 200)[:2], bytes([0xC8, 0x01]))


class LinhaDeComando(unittest.TestCase):
    def test_converte_arquivos_e_devolve_zero(self):
        rom, flags = montar_rotina()
        with tempfile.TemporaryDirectory() as pasta:
            caminho_cdl = os.path.join(pasta, "teste.cdl")
            caminho_rom = os.path.join(pasta, "teste.sfc")
            caminho_saida = os.path.join(pasta, "bizhawk.cdl")
            with open(caminho_cdl, "wb") as arquivo:
                arquivo.write(cdl_mesen(flags, rom))
            with open(caminho_rom, "wb") as arquivo:
                arquivo.write(rom)
            saida_impressa = io.StringIO()
            with contextlib.redirect_stdout(saida_impressa):
                codigo_de_saida = conversor.main([caminho_cdl, caminho_rom, caminho_saida])
            with open(caminho_saida, "rb") as arquivo:
                marcas = ler_como_o_diztinguish(arquivo.read())
        self.assertEqual(codigo_de_saida, 0)
        self.assertEqual(len(marcas), len(rom))
        self.assertIn("10 instruções, 14 bytes de operando, 3 bytes de dado", saida_impressa.getvalue())


if __name__ == "__main__":
    unittest.main()
