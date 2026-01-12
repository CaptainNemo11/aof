import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock

import re

def parse_machine_file(filename):
    machines = []
    
    with open(filename, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue  
            
            target_match = re.search(r"\[(.*?)\]", line)
            if not target_match:
                continue
            target = target_match.group(1)
            
            buttons = []
            for btn in re.findall(r"\((.*?)\)", line):
                btn_list = [int(x) for x in btn.split(",") if x.strip() != ""]
                buttons.append(btn_list)
            
            machines.append({"target": target, "buttons": buttons})
    
    return machines




def matrix(target, buttons):
    n_buttons = len(buttons)
    n_lights  = len(target)

    rows = []

    for light in range(n_lights):
        mask = 0
        for b_idx, btn in enumerate(buttons):
            if light in btn:
                mask |= 1 << (n_buttons - 1 - b_idx)

        rhs = 1 if target[light] == "#" else 0
        rows.append((mask << 1) | rhs)

    return rows, n_buttons, n_lights
def gaussian_elim_gf2(rows, nvars):
    pivot_row = 0
    pivot_cols = []

    for col in range(nvars):
        bit = 1 << (nvars - col)

        pivot = None
        for r in range(pivot_row, len(rows)):
            if rows[r] & bit:
                pivot = r
                break
        if pivot is None:
            continue

        rows[pivot_row], rows[pivot] = rows[pivot], rows[pivot_row]

        for r in range(len(rows)):
            if r != pivot_row and (rows[r] & bit):
                rows[r] ^= rows[pivot_row]

        pivot_cols.append(col)
        pivot_row += 1
    return rows, pivot_cols



def nullspace_basis(rows, pivot_cols, nvars):
    free = [i for i in range(nvars) if i not in pivot_cols]
    basis = []

    for f in free:
        vec = 1 << (nvars - 1 - f)
        for r, p in enumerate(pivot_cols):
            if (rows[r] >> (nvars -  f)) & 1:
                vec |= 1 << (nvars - 1 - p)
        basis.append(vec)
    return basis, free


def particular_solution(rows, pivot_cols, nvars):
    x0 = 0
    for r, p in enumerate(pivot_cols):
        if rows[r] & 1:
            x0 |= 1 << (nvars - 1 - p)
    return x0


def minimal_solution(rows, nvars):
    n_rows, pivot_cols = gaussian_elim_gf2(rows, nvars)
    basis, _ = nullspace_basis(n_rows, pivot_cols, nvars)
    x0 = particular_solution(n_rows, pivot_cols, nvars)
    best = x0
    best_w = bin(x0).count("1")

    for mask in range(1 << len(basis)):
        x = x0
        for i in range(len(basis)):
            if (mask >> i) & 1:
                x ^= basis[i]
        w = bin(x).count("1")
        if w < best_w:
            best = x
            best_w = w

    return best



@cocotb.test()
async def day10(dut):
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())


    for _ in range(2):
        await RisingEdge(dut.clk)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    total = 0
    machines = parse_machine_file("input.txt")
    for m in machines:
        rows, b, l = matrix(m["target"], m["buttons"])
        sol = minimal_solution(rows, b)
        total += bin(sol).count("1");

        for r in range(l):
            dut.i_matrix[r].value = rows[r]
        await RisingEdge(dut.clk)
        dut.i_n_lights.value = l
        dut.i_n_buttons.value = b
        await RisingEdge(dut.clk)
        dut.start.value = 1
        await RisingEdge(dut.clk)
        dut.start.value = 0
        while not dut.done.value:
            await RisingEdge(dut.clk)
        while int(dut.state.value) != 0:
            await RisingEdge(dut.clk)
        for _ in range(2):
            await RisingEdge(dut.clk)
    
    result_port = int(dut.o_min_presses.value)
    assert(result_port == total)
    print("==========================")
    print(result_port) 
    print("==========================")