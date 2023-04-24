cmake_minimum_required(VERSION 3.26)
project(simulator)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})

set(TARGET SimulatorRV32)
add_executable(${TARGET} main.cpp)
verilate(${TARGET} SOURCES Simulator.v VERILATOR_ARGS --trace)

target_include_directories(${TARGET} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/3rd_party/ELFIO)