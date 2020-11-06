// RUN: aie-translate --aie-generate-xaie %s | FileCheck %s

// CHECK: mlir_configure_cores
// CHECK: XAieTile_CoreControl(&(TileInst[3][3]), XAIE_DISABLE, XAIE_ENABLE);
// CHECK: XAieGbl_LoadElf(&(TileInst[3][3]), "test.elf", XAIE_ENABLE);
// CHECK: mlir_start_cores
// CHECK: XAieTile_CoreControl(&(TileInst[3][3]), XAIE_ENABLE, XAIE_DISABLE);
module @test_xaie0 {
  %t33 = AIE.tile(3, 3)
  AIE.core(%t33) {
    AIE.end
  } { elf_file = "test.elf" } 
}
