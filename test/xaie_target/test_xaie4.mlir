// RUN: aie-translate --aie-generate-xaie %s | FileCheck %s

// Test shared BD list.
// CHECK: XAieDma_TileBdSetLock(&(TileDMAInst[3][3]), {{.*}}0, XAIEDMA_TILE_BD_ADDRA, {{.*}}0, XAIE_ENABLE, {{.*}}0, XAIE_ENABLE, {{.*}}1);
// CHECK: XAieDma_TileBdSetAdrLenMod(&(TileDMAInst[3][3]), {{.*}}0, {{.*}}0x1000, {{.*}}0x0, {{.*}}256 * 4, {{.*}}XAIE_DISABLE, {{.*}}XAIE_DISABLE);
// CHECK: XAieDma_TileBdWrite(&(TileDMAInst[3][3]), {{.*}}0);
// CHECK: XAieDma_TileBdSetLock(&(TileDMAInst[3][3]), {{.*}}1, XAIEDMA_TILE_BD_ADDRA, {{.*}}1, XAIE_ENABLE, {{.*}}0, XAIE_ENABLE, {{.*}}1);
// CHECK: XAieDma_TileBdSetAdrLenMod(&(TileDMAInst[3][3]), {{.*}}1, {{.*}}0x1400, {{.*}}0x0, {{.*}}256 * 4, {{.*}}XAIE_DISABLE, {{.*}}XAIE_DISABLE);
// CHECK: XAieDma_TileBdWrite(&(TileDMAInst[3][3]), {{.*}}1);
// CHECK: XAieDma_TileSetStartBd((&(TileDMAInst[3][3])), XAIEDMA_TILE_CHNUM_MM2S0, {{.*}}0);
// CHECK: XAieDma_TileSetStartBd((&(TileDMAInst[3][3])), XAIEDMA_TILE_CHNUM_S2MM0, {{.*}}1);

module @test_xaie3 {
  %t33 = AIE.tile(3, 3)
  %t44 = AIE.tile(4, 4)

  %buf33_0 = AIE.buffer(%t33) {address = 0x1000} : memref<256xi32>
  %buf33_1 = AIE.buffer(%t33) {address = 0x1400} : memref<256xi32>

  %l33_0 = AIE.lock(%t33, 0)
  %l33_1 = AIE.lock(%t33, 1)

  %m33 = AIE.mem(%t33) {
      %srcDma = AIE.dmaStart("MM2S0", ^bd0, ^dma0)
    ^dma0:
      %destDma = AIE.dmaStart("S2MM0", ^bd1, ^end)
    ^bd0:
      AIE.useLock(%l33_0, "Acquire", 1, 0)
      AIE.dmaBd(<%buf33_0 : memref<256xi32>, 0, 256>, 0)
      AIE.useLock(%l33_0, "Release", 0, 0)
      br ^end
    ^bd1:
      AIE.useLock(%l33_1, "Acquire", 1, 0)
      AIE.dmaBd(<%buf33_1 : memref<256xi32>, 0, 256>, 0)
      AIE.useLock(%l33_1, "Release", 0, 0)
      br ^end
    ^end:
      AIE.end
  }
}
