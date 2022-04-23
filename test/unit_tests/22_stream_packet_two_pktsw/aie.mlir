//===- aie.mlir ------------------------------------------------*- MLIR -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// (c) Copyright 2021 Xilinx Inc.
//
//===----------------------------------------------------------------------===//

// RUN: source %S/../../../settings.sh
// RUN: aiecc.py --sysroot=%VITIS_SYSROOT% --aie-generate-xaiev2 %s -I%aie_runtime_lib% %aie_runtime_lib%/test_library.cpp %S/test.cpp -o test.elf
// RUN: %run_on_board ./test.elf

// many-to-one, then one-to-many (3 streams)
// Two switchboxes with packet-switch mode enabled
module @test22_stream_packet_two_pktsw {
  %t72 = AIE.tile(7, 2)
  %t62 = AIE.tile(6, 2)
  %t71 = AIE.tile(7, 1)
  
  %sw71 = AIE.switchbox(%t71) {
    AIE.connect<"DMA" : 0, "North" : 0>
    AIE.connect<"DMA" : 1, "North" : 1>
  }

  %sw72 = AIE.switchbox(%t72) {
    %a1_m0 = AIE.amsel<1> (0)
    AIE.masterset(West : 3, %a1_m0) { drop_header = false }
    AIE.packetrules(South : 0)  {
      AIE.rule(0x1e, 0, %a1_m0)
    }
    AIE.packetrules(South : 1)  {
      AIE.rule(0x1f, 2, %a1_m0)
    }
  }

  %sw62 = AIE.switchbox(%t62) {
    %a0_m0 = AIE.amsel<0> (0)
    %a0_m1 = AIE.amsel<0> (1)

    AIE.masterset(DMA : 0, %a0_m0)
    AIE.masterset(DMA : 1, %a0_m1)

    AIE.packetrules(East : 3) {
      AIE.rule(0x1e, 0, %a0_m0)
      AIE.rule(0x1f, 2, %a0_m1)
    }
  }

  %buf71_0 = AIE.buffer(%t71) {sym_name = "buf71_0" } : memref<256xi32>
  %buf71_1 = AIE.buffer(%t71) {sym_name = "buf71_1" } : memref<256xi32>
  %buf71_2 = AIE.buffer(%t71) {sym_name = "buf71_2" } : memref<256xi32>

  %l71_0 = AIE.lock(%t71, 0)
  %l71_1 = AIE.lock(%t71, 1)
  %l71_2 = AIE.lock(%t72, 2)

  %m71 = AIE.mem(%t71) {
    AIE.dmaLaunch(^end, ^end, ^bd0, ^bd2)
    ^bd0:
      AIE.useLock(%l71_0, "Acquire", 1)
      AIE.dmaBd(<%buf71_0 : memref<256xi32>, 0, 256>, 0) { pkt_id = 0x0 }
      AIE.useLock(%l71_0, "Release", 0)
      cf.br ^bd1
    ^bd1:
      AIE.useLock(%l71_1, "Acquire", 1)
      AIE.dmaBd(<%buf71_1 : memref<256xi32>, 0, 256>, 0) { pkt_id = 0x1 }
      AIE.useLock(%l71_1, "Release", 0)
      cf.br ^bd0
    ^bd2:
      AIE.useLock(%l71_2, "Acquire", 1)
      AIE.dmaBd(<%buf71_2 : memref<256xi32>, 0, 256>, 0) { pkt_id = 0x2 }
      AIE.useLock(%l71_2, "Release", 0)
      cf.br ^bd2
    ^end:
      AIE.end
  }

  %buf62_0 = AIE.buffer(%t62) {sym_name = "buf62_0" } : memref<512xi32>
  %buf62_1 = AIE.buffer(%t62) {sym_name = "buf62_1" } : memref<256xi32>

  %l62_0 = AIE.lock(%t62, 0)
  %l62_1 = AIE.lock(%t62, 1)

  %m62 = AIE.mem(%t62) {
    AIE.dmaLaunch(^bd0, ^bd1, ^end, ^end)
    ^bd0:
      AIE.useLock(%l62_0, "Acquire", 0)
      AIE.dmaBd(<%buf62_0 : memref<512xi32>, 0, 512>, 0)
      AIE.useLock(%l62_0, "Release", 1)
      cf.br ^bd0
    ^bd1:
      AIE.useLock(%l62_1, "Acquire", 0)
      AIE.dmaBd(<%buf62_1 : memref<256xi32>, 0, 256>, 0)
      AIE.useLock(%l62_1, "Release", 1)
      cf.br ^bd1
    ^end:
      AIE.end
  }  
}
