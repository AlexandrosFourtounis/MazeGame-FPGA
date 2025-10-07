# Maze Game - FPGA Implementation

A VGA-based maze navigation game implemented on the Xilinx ZedBoard FPGA. This project was developed as part of the CS220 Digital Circuits Lab at the University of Crete.

## Table of Contents
- [Overview](#overview)
- [Hardware Requirements](#hardware-requirements)
- [Features](#features)
- [Project Structure](#project-structure)
- [Module Descriptions](#module-descriptions)
- [Game Controls](#game-controls)
- [FSM States](#fsm-states)
- [Building and Running](#building-and-running)
- [I/O Interface](#io-interface)

## Overview

This project implements a maze navigation game displayed on a VGA monitor. The player navigates through a maze using button inputs, avoiding walls and trying to reach the exit. The game includes:
- Real-time VGA output at 640x480 @ 60Hz
- Player sprite with collision detection
- Visual feedback via LEDs showing game state
- Progress bar timer
- Start/reset controls

## Hardware Requirements

- **FPGA Board**: Xilinx ZedBoard (Zynq-7000)
- **Display**: VGA monitor (640x480 @ 60Hz)
- **Clock**: 100 MHz input clock (converted to 25 MHz for VGA)

## Features

- **VGA Graphics**: 640x480 resolution at 60Hz refresh rate
- **Sprite System**: 16x16 pixel sprites for player and exit
- **Maze Rendering**: 64x64 block-based maze loaded from ROM
- **Collision Detection**: Real-time wall detection using pixel color checking
- **Button Debouncing**: Hardware debouncing for reliable input
- **Timer**: Progress bar indicating time remaining
- **State Display**: LED output showing current FSM state

## Project Structure

```
lab3_code/
├── src/                      # Source files
│   ├── vga_maze_top.sv      # Top-level module
│   ├── vga_sync.sv          # VGA timing generator
│   ├── vga_frame.sv         # Frame rendering logic
│   ├── maze_controller.sv   # Game FSM and logic
│   ├── debouncer.sv         # Button debouncing
│   ├── rom.sv               # Single-port ROM
│   ├── rom_dp.sv            # Dual-port ROM
│   ├── vga_tb.sv            # Testbench
│   └── roms/                # ROM initialization files
│       ├── maze1.rom        # Maze layout data
│       ├── player.rom       # Player sprite
│       └── exit.rom         # Exit sprite
├── fpga/
│   └── lab3.xdc             # Constraints file (pin mappings)
├── run/
│   └── Makefile             # Build automation
└── ref/
    └── vga-simulator/       # VGA simulation tools
```

## Module Descriptions

### vga_maze_top
Top-level module that instantiates and connects all submodules:
- Clock generation (25 MHz from 100 MHz)
- Button debouncers for all inputs
- VGA sync generator
- Frame renderer
- Maze controller (game logic)
- Progress bar timer

### vga_sync
Generates VGA timing signals for 640x480 @ 60Hz:
- Horizontal sync (HSYNC)
- Vertical sync (VSYNC)
- Pixel valid signal
- Current column/row coordinates

**Timing Parameters:**
- H-Sync Pulse: 96 clocks
- H-Back Porch: 48 clocks
- H-Active: 640 clocks
- H-Front Porch: 16 clocks
- V-Sync Pulse: 2 lines
- V-Back Porch: 29 lines
- V-Active: 480 lines
- V-Front Porch: 10 lines

### vga_frame
Renders each video frame by:
- Reading maze data from dual-port ROM
- Overlaying player sprite at current position
- Overlaying exit sprite at fixed position (37, 22)
- Drawing progress bar timer at bottom
- Handling sprite priority (player > exit > maze)

**Block-based rendering:**
- Screen divided into 16x16 pixel blocks
- 64x64 blocks total (40x30 visible)
- Each block addressed by row/column coordinates

### maze_controller
Implements game logic as a finite state machine:
- Processes button inputs (debounced)
- Validates player movements against walls
- Detects exit condition
- Outputs current position and state to LEDs
- Reads maze pixel data to check collision

**Collision Detection:**
- White pixels (0xFFF): Walkable paths
- Black pixels (0x000): Walls
- Green pixels (0x241): Grass (boundary)

### debouncer
Hardware debouncer for push buttons:
- Configurable cycle count
- Single pulse output per button press
- Eliminates mechanical bounce effects
- Default: 25M cycles (~0.25s @ 100MHz) for hardware
- Simulation: 1000 cycles for faster testing

### ROM Modules
- **rom.sv**: Single-port ROM for sprite data
- **rom_dp.sv**: Dual-port ROM for maze data
  - Port A: VGA frame reading
  - Port B: Controller pixel checking
- Initialized from .rom files (hexadecimal format)

## Game Controls

| Button | Function |
|--------|----------|
| BTNC (Control) | Press 3 times to start game, Press to reset after game over |
| BTNU (Up) | Move player up |
| BTND (Down) | Move player down |
| BTNL (Left) | Move player left |
| BTNR (Right) | Move player right |
| SW0 | Reset |

## FSM States

The maze controller operates with the following states:

| State | Value | Description |
|-------|-------|-------------|
| IDLE | 0x0 | Waiting for start (3 control button presses) |
| PLAY | 0x1 | Active gameplay, waiting for movement input |
| UP | 0x2 | Processing upward movement |
| DOWN | 0x3 | Processing downward movement |
| LEFT | 0x4 | Processing leftward movement |
| RIGHT | 0x5 | Processing rightward movement |
| READROM | 0x6 | Reading maze data for collision check |
| CHECK | 0x7 | Checking if move is valid (wall detection) |
| UPDATE | 0x8 | Updating player position after valid move |
| ENDD | 0x9 | Game over (exit reached or timeout) |
| CTRL | 0xA | Counting control button presses |

**Movement Validation Flow:**
1. Player input (UP/DOWN/LEFT/RIGHT) → Calculate new position
2. READROM → Read pixel color at new position from maze ROM
3. CHECK → Verify if white (walkable)
4. UPDATE → Move player if valid, or return to PLAY if wall/grass

## Building and Running

### Simulation
```bash
cd run
make sim          # Run simulation
make check        # Compare output with reference
```

### FPGA Synthesis
```bash
cd run
make synth        # Synthesize design
make impl         # Implement design
make bitstream    # Generate bitstream
```

### Programming FPGA
```bash
make program      # Program the ZedBoard
```

**Note:** Update ROM file paths in `vga_frame.sv` to match your system before synthesis.

## I/O Interface

### Inputs
| Signal | Width | Description | FPGA Pin |
|--------|-------|-------------|----------|
| clk | 1 | 100 MHz system clock | Y9 (GCLK) |
| rst | 1 | Active-high reset | F22 (SW0) |
| i_control | 1 | Control/start button | P16 (BTNC) |
| i_up | 1 | Up movement button | T18 (BTNU) |
| i_down | 1 | Down movement button | R16 (BTND) |
| i_left | 1 | Left movement button | N15 (BTNL) |
| i_right | 1 | Right movement button | R18 (BTNR) |

### Outputs
| Signal | Width | Description | FPGA Pins |
|--------|-------|-------------|-----------|
| o_leds | 8 | FSM state display | T22-U14 (LD0-LD7) |
| o_hsync | 1 | VGA horizontal sync | AA19 |
| o_vsync | 1 | VGA vertical sync | Y19 |
| o_red | 4 | VGA red channel | V20-V18 |
| o_green | 4 | VGA green channel | AB22-AA21 |
| o_blue | 4 | VGA blue channel | Y21-AB19 |

### Color Format
- 12-bit RGB (4 bits per channel)
- Format: 0xRGB where R, G, B are 4-bit hex values
- Example: 0xFFF = white, 0x000 = black, 0xF00 = red

## Authors

- **Course**: CS220 Digital Circuits Lab
- **Institution**: Computer Science Department, University of Crete
- **Instructors**: CS220 Instructors
- **Student Implementation**: Alexandros Fourtounis
- **Date**: 2024

## License

Educational project for CS220 Digital Circuits Lab course.
