cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

project(ponyc_crt LANGUAGES C)

if(DEFINED PONY_USE_OS_LLVM AND PONY_USE_OS_LLVM)

# TODO: support all possible paths
set(CRT_SRC_DIR /lib64/clang/22/lib/linux)

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/crtbeginS.o
    COMMAND ${CMAKE_COMMAND} -E copy ${CRT_SRC_DIR}/clang_rt.crtbegin-x86_64.o ${CMAKE_CURRENT_BINARY_DIR}/crtbeginS.o
    DEPENDS ${CRT_SRC_DIR}/clang_rt.crtbegin-x86_64.o
    COMMENT "Copying clang_rt.crtbegin-x86_64.o to crtbeginS.o")

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/crtendS.o
    COMMAND ${CMAKE_COMMAND} -E copy ${CRT_SRC_DIR}/clang_rt.crtend-x86_64.o ${CMAKE_CURRENT_BINARY_DIR}/crtendS.o
    DEPENDS ${CRT_SRC_DIR}/clang_rt.crtend-x86_64.o
    COMMENT "Copying clang_rt.crtend-x86_64.o to crtendS.o")

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/crtbeginT.o
    COMMAND ${CMAKE_COMMAND} -E copy ${CRT_SRC_DIR}/clang_rt.crtbegin-x86_64.o ${CMAKE_CURRENT_BINARY_DIR}/crtbeginT.o
    DEPENDS ${CRT_SRC_DIR}/clang_rt.crtbegin-x86_64.o
    COMMENT "Copying clang_rt.crtbegin-x86_64.o to crtbeginT.o")

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/crtend.o
    COMMAND ${CMAKE_COMMAND} -E copy ${CRT_SRC_DIR}/clang_rt.crtend-x86_64.o ${CMAKE_CURRENT_BINARY_DIR}/crtend.o
    DEPENDS ${CRT_SRC_DIR}/clang_rt.crtend-x86_64.o
    COMMENT "Copying clang_rt.crtend-x86_64.o to crtend.o")

else()

set(CRT_SRC_DIR ${CMAKE_SOURCE_DIR}/lib/llvm/src/compiler-rt/lib/builtins)
set(CRT_COMMON_FLAGS -DCRT_HAS_INITFINI_ARRAY -DEH_USE_FRAME_REGISTRY)

# PIE/shared variants (for dynamic linking — the default)
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/crtbeginS.o
    COMMAND ${CMAKE_C_COMPILER} -c ${PONY_PIC_FLAG} ${CRT_COMMON_FLAGS}
        -o ${CMAKE_CURRENT_BINARY_DIR}/crtbeginS.o
        ${CRT_SRC_DIR}/crtbegin.c
    DEPENDS ${CRT_SRC_DIR}/crtbegin.c
    COMMENT "Compiling crtbeginS.o (PIC)")

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/crtendS.o
    COMMAND ${CMAKE_C_COMPILER} -c ${PONY_PIC_FLAG} ${CRT_COMMON_FLAGS}
        -o ${CMAKE_CURRENT_BINARY_DIR}/crtendS.o
        ${CRT_SRC_DIR}/crtend.c
    DEPENDS ${CRT_SRC_DIR}/crtend.c
    COMMENT "Compiling crtendS.o (PIC)")

# Static variants (for --static linking)
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/crtbeginT.o
    COMMAND ${CMAKE_C_COMPILER} -c ${CRT_COMMON_FLAGS}
        -o ${CMAKE_CURRENT_BINARY_DIR}/crtbeginT.o
        ${CRT_SRC_DIR}/crtbegin.c
    DEPENDS ${CRT_SRC_DIR}/crtbegin.c
    COMMENT "Compiling crtbeginT.o (static)")

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/crtend.o
    COMMAND ${CMAKE_C_COMPILER} -c ${CRT_COMMON_FLAGS}
        -o ${CMAKE_CURRENT_BINARY_DIR}/crtend.o
        ${CRT_SRC_DIR}/crtend.c
    DEPENDS ${CRT_SRC_DIR}/crtend.c
    COMMENT "Compiling crtend.o (static)")

endif()

add_custom_target(crt_objects ALL
    DEPENDS
        ${CMAKE_CURRENT_BINARY_DIR}/crtbeginS.o
        ${CMAKE_CURRENT_BINARY_DIR}/crtendS.o
        ${CMAKE_CURRENT_BINARY_DIR}/crtbeginT.o
        ${CMAKE_CURRENT_BINARY_DIR}/crtend.o)

# Copy to output directory alongside libponyrt.
set(CRT_FILES
    ${CMAKE_CURRENT_BINARY_DIR}/crtbeginS.o
    ${CMAKE_CURRENT_BINARY_DIR}/crtendS.o
    ${CMAKE_CURRENT_BINARY_DIR}/crtbeginT.o
    ${CMAKE_CURRENT_BINARY_DIR}/crtend.o)

foreach(CRT_FILE ${CRT_FILES})
    add_custom_command(TARGET crt_objects POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy ${CRT_FILE} ${PONY_OUTPUT_DIR}/
    )
endforeach()

# ponyc links these CRT objects into every binary it produces on Linux, so they
# must be built before ponyc is used to build the self-hosted tools and tests.
# Order crt_objects ahead of ponyc; without this the build order is incidental and
# a ponyc-built target (e.g. pony-compiler-tests) can link before crt_objects
# finishes, failing with "could not find compiler-rt CRT objects". Everything
# ponyc builds depends on the ponyc target, so ordering it here covers them all.
# Guarded because the cross-libponyrt build has no ponyc target.
if(TARGET ponyc)
    add_dependencies(ponyc crt_objects)
endif()
