set(INSTALL_BIN_DIR "${CMAKE_INSTALL_PREFIX}/bin" CACHE PATH "Installation directory for executables")
set(INSTALL_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib" CACHE PATH "Installation directory for libraries")
set(INSTALL_INC_DIR "${CMAKE_INSTALL_PREFIX}/include" CACHE PATH "Installation directory for headers")

add_library(zstd
    "lib/decompress/zstd_ddict.c"
    "lib/decompress/zstd_decompress.c"
    "lib/decompress/huf_decompress.c"
    "lib/decompress/huf_decompress_amd64.S"
    "lib/decompress/zstd_decompress_block.c"
    "lib/compress/zstdmt_compress.c"
    "lib/compress/zstd_opt.c"
    "lib/compress/hist.c"
    "lib/compress/zstd_ldm.c"
    "lib/compress/zstd_fast.c"
    "lib/compress/zstd_compress_literals.c"
    "lib/compress/zstd_double_fast.c"
    "lib/compress/huf_compress.c"
    "lib/compress/fse_compress.c"
    "lib/compress/zstd_lazy.c"
    "lib/compress/zstd_compress.c"
    "lib/compress/zstd_compress_sequences.c"
    "lib/compress/zstd_compress_superblock.c"
    "lib/deprecated/zbuff_compress.c"
    "lib/deprecated/zbuff_decompress.c"
    "lib/deprecated/zbuff_common.c"
    "lib/common/entropy_common.c"
    "lib/common/pool.c"
    "lib/common/threading.c"
    "lib/common/zstd_common.c"
    "lib/common/xxhash.c"
    "lib/common/debug.c"
    "lib/common/fse_decompress.c"
    "lib/common/error_private.c"
    "lib/dictBuilder/zdict.c"
    "lib/dictBuilder/divsufsort.c"
    "lib/dictBuilder/fastcover.c"
    "lib/dictBuilder/cover.c"
)

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL )
    install(TARGETS zstd
        RUNTIME DESTINATION "${INSTALL_BIN_DIR}"
        ARCHIVE DESTINATION "${INSTALL_LIB_DIR}"
        LIBRARY DESTINATION "${INSTALL_LIB_DIR}" )
endif()
if(NOT SKIP_INSTALL_HEADERS AND NOT SKIP_INSTALL_ALL )
    install(FILES "lib/zstd.h" DESTINATION "${INSTALL_INC_DIR}")
endif()
