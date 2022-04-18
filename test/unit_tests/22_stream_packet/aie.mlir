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

// many-to-one, 3 streams
module @test22_stream_packet {
  %t72 = AIE.tile(7, 2)
  %t62 = AIE.tile(6, 2)
  %t71 = AIE.tile(7, 1)
  
  %sw71 = AIE.switchbox(%t71) {
    AIE.connect<"DMA" : 0, "North" : 1>
  }
  %sw72 = AIE.switchbox(%t72) {
    %tmsel = AIE.amsel<1> (0) // <arbiter> (mask). mask is msel_enable
    %tmaster = AIE.masterset(West : 3, %tmsel)
    AIE.packetrules(South : 1)  {
      AIE.rule(0x1e, 0, %tmsel)
    }
  }
  %sw62 = AIE.switchbox(%t62) {
    AIE.connect<"East" : 3, "DMA" : 0>
  }

  %buf71_0 = AIE.buffer(%t71) {sym_name = "buf71_0" } : memref<256xi32>
  %buf71_1 = AIE.buffer(%t71) {sym_name = "buf71_1" } : memref<256xi32>

  %l71_0 = AIE.lock(%t71, 0)
  %l71_1 = AIE.lock(%t71, 1)

  %m71 = AIE.mem(%t71) {
      %srcDma = AIE.dmaStart("MM2S0", ^bd0, ^end)
    ^bd0:
      AIE.useLock(%l71_0, "Acquire", 1)
      AIE.dmaBdPacket(0x4, 0x0) // (pkt_type, pkt_id)
      AIE.dmaBd(<%buf71_0 : memref<256xi32>, 0, 256>, 0)
      AIE.useLock(%l71_0, "Release", 0)
      br ^bd1
    ^bd1:
      AIE.useLock(%l71_1, "Acquire", 1)
      AIE.dmaBdPacket(0x5, 0x1) // (pkt_type, pkt_id)
      AIE.dmaBd(<%buf71_1 : memref<256xi32>, 0, 256>, 0)
      AIE.useLock(%l71_1, "Release", 0)
      br ^end
    ^end:
      AIE.end
  }

  %buf62 = AIE.buffer(%t62) {sym_name = "buf62" } : memref<512xi32>
  %l62 = AIE.lock(%t62, 0)

  %m62 = AIE.mem(%t62) {
      %srcDma0 = AIE.dmaStart("S2MM0", ^bd0, ^end)
    ^bd0:
      AIE.useLock(%l62, "Acquire", 0)
      AIE.dmaBd(<%buf62 : memref<512xi32>, 0, 512>, 0)
      AIE.useLock(%l62, "Release", 1)
      br ^end
    ^end:
      AIE.end
  }  
}
