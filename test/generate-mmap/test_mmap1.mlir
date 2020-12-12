// RUN: aie-translate --aie-generate-mmap %s | FileCheck %s

// CHECK-LABEL: Tile(4, 4)
// CHECK-NOT: _symbol a
// CHECK-LABEL: Tile(2, 4)
// CHECK: _symbol a 0x38000 16
// CHECK-LABEL: Tile(3, 3)
// CHECK: _symbol a 0x30000 16
// CHECK-LABEL: Tile(3, 5)
// CHECK: _symbol a 0x20000 16
// CHECK-LABEL: Tile(3, 4)
// CHECK: _symbol a 0x38000 16

module @test_mmap1 {
  %t34 = AIE.tile(3, 4)
  %t24 = AIE.tile(2, 4) // Different column
  %t44 = AIE.tile(4, 4) // Different column
  %t33 = AIE.tile(3, 3) // Different row
  %t35 = AIE.tile(3, 5) // Different row

  %buf34_0 = AIE.buffer(%t34) { sym_name = "a", address = 0x0 } : memref<4xi32>
}

