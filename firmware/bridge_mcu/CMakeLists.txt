cmake_minimum_required(VERSION 3.13)

# Pull in SDK (e.g. Raspberry Pi Pico SDK if targeting RP2040 companion bridge)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

project(pulsewave_bridge C CXX ASM)

add_executable(pulsewave_bridge
    src/main.c
)

target_include_directories(pulsewave_bridge PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/src
)

# Compilation flags
target_compile_options(pulsewave_bridge PRIVATE
    -Wall
    -Wextra
    -O3
)
