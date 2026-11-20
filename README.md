# Custom FPGA Architecture & Bitstream Programming

## Overview
This project involves the RTL design and verification of a simplified, custom Field-Programmable Gate Array (FPGA) architecture. The architecture consists of two Configurable Logic Blocks (CLBs), a programmable routing Connector, and a 38-bit SRAM configuration memory. 

The FPGA is programmed using a serial bitstream, which configures the Look-Up Tables (LUT4s), output registers, and routing multiplexers. To check the functionality, the FPGA is programmed to implement five different logic functions, ranging from purely combinational to pipelined sequential circuits.

**Course:** Digital VLSI System Design (Fall 2026)  
**Institution:** Sharif University of Technology  
**Instructor:** Dr. Shabany

## Architecture
The system is composed of the following modules:

### 1. Configurable Logic Block (CLB)
Each CLB contains:
*   **16 SRAM cells** configuring a 4-input Look-Up Table (LUT4).
*   **1 SRAM cell** configuring a multiplexer that selects between the combinational LUT output or a registered (flip-flop) output.
*   *Total:* 17 SRAM bits per CLB.

![CLB Architecture](images/CLB.png)
*Figure 1: Internal architecture of the Configurable Logic Block (CLB).*

### 2. Connector (Routing Matrix)
The connector routes the output of `CLBa` to the four inputs of `CLBb` via four 2-to-1 multiplexers. The select lines for these muxes are configured via 4 SRAM cells, allowing mapping between the two CLBs.

![Connector Architecture](images/Connector.png)
*Figure 2: The programmable routing matrix (Connector).*

### 3. FPGA Top-Level
The top-level module integrates 2 CLBs and 1 Connector. The programming sequence expects a **38-bit serial bitstream** (17 bits for CLBa, 4 bits for the Connector, and 17 bits for CLBb).

![FPGA Top-Level Architecture](images/FPGA.png)
*Figure 3: Complete FPGA top-level architecture showing CLBa, Connector, and CLBb.*

*   **Inputs:** `clk`, `rst_n`, `Ia` (4-bit), `Ib` (4-bit), `bit_stream`, `bit_stream_valid`
*   **Outputs:** `CLBb_O` (1-bit)

## Bitstream Programming Sequence
To configure the FPGA, a serial bitstream is shifted into the device. The `bit_stream_valid` signal acts as an active-high enable for the configuration memory. 

The waveform below demonstrates the loading sequence. Over exactly 38 clock cycles, the 16-bit LUT SRAM, 1-bit MUX SRAM, 4-bit Connector SRAMs, and the second CLB's 17-bit configuration are programmed sequentially.

![Programming Waveform](images/Vivado_waveforms_programing.png)
*Figure 4: Vivado simulation waveform showing the 38-cycle bitstream loading sequence.*

## Verification & Implemented Functions
The design is verified using a self-checking SystemVerilog testbench (`tb_fpga.sv`). The testbench reads the bitstream from `bitstreams.txt`, programs the FPGA, and applies random stimulus. 

The outputs are compared against a behavioral "Golden Model" (`functions.v`). The design successfully implements and verifies the following 5 functions:

1.  **Function 1:** A 4-input truth table (Fully combinational).
2.  **Function 2:** `f = (!a | b) & (c | d)` (Combinational).
3.  **Function 3:** `f = ((a | b) & (!c & d)) ^ e` (Registered output).
4.  **Function 4:** `f = b >= a` (3-bit unsigned comparator, combinational).
5.  **Function 5:** `f = b >= a` (3-bit unsigned comparator, 2-stage pipelined).

![Simulation Waveform](images/Vivado_waveforms.png)
*Figure 5: Overall simulation waveform showing random stimulus application and golden model comparison.*

## Results
The testbench was run for 10,000 randomized test vectors per function. The self-checking mechanism compares the synthesized FPGA output against the behavioral golden model, achieving **100% accuracy** across all test cases.

![Simulation Results](images/Vivado_ouputLog.png)
*Figure 6: Vivado simulation log showing a 100% pass rate (0 failures) for all five implemented functions.*
