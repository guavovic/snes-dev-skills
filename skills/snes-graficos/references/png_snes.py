#!/usr/bin/env python3
"""Converte PNG indexado <-> tiles planares do SNES (1/2/3/4/8bpp) e paleta BGR555.

Uso:
  png_snes.py png2snes entrada.png tiles.bin [--bpp 4] [--pal paleta.bin] [--round]
  png_snes.py snes2png tiles.bin saida.png [--bpp 4] [--pal paleta.bin] [--largura 16]

- O PNG precisa estar em modo indexado (P). O índice do pixel vira o valor do pixel
  no tile, sem remapear cor. Largura e altura múltiplas de 8.
- Tiles saem na ordem de leitura do PNG (esquerda para direita, cima para baixo),
  sem deduplicar. Para BG com tilemap, use superfamiconv.
- Mode 7 (8bpp chunky) não é tratado aqui.
"""
import argparse
import sys

from PIL import Image

PLANOS_POR_BPP = {1: 1, 2: 2, 3: 3, 4: 4, 8: 8}


def bytes_por_tile(bpp):
    return 8 * bpp


def codificar_tile(pixels, bpp):
    """pixels: 64 índices (linha a linha). Retorna os bytes do tile no formato SNES."""
    saida = bytearray(bytes_por_tile(bpp))
    for y in range(8):
        linha = pixels[y * 8:(y + 1) * 8]
        for plano in range(bpp):
            valor = 0
            for x in range(8):
                bit = (linha[x] >> plano) & 1
                valor |= bit << (7 - x)
            par, dentro_do_par = divmod(plano, 2)
            if bpp == 1:
                posicao = y
            elif bpp == 3 and plano == 2:
                posicao = 16 + y
            else:
                posicao = par * 16 + y * 2 + dentro_do_par
            saida[posicao] = valor
    return bytes(saida)


def decodificar_tile(dados, bpp):
    pixels = [0] * 64
    for y in range(8):
        for plano in range(bpp):
            par, dentro_do_par = divmod(plano, 2)
            if bpp == 1:
                posicao = y
            elif bpp == 3 and plano == 2:
                posicao = 16 + y
            else:
                posicao = par * 16 + y * 2 + dentro_do_par
            valor = dados[posicao]
            for x in range(8):
                pixels[y * 8 + x] |= ((valor >> (7 - x)) & 1) << plano
    return pixels


def canal_para_5bits(valor, arredondar):
    if arredondar:
        return (valor * 31 + 127) // 255
    return valor >> 3


def canal_para_8bits(valor):
    return (valor << 3) | (valor >> 2)


def rgb_para_bgr555(r, g, b, arredondar=False):
    cor = (canal_para_5bits(b, arredondar) << 10) | (canal_para_5bits(g, arredondar) << 5) | canal_para_5bits(r, arredondar)
    return bytes((cor & 0xFF, cor >> 8))


def bgr555_para_rgb(lo, hi):
    cor = lo | (hi << 8)
    return (canal_para_8bits(cor & 0x1F), canal_para_8bits((cor >> 5) & 0x1F), canal_para_8bits((cor >> 10) & 0x1F))


def png_para_snes(args):
    imagem = Image.open(args.entrada)
    if imagem.mode != "P":
        sys.exit("O PNG precisa estar em modo indexado (P).")
    largura, altura = imagem.size
    if largura % 8 or altura % 8:
        sys.exit("Largura e altura precisam ser múltiplas de 8.")
    limite = 1 << args.bpp
    origem = imagem.load()
    saida = bytearray()
    for ty in range(0, altura, 8):
        for tx in range(0, largura, 8):
            pixels = [origem[tx + x, ty + y] for y in range(8) for x in range(8)]
            if max(pixels) >= limite:
                sys.exit(f"Tile em ({tx},{ty}) usa índice {max(pixels)}, acima do limite de {args.bpp}bpp.")
            saida += codificar_tile(pixels, args.bpp)
    with open(args.saida, "wb") as arquivo:
        arquivo.write(saida)
    if args.pal:
        paleta = imagem.getpalette()[:limite * 3]
        with open(args.pal, "wb") as arquivo:
            for i in range(0, len(paleta), 3):
                arquivo.write(rgb_para_bgr555(*paleta[i:i + 3], arredondar=args.round))


def snes_para_png(args):
    with open(args.entrada, "rb") as arquivo:
        dados = arquivo.read()
    tamanho = bytes_por_tile(args.bpp)
    total = len(dados) // tamanho
    colunas = args.largura
    linhas = (total + colunas - 1) // colunas
    imagem = Image.new("P", (colunas * 8, linhas * 8))
    if args.pal:
        with open(args.pal, "rb") as arquivo:
            bruto = arquivo.read()
        paleta = []
        for i in range(0, len(bruto) - 1, 2):
            paleta += bgr555_para_rgb(bruto[i], bruto[i + 1])
    else:
        niveis = (1 << args.bpp) - 1
        paleta = []
        for i in range(niveis + 1):
            cinza = i * 255 // niveis
            paleta += (cinza, cinza, cinza)
    imagem.putpalette(paleta + [0] * (768 - len(paleta)))
    pixels = imagem.load()
    for n in range(total):
        tile = decodificar_tile(dados[n * tamanho:(n + 1) * tamanho], args.bpp)
        ox, oy = (n % colunas) * 8, (n // colunas) * 8
        for i, valor in enumerate(tile):
            pixels[ox + i % 8, oy + i // 8] = valor
    imagem.save(args.saida)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="comando", required=True)
    for nome, funcao in (("png2snes", png_para_snes), ("snes2png", snes_para_png)):
        p = sub.add_parser(nome)
        p.add_argument("entrada")
        p.add_argument("saida")
        p.add_argument("--bpp", type=int, default=4, choices=sorted(PLANOS_POR_BPP))
        p.add_argument("--pal", help="arquivo de paleta BGR555 (2 bytes por cor, little endian)")
        p.set_defaults(funcao=funcao)
        if nome == "png2snes":
            p.add_argument("--round", action="store_true", help="arredonda ao reduzir para 5 bits (arte nova)")
        else:
            p.add_argument("--largura", type=int, default=16, help="tiles por linha no PNG")
    args = parser.parse_args()
    args.funcao(args)


if __name__ == "__main__":
    main()
