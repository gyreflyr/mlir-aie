//===- test.cpp -------------------------------------------------*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// (c) Copyright 2020 Xilinx Inc.
//
//===----------------------------------------------------------------------===//

#include <cassert>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <thread>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <xaiengine.h>
#include "test_library.h"

#define LOCK_TIMEOUT 100

#include "aie_inc.cpp"

int main(int argc, char *argv[])
{
  aie_libxaie_ctx_t *_xaie = mlir_aie_init_libxaie();
  mlir_aie_init_device(_xaie);
  mlir_aie_clear_all_configs(_xaie);

  mlir_aie_configure_cores(_xaie);

  mlir_aie_configure_switchboxes(_xaie);
  mlir_aie_initialize_locks(_xaie);
  mlir_aie_configure_dmas(_xaie);

  usleep(10000);

  uint32_t bd_ctrl, bd_pckt;
  bd_ctrl = mlir_aie_read32(_xaie, mlir_aie_get_tile_addr(_xaie, 7, 1) + 0x0001D018);
  bd_pckt = mlir_aie_read32(_xaie, mlir_aie_get_tile_addr(_xaie, 7, 1) + 0x0001D010);
  printf("BD0_71: pckt: %x, ctrl: %x \n", bd_pckt, bd_ctrl);

  int count = 256;

  // We're going to stamp over the memory
  for (int i=0; i<count; i++) {
    mlir_aie_write_buffer_buf71_0(_xaie, i, 71);
    mlir_aie_write_buffer_buf71_1(_xaie, i, 71 * 2);
    mlir_aie_write_buffer_buf71_2(_xaie, i, 71 * 3);
    mlir_aie_write_buffer_buf62_0(_xaie, i, 1);
    mlir_aie_write_buffer_buf62_1(_xaie, i + count, 1);
    mlir_aie_write_buffer_buf62_1(_xaie, i, 1);
  }

  usleep(10000);

  mlir_aie_release_lock(_xaie, 7, 1, 0, 1, 0); // Release lock
  mlir_aie_release_lock(_xaie, 7, 1, 1, 1, 0); // Release lock
  mlir_aie_release_lock(_xaie, 7, 1, 2, 1, 0); // Release lock

  if (!mlir_aie_acquire_lock(_xaie, 6, 2, 0, 1, LOCK_TIMEOUT)) {
    printf("ERROR: trying to acquire lock(6, 2)[0] -- timeout hit!\n");
  }
  if (!mlir_aie_acquire_lock(_xaie, 6, 2, 1, 1, LOCK_TIMEOUT)) {
    printf("ERROR: trying to acquire lock(6, 2)[1] -- timeout hit!\n");
  }

  int errors = 0;
  for (int i=0; i<count; i++) {
    if (mlir_aie_read_buffer_buf62_0(_xaie, i) != 71) {
      printf("buf62_0[%d] mismatched: %d, expect 71\n",
        i, mlir_aie_read_buffer_buf62_0(_xaie, i));
      errors++;
    }
    if (mlir_aie_read_buffer_buf62_0(_xaie, i + count) != 71 * 2) {
      printf("buf62_0[%d] mismatched: %d, expect %d\n",
        i + count, mlir_aie_read_buffer_buf62_0(_xaie, i + count), 71 * 2);
      errors++;
    }
    if (mlir_aie_read_buffer_buf62_1(_xaie, i) != 71 * 3) {
      printf("buf62_1[%d] mismatched: %d, expect %d\n",
        i, mlir_aie_read_buffer_buf62_1(_xaie, i), 71 * 3);
      errors++;
    }
  }

  int res = 0;
  if (!errors) {
    printf("PASS!\n");
    res = 0;
  } else {
    printf("Failed! Num. errors: %d\n", errors);
    res = -1;
  }
  mlir_aie_deinit_libxaie(_xaie);

  printf("test done.\n");
  return res;
}
