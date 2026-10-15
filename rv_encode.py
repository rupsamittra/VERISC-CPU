#!/usr/bin/env python3
"""
Tiny RV32I assembler for the 10 instructions in this project (+ NOP).

Supported:  ADD SUB AND OR SLT | ADDI LW | SW | BEQ | JAL | NOP

Usage:
  python rv_encode.py "ADDI x1, x0, 5" "ADD x3, x1, x2"
  python rv_encode.py -f program.asm          # one instruction per line, '#' or '//' comments
  python rv_encode.py -v -f program.asm       # also print Verilog memory[...] lines

Branch/jump operands are BYTE OFFSETS relative to that instruction's own address
(e.g. BEQ x1, x2, 8  means "skip ahead 8 bytes if equal"), same as the ISA.
"""
import re
import sys

R_TYPE = {  # name: (funct7, funct3)
    "ADD": (0b0000000, 0b000),
    "SUB": (0b0100000, 0b000),
    "AND": (0b0000000, 0b111),
    "OR":  (0b0000000, 0b110),
    "SLT": (0b0000000, 0b010),
}


def reg(tok):
    m = re.fullmatch(r"x(\d+)", tok.strip().lower())
    if not m or int(m.group(1)) > 31:
        raise ValueError(f"bad register '{tok.strip()}' (use x0..x31)")
    return int(m.group(1))


def num(tok):
    return int(tok.strip(), 0)  # accepts 10, -4, 0x1F


def fit(value, bits, what):
    lo, hi = -(1 << (bits - 1)), (1 << (bits - 1)) - 1
    if not lo <= value <= hi:
        raise ValueError(f"{what} {value} does not fit in {bits} signed bits ({lo}..{hi})")
    return value & ((1 << bits) - 1)


def mem_operand(tok):
    m = re.fullmatch(r"\s*(-?\w+)\s*\(\s*(x\d+)\s*\)\s*", tok, re.I)
    if not m:
        raise ValueError(f"expected offset(xN), got '{tok.strip()}'")
    return num(m.group(1)), reg(m.group(2))


def encode(line):
    """Return (word, field_widths) for one assembly line."""
    line = line.strip()
    name, _, rest = line.partition(" ")
    name = name.upper()
    ops = [o for o in rest.split(",")] if rest.strip() else []

    def need(n):
        if len(ops) != n:
            raise ValueError(f"{name} needs {n} operands, got {len(ops)}")

    if name == "NOP":
        return 0x00000013, (12, 5, 3, 5, 7)

    if name in R_TYPE:                                   # R-type
        need(3)
        f7, f3 = R_TYPE[name]
        rd, rs1, rs2 = reg(ops[0]), reg(ops[1]), reg(ops[2])
        w = (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0b0110011
        return w, (7, 5, 5, 3, 5, 7)

    if name == "ADDI":                                   # I-type
        need(3)
        rd, rs1, imm = reg(ops[0]), reg(ops[1]), fit(num(ops[2]), 12, "immediate")
        w = (imm << 20) | (rs1 << 15) | (0b000 << 12) | (rd << 7) | 0b0010011
        return w, (12, 5, 3, 5, 7)

    if name == "LW":                                     # I-type load
        need(2)
        rd = reg(ops[0])
        off, rs1 = mem_operand(ops[1])
        imm = fit(off, 12, "offset")
        w = (imm << 20) | (rs1 << 15) | (0b010 << 12) | (rd << 7) | 0b0000011
        return w, (12, 5, 3, 5, 7)

    if name == "SW":                                     # S-type
        need(2)
        rs2 = reg(ops[0])
        off, rs1 = mem_operand(ops[1])
        imm = fit(off, 12, "offset")
        w = ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (0b010 << 12) \
            | ((imm & 0x1F) << 7) | 0b0100011
        return w, (7, 5, 5, 3, 5, 7)

    if name == "BEQ":                                    # B-type
        need(3)
        rs1, rs2, off = reg(ops[0]), reg(ops[1]), num(ops[2])
        if off % 2:
            raise ValueError("branch offset must be even")
        i = fit(off, 13, "branch offset")
        w = (((i >> 12) & 1) << 31) | (((i >> 5) & 0x3F) << 25) | (rs2 << 20) \
            | (rs1 << 15) | (0b000 << 12) | (((i >> 1) & 0xF) << 8) \
            | (((i >> 11) & 1) << 7) | 0b1100011
        return w, (1, 6, 5, 5, 3, 4, 1, 7)

    if name == "JAL":                                    # J-type
        need(2)
        rd, off = reg(ops[0]), num(ops[1])
        if off % 2:
            raise ValueError("jump offset must be even")
        i = fit(off, 21, "jump offset")
        w = (((i >> 20) & 1) << 31) | (((i >> 1) & 0x3FF) << 21) | (((i >> 11) & 1) << 20) \
            | (((i >> 12) & 0xFF) << 12) | (rd << 7) | 0b1101111
        return w, (1, 10, 1, 8, 5, 7)

    raise ValueError(f"unsupported instruction '{name}'")


def grouped_binary(word, widths):
    bits = f"{word:032b}"
    out, pos = [], 0
    for w in widths:
        out.append(bits[pos:pos + w])
        pos += w
    return "_".join(out)


def main(argv):
    verilog = "-v" in argv
    argv = [a for a in argv if a != "-v"]
    if len(argv) >= 2 and argv[0] == "-f":
        with open(argv[1]) as fh:
            lines = fh.read().splitlines()
    else:
        lines = argv
    lines = [re.split(r"#|//", l)[0].strip() for l in lines]
    lines = [l for l in lines if l]
    if not lines:
        print(__doc__)
        return 1

    status = 0
    for n, line in enumerate(lines):
        try:
            word, widths = encode(line)
        except ValueError as e:
            print(f"ERROR  {line!r}: {e}")
            status = 1
            continue
        if verilog:
            print(f"memory[{n}] = 32'h{word:08X};  // 0x{n * 4:02X}: {line}")
        else:
            print(f"0x{word:08X}  {grouped_binary(word, widths)}  {line}")
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
