# fds-digital-logic

**A digital-logic library in Verilog** — 42 synthesizable modules, each with a
self-checking testbench, covering the whole chain from the logic gate to a processor's
register file.

A personal project built around the course **CS-173 — Fundamentals of Digital Systems**
(EPFL, second year). It is not a graded project: it revisits the course material,
consolidated and taken well beyond the exercises, with systematic verification by
simulation.

> `Verilog-2005` · 42 modules · 42 testbenches · **42/42 passing** · zero `iverilog -Wall` warnings

> **Status:** modules are being added to this repository progressively; the complete
> library has been simulated end to end locally with `run_all.sh`.

---

## Check it yourself

```bash
brew install icarus-verilog     # macOS; otherwise: apt install iverilog
./run_all.sh                    # compiles and simulates every testbench
./run_all.sh counter            # or a subset, by pattern
```

The script exits with a non-zero code if a single testbench fails, so it can be used as-is
in continuous integration.

## What the library covers

### Combinational — `src/combinational/` (24 modules)

**Addition and subtraction.** `half_adder` and `full_adder` (described structurally, by
instantiating gates) are the building blocks of the parameterised `ripple_carry_adder`. The
`carry_lookahead_adder4` computes the same thing with generate `g = a·b` and propagate
`p = a⊕b` signals, bringing the delay down from O(N) to O(log N) — its testbench runs it
**side by side** with a `ripple_carry_adder` to prove functional equivalence over all 512
vectors. The `adder_subtractor` uses the two's-complement identity `a − b = a + ¬b + 1` and
exposes the four flags; its **signed** overflow is checked not with the formula
`carry[N] ⊕ carry[N−1]` but with its definition ("does the exact result fall outside the
representable range?"), so the testbench never checks a formula against itself.

**Selection and decoding.** 2-, 4- and 8-to-1 multiplexers and a generic 2^SEL-to-1
`mux_param`; a demultiplexer; 2→4 and 3→8 decoders, plus a 4→16 decoder built
hierarchically from two 3→8 decoders; a plain encoder and a **priority** encoder.

**Codes and bit manipulation.** A `barrel_shifter` in log2(N) stages of multiplexers
(logical and arithmetic shifts, with the mirroring trick for left shifts),
`binary_to_gray` / `gray_to_binary` conversions, a `parity_checker`, a `bcd_adder` with its
+6 correction, a `seven_segment_decoder`, comparators and `absolute_difference`.

### Sequential — `src/sequential/` (15 modules)

Following the course's progression: latches (`sr_latch` on cross-coupled NOR gates,
level-transparent `d_latch`), then edge-triggered flip-flops (`d_flip_flop` with
synchronous **and** asynchronous reset, `t_flip_flop` and `jk_flip_flop` built by
instantiating a D flip-flop), then the circuits built on them — register, shift register,
up/down and modulo-N counters, a ring counter and its Johnson variant.

Finally, **state machines**: the same `1011` sequence detector implemented as a **Moore**
machine (5 states) and a **Mealy** machine (4 states), to make the difference tangible —
Mealy reacts one cycle earlier with fewer states. Plus a traffic-light controller with
configurable durations and a push-button debouncer.

### Memory — `src/memory/` (3 modules)

`register_file` reproduces an **RV32I** register file: 32 × 32 bits, two asynchronous read
ports, one synchronous write port, and register `x0` hard-wired to zero, writes included.
Completed by a synchronous RAM and a combinational ROM, both parameterised.

## On testbench quality

A passing test proves nothing if it cannot fail. Three principles were applied:

1. **Exhaustive sweeps** wherever the domain allows — the 512 vectors of the 4-bit adder,
   the 4,096 of the 6-bit comparator, the 19,968 of the generic multiplexer, the 16 values
   of the seven-segment decoder.
2. **Independent references**: the expected result is recomputed through a different path
   from the one under test (Verilog integer arithmetic, the `<<` `>>` `>>>` operators,
   glyphs rebuilt segment by segment, Gray↔binary round trips), never copied from the
   module's own logic.
3. **Mutation testing**: faults were deliberately injected into a sample of modules, in
   throwaway copies, to confirm that the corresponding testbench catches them — a
   testbench that stays green on faulty code tests nothing.

## Layout

```
src/combinational/   24 modules
src/sequential/      15 modules
src/memory/           3 modules
tb/                  42 testbenches (one per module)
run_all.sh           compiles and simulates everything
```

Every file carries a header explaining the module's role, its equation or transition
table, and why the circuit exists — the intent is for the repository to read as revision
material, not just as code.

## Context

CS-173 is taught by Prof. Mirjana Stojilović at EPFL. The syllabus covers number systems
(two's complement, Gray and BCD codes, fixed and floating point), logic circuits (Boolean
algebra, fast adders, flip-flops, state machines, memory) and an introduction to computer
architecture (the RV32I instruction set). This repository covers the second block and
starts on the third.
