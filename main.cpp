#include "VSimulator.h"
#include "VSimulator_MemoryInstruction__N11.h"
#include "VSimulator_MemoryData__N11.h"
#include "VSimulator_RegisterFile.h"
#include "VSimulator_Simulator.h"
#include "VSimulator_PCCounter.h"
#include <verilated_vcd_c.h>

#include <elfio/elfio.hpp>
#include <iomanip>
#include <array>
#include <iostream>

int check_arguments(int argc) {
  if (argc < 2 || argc > 3) {
    std::cout << "Failed input!\n Wrong number of input!" << std::endl;
    return 0;
  }
  return argc - 1;
}

void readELFFile(std::string path, ELFIO::elfio& m_reader, ELFIO::Elf_Half& segment) {
  if (!m_reader.load(path))
    throw std::invalid_argument("Error! Incorrect path to ELF : " + path);
  if (m_reader.get_class() != ELFIO::ELFCLASS32) {
    throw std::runtime_error("Error! ELF file class is wrong!");
  }
  if (m_reader.get_encoding() != ELFIO::ELFDATA2LSB) {
    throw std::runtime_error("Error! Incorrect type of ELF.");
  }
  segment = m_reader.segments.size();
}

void RegfileStr(const uint32_t *registers) {
  std::cout << std::setfill('0');
  constexpr std::size_t lineNum = 8;

  for (std::size_t i = 0; i < lineNum; ++i) {
    for (std::size_t j = 0; j < 32 / lineNum; ++j) {
      auto regIdx = j * lineNum + i;
      auto &reg = registers[regIdx];
      std::cout << "  [" << std::dec << std::setw(2) << regIdx << "] ";
      std::cout << "0x" << std::hex << std::setw(sizeof(reg) * 2) << reg;
    }
    std::cout << std::endl;
  }
}

int main(int argc, char **argv) {
  // Initialize Verilators variables
  Verilated::commandArgs(argc, argv);
  std::string path_to_exec{};
  bool is_trace = false;
  int num_arguments = check_arguments(argc);
  if ( num_arguments == 0 ) {
    std::cout << "Error in args" << std::endl;
    return -1;
  }
  path_to_exec = std::string(argv[1]);
  if ( num_arguments > 1) {
    is_trace = true;
  }
  int inst_counter = 0;
  int tackt = 0;
  auto top_module = std::make_unique<VSimulator>();

  Verilated::traceEverOn(true);
  auto vcd = std::make_unique<VerilatedVcdC>();
  top_module->trace(vcd.get(), 10); // Trace 10 levels of hierarchy
  vcd->open("out.vcd");             // Open the dump file

  ELFIO::elfio m_reader{};
  ELFIO::Elf_Half seg_num{};
  readELFFile(path_to_exec, m_reader, seg_num);
  
  for (size_t seg_i = 0; seg_i < seg_num; ++seg_i) {
    const ELFIO::segment *segment = m_reader.segments[seg_i];
    if (segment->get_type() != ELFIO::PT_LOAD) {
      continue;
    }
    uint32_t address = segment->get_virtual_address();
    if (address >> 17) {
      throw std::runtime_error("Try load ELF to data mem! " + std::to_string(address));
    }
    size_t filesz = static_cast<size_t>(segment->get_file_size());
    size_t memsz = static_cast<size_t>(segment->get_memory_size());
    if (filesz) {
      const auto *begin = reinterpret_cast<const uint8_t *>(segment->get_data());
      uint8_t *dst = reinterpret_cast<uint8_t *>(top_module->Simulator->imem->mem_buff);
      std::copy(begin, begin + filesz, dst + address);
    }
  }

  // init pc
  top_module->Simulator->pc_module->pc = m_reader.get_entry();

  // std::ofstream trace_out(path_to_trace);

  vluint64_t vtime = 0;
  int clock = 0;
  top_module->clk = 0;
  while (!Verilated::gotFinish()) {
    vtime += 1;
    if (vtime % 8 == 0) {
      if (!clock && top_module->valid_out) {
      //clock ^= 1;
        if (is_trace && (std::strcmp(argv[2], "--trace") == 0)) {
          std::cout << "*********************************************************"
                     "**********************"
                  << std::endl;
          std::cout << std::hex << "0x" << (unsigned)top_module->pc_out << ": "
                  << "CMD" << std::dec << " rd = " << (int)top_module->rdn_out
                  << ", rs1 = " << (int)top_module->rs1n_out
                  << ", rs2 = " << (int)top_module->rs2n_out << std::hex
                  << ", imm = 0x" << top_module->imm_out << std::dec
                  << std::endl;

          RegfileStr(top_module->Simulator->reg_file->registers);
        } else if (is_trace && (std::strcmp(argv[2], "--traceInstr") == 0)) {
          std::cout << "***********************************\n";
            std::cout << "TAKT: " << std::dec << tackt << std::endl;
            std::cout << "NUM: " << std::dec << inst_counter++ << std::endl;
            std::cout << "PC : "
                      << "0x" << std::hex << (unsigned)top_module->pc_out
                      << std::endl;
            if (top_module->RegWrite_out && top_module->rdn_out != 0) {
              std::cout
                << "X" << std::dec << (int)top_module->rdn_out << " = 0x"
                << std::hex
                << top_module->Simulator->reg_file->registers[top_module->rdn_out]
                << std::endl;
            }
        }
      } 
      if (top_module->bit_exit & (top_module->clk == 0)) {
        std::cout << "Success!" << std::endl;
        break;
      }
      clock ^= 1;
      tackt += clock;
    }
    top_module->clk = clock;
    top_module->eval();
    vcd->dump(vtime);
  }

  top_module->final();
  vcd->close();

  return 0;
}
