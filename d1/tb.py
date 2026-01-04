import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock

def init_state():
	return  {
    "pos": 50,
    "zero": 0,
	"abs":50,
	}

def py_rotate(dir: str, dis: int, state):
    dis = dis if dir == 'R' else -dis
    state["pos"] = (state["pos"] + dis) % 100
    if state["pos"] == 0:
        state["zero"] += 1
    return state["zero"]




@cocotb.test()
async def day1_p1_solve(dut):
	state = init_state()
	cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
	dut.rst.value = 1
	
	for _ in range(2):
		await RisingEdge(dut.clk)
	dut.rst.value = 1
	await RisingEdge(dut.clk)

	dut.rst.value = 0
	dut.part.value = 0
	py_zero = 0
	with open("input.txt") as f:
		lines = f.readlines()
	for line in lines:
		line = line.strip()
		direction = line[0]
		distance  = int(line[1:])
		dut.i_dir.value  = 0 if direction == 'L' else 1
		dut.i_dist.value = distance
		await RisingEdge(dut.clk)
		py_zero=py_rotate(direction, distance, state)
	pwd = int(dut.o_zero.value)
	print("Password:",  pwd)
	assert(pwd == py_zero)
		

def count_zero_hits(old_abs, new_abs):
    if new_abs > old_abs:  
        return max(0,
            new_abs // 100 - old_abs // 100
        )
    else:  
        return max(0,
            (old_abs - 1) // 100 - (new_abs - 1) // 100
        )

def py_rotate2(dir: str, dist: int, state):
	signed = dist if dir == 'R' else -dist
	old_abs = state["abs"]
	new_abs = old_abs + signed
	state["zero"] += count_zero_hits(old_abs, new_abs)
	state["abs"] = new_abs
	state["pos"] = new_abs % 100
	return state["zero"]



@cocotb.test()
async def day1_p2_solve(dut):
	state = init_state()
	cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
	for _ in range(2):
		await RisingEdge(dut.clk)
	dut.rst.value = 1
	await RisingEdge(dut.clk)

	dut.rst.value = 0
	dut.part.value = 1
	py_zero = 0
	with open("input.txt") as f:
		lines = f.readlines()
	for line in lines:
		line = line.strip()
		direction = line[0]
		distance  = int(line[1:])
		dut.i_dir.value  = 0 if direction == 'L' else 1
		dut.i_dist.value = distance
		await RisingEdge(dut.clk)
		py_zero=py_rotate2(direction, distance, state)
	pwd = int(dut.o_zero.value)
	print("Password:",  pwd)
	assert(pwd == py_zero)
