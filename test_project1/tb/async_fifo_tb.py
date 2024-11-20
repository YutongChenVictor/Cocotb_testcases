import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray

import random

@cocotb.test()
async def async_fifo_test(dut):
    # 创建写时钟和读时钟
    wr_clock = Clock(dut.wr_clk, 20, units="ns")
    rd_clock = Clock(dut.rd_clk, 20, units="ns")

    dut.wr_rst_n = 0
    dut.rd_rst_n = 0

    cocotb.start_soon(wr_clock.start(start_high=False))
    cocotb.start_soon(rd_clock.start(start_high=False))
    await RisingEdge(dut.wr_clk)  # 等待写时钟的上升沿
    dut.wr_rst_n = 1
    await RisingEdge(dut.rd_clk)  # 等待写时钟的上升沿

    dut.rd_rst_n = 1


    # 生成随机数组并写入FIFO
    random_array = [random.randint(0, 256) for _ in range(8)]
    for i in range(8):
        await RisingEdge(dut.wr_clk)  # 等待写时钟的上升沿
        dut.wr_en = 1
        dut.wr_data = random_array[i]
    await RisingEdge(dut.wr_clk)

    dut.wr_en = 0

    # 等待一段时间以确保FIFO有足够的时间处理写入并更新fifo_full信号
    # 假设FIFO在写满后需要至少一个时钟周期来更新fifo_full信号
    for i in range(2):
        await RisingEdge(dut.wr_clk)

    # 断言fifo_full信号是否为1
    assert dut.fifo_full == 1, f"Port \"fifo_full\" is incorrect\n"

    await RisingEdge(dut.rd_clk)  # 等待写时钟的上升沿

    dut.rd_en = 1
    await RisingEdge(dut.rd_clk)  # 等待写时钟的上升沿

    for i in range(8):
        await RisingEdge(dut.rd_clk)  # 等待写时钟的上升沿
        assert dut.rd_data == random_array[i], f"Port \"fifo_out\" is incorrect on circle {i}\n"
    await RisingEdge(dut.rd_clk)
    dut.rd_en = 0
    await RisingEdge(dut.rd_clk)
    assert dut.fifo_empty == 1, f"Port \"fifo_empty\" is incorrect\n"
