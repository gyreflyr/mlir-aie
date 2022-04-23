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

//           (7, 2)
//             ^
//             |
// (6, 1) <- (7, 1)
module @test23_stream_packet_partial_multicast {
  %t72 = AIE.tile(7, 2)
  %t61 = AIE.tile(6, 1)
  %t71 = AIE.tile(7, 1)
  
  %sw71 = AIE.switchbox(%t71) {
    %a0_0 = AIE.amsel<0> (0)
    %a0_1 = AIE.amsel<0> (1)

    AIE.masterset(North : 0, %a0_0, %a0_1)
    AIE.masterset(West : 0, %a0_1)

    AIE.packetrules(DMA : 0)  {
      AIE.rule(0x1f, 0, %a0_0)
      AIE.rule(0x1f, 1, %a0_1)
    }
  }

  %sw72 = AIE.switchbox(%t72) {
    AIE.connect<"South" : 0, "DMA" : 0>
  }

  %sw61 = AIE.switchbox(%t61) {
    AIE.connect<"East" : 0, "DMA" : 0>
  }

  %buf71_0 = AIE.buffer(%t71) {sym_name = "buf71_0" } : memref<256xi32>
  %buf71_1 = AIE.buffer(%t71) {sym_name = "buf71_1" } : memref<256xi32>

  %l71_0 = AIE.lock(%t71, 0)
  %l71_1 = AIE.lock(%t71, 1)

  %m71 = AIE.mem(%t71) {
    AIE.dmaLaunch(^end, ^end, ^bd0, ^end)
    ^bd0: // MM2S0
      AIE.useLock(%l71_0, "Acquire", 1)
      AIE.dmaBd(<%buf71_0 : memref<256xi32>, 0, 256>, 0) { pkt_id = 0x1 }
      AIE.useLock(%l71_0, "Release", 0)
      cf.br ^bd1
    ^bd1:
      AIE.useLock(%l71_1, "Acquire", 1)
      AIE.dmaBd(<%buf71_1 : memref<256xi32>, 0, 256>, 0) { pkt_id = 0x0 }
      AIE.useLock(%l71_1, "Release", 0)
      cf.br ^end
    ^end:
      AIE.end
  }

  %buf61 = AIE.buffer(%t61) {sym_name = "buf61" } : memref<256xi32>
  %l61 = AIE.lock(%t61, 0)

  AIE.mem(%t61) {
    AIE.dmaLaunch(^bd0, ^end, ^end, ^end)
    ^bd0:
      AIE.useLock(%l61, "Acquire", 0)
      AIE.dmaBd(<%buf61 : memref<256xi32>, 0, 256>, 0)
      AIE.useLock(%l61, "Release", 1)
      cf.br ^end
    ^end:
      AIE.end
  }

  %buf72 = AIE.buffer(%t72) {sym_name = "buf72" } : memref<512xi32>
  %l72 = AIE.lock(%t72, 0)

  AIE.mem(%t72) {
    AIE.dmaLaunch(^bd0, ^end, ^end, ^end)
    ^bd0:
      AIE.useLock(%l72, "Acquire", 0)
      AIE.dmaBd(<%buf72 : memref<512xi32>, 0, 512>, 0)
      AIE.useLock(%l72, "Release", 1)
      cf.br ^end
    ^end:
      AIE.end
  }  
}
