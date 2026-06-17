# AMBA APB Protocol: RTL \& Testbench

A Verilog implementation of the **AMBA Advanced Peripheral Bus (APB)** protocol, with a single master, a single slave (containing 11 x 32-bit memory), and a self-checking testbench.

\---

## What is APB?

APB is ARM's low-power, low-complexity bus from the AMBA family, intended for accessing slow peripherals (UARTs, timers, GPIO, register banks). Every APB transfer is a deterministic two-phase handshake:

1. **SETUP phase** - `PSEL` goes high, address / data / direction are placed on the bus.
2. **ACCESS phase** - `PENABLE` goes high while `PSEL` and the bus signals stay stable. The slave commits the transfer on the next rising clock edge.

Each transfer therefore takes exactly **2 clock cycles**.

\---

## Repository layout

```
.
├── rtl/
│   ├── apb\_master.v        # APB master FSM (IDLE → SETUP → ACCESS)
│   ├── apb\_slave.v         # APB slave with 11x32-bit internal memory
│   └── apb\_top.v           # Top wrapper connecting master and slave
├── tb/
│   └── tb\_apb\_top.v        # Self-checking testbench (random + linear modes)
├── scripts/
│   └── run.do              # QuestaSim / ModelSim simulation script
├── docs/
│   └── waveform.png        # Reference waveform from a passing run
├── Makefile                # iverilog/vvp build for Linux/macOS users
├── .gitignore
└── README.md
```

\---

## How the modules connect

```
   ┌──────────────┐
   │  tb\_apb\_top  │            (stimulus + self-check)
   └──────┬───────┘
          │  pclk, prst, pwrite, paddressi, pdatai, prdata
   ┌──────▼───────┐
   │   apb\_top    │            (wires master ↔ slave)
   │ ┌──────────┐ │
   │ │apb\_master│─┼─── psel, penable, pwrite, paddress, pwdata ──┐
   │ └──────────┘ │                                              │
   │ ┌──────────┐ │                                              │
   │ │apb\_slave │◄┼──────────────────────────────────────────────┘
   │ └────┬─────┘ │
   │      │ prdata│
   └──────┼───────┘
          ▼
       to TB
```

\---

## Quick start

### Option A - Icarus Verilog (Linux / macOS / WSL)

```bash
make            # compile + run with random stimulus
make linear     # compile + run with fixed data (152, 1002)
make wave       # open VCD in GTKWave
make clean
```

### Option B - QuestaSim / ModelSim

Inside the QuestaSim Transcript window:

```tcl
cd C:/path/to/apb-protocol-verilog/scripts
do run.do
```

Use forward slashes in the path, even on Windows. The script compiles, elaborates, adds all waves, and runs to `$finish`.

\---

## Expected output

```
============================================
     APB PROTOCOL SIMULATION  -  START
============================================
\[45000 ns] SLAVE WRITE: addr=1 data=152  (0x00000098)
\[65000 ns] SLAVE WRITE: addr=2 data=1002 (0x000003ea)
\[110000 ns] READ  PASS: addr=1  prdata=152  (0x00000098)
\[140000 ns] READ  PASS: addr=2  prdata=1002 (0x000003ea)
============================================
  RESULTS: checks=2  errors=0  -> PASS
============================================
```

\---

## Design notes

**State machine (master)**

|State|psel|penable|Description|
|-|-|-|-|
|IDLE|0|0|Bus quiet. Moves to SETUP on next clock.|
|SETUP|1|0|Address/data/direction placed on bus.|
|ACCESS|1|1|Transfer commits on next rising edge.|

**Coding practices**

* ANSI port style and named-port instantiation throughout.
* Synchronous active-high reset.
* Non-blocking (`<=`) in sequential blocks, blocking (`=`) in combinational.
* Default assignments at the top of every combinational `always @(\*)` block to prevent latch inference.
* Localparams for FSM state encoding (no magic numbers).
* Self-checking testbench with a pass/fail summary.

**Known limitations (intentionally left for future iterations)**

* Master FSM has no transfer-request input; once out of reset it generates back-to-back transfers continuously. A production master would gate this on a `transfer\_request` signal from the CPU side.
* `prdata` is registered (valid one cycle after ACCESS) rather than driven combinationally in ACCESS as the spec prefers.
* Slave has a redundant FSM that mirrors the master; not strictly required.

These are the next things to fix as the design evolves.

\---

## What this project demonstrates

* Verilog RTL coding style suitable for synthesis
* Two-process FSM design (sequential state register + combinational next-state/output logic)
* Multi-file project organization (`rtl/`, `tb/`, `scripts/`)
* Self-checking testbench with random and directed modes
* QuestaSim and Icarus Verilog simulation flows

\---

## License

MIT — see [LICENSE](LICENSE).

