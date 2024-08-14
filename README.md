# Formally Verified Hamming Encoder Decoder
Click on the image(s) to view the full image.

  ![Waveform of trace of witness cover for zero message with no error, opened in GTKWave](https://github.com/ShashankVM/hamming_encoder_decoder/blob/main/no_error_inject.png)

  ![Waveform of trace of witness cover for 2 different non-zero messages with different error positions, opened in GTKWave](https://github.com/ShashankVM/hamming_encoder_decoder/blob/main/2_non_zero_message_with_different_error_pos.png)
TODO:
Implement a simple sticky bit and simplify the logic.

- A formally verified (7,4) cyclic encoder and decoder implementing the Hamming code.
- Capable of correcting single bit errors in a codeword of 7 bits.
- Capable of detecting all double bit errors.
- Encoder output and decoder input is in Bit serial fashion, to support high speeds.
- High Throughput decoder capable of producing an output on every input, designed using time division multiplexing of 2 Meggitt decoders.
- Simple Ready Valid protocol to synchronize encoder and decoder operation.
- **Tools & Technologies:** SystemVerilog, SystemVerilog Assertions, Yosys, Tabby CAD Suite
- **Results:** Assertions passing using both Bounded Model Checking and Full Proof. Covers were written to visualize the cycles of operation.
- **Files & Directories:**
   * dut.sv: Top level module.
   * tb.sv: Testbench instantiating Design Under Test (DUT) and assertion checker module.
   * properties.sva: SystemVerilog Assertion file containing properties, assertions, assumptions and covers.
   * bindings.sva: SystemVerilog Bind file for binding assertion module to DUT.
   * piso.sv: Parameterized Parallel In Serial Out.
   * lfsr_encoder.sv: 3 bit Linear Feedback Shift Register, encoder variant
   * lfsr_decoder.sv: 3 bit Linear Feedback Shift Register, decoder variant
   * channel.sv: channel model
   * cc_encoder.sv: (7,4) Cyclic encoder
   * cc_decoder.sv: (7,4) Cyclic decoder
   * cc_decoder_ht.sv: High throughput cyclic decoder
   * buffer_reg.sv: Parameterized buffer register, with serial to parallel conversion functionality.
   * hamming_encoder_decoder.sby: SBY file for setup of Yosys SBY Formal tool.
   * hamming_encoder_decoder_bmc: Output directory for Bounded Model Checking.
   * hamming_encoder_decoder_prove: Output directory for full proof.
   * hamming_encoder_decoder_witness: Output directory for witness cover.

## Design blocks Description:

### Encoder
- ready signal is high on the first cycle of operation.
- valid is high on every cycle of operation.
- Encoder output is bit serial, so that it can be used for transmitting data over a channel at high speeds.
- It uses a Parallel-In-Serial-Out to output data serially, on every cycle.
- Linear Feedback Shift register is used to compute the syndrome.
- A Finite State Machine is used to control its operation.

#### Encoder Finite State Machine Description:
- MESSAGE_0: first cycle of reading message first bit; syndrome calculation
- MESSAGE_1: second cycle of reading message second bit; syndrome calculation
- MESSAGE_2: third cycle of reading message third bit; syndrome calculation
- MESSAGE_3: fourth cycle of reading message fourth bit; syndrome calculation
- SYNDROME_0: Output syndrome first bit
- SYNDROME_1: Output syndrome second bit
- SYNDROME_2: Output syndrome third bit


### Decoder
- valid from encoder is connected to the decoder as an input. This is used to control state transition only if the valid input is High.
- Valid output is high on the 8th cycle of operation, after any 1 bit errors are corrected.
- Syndrome is computed using a Linear Feedback Shift register.
- Combinational circuit is used to compute the position of the error from the generated Syndrome.
- It uses a serial input, so that it can be used for receiving data over a channel at high speeds.
- Output is converted to parallel format using a buffer register.
- A Finite State Machine is used to control its operation.

#### Decoder Finite State Machine Description:
- SYNDROME_CALC0, SYNDROME_CALC1, SYNDROME_CALC2, SYNDROME_CALC3, SYNDROME_CALC4, SYNDROME_CALC5, SYNDROME_CALC6: 7 cycles of syndrome calculation
- ERROR_CORRECTION: calculate corrected data if single error detected.


### High Throughput Decoder
- High Throughput decoder capable of producing an output on every input is constructed using 2 decoders.
- A Finite State Machine is used to control its operation.

#### High Throughput Decoder Finite State Machine Description:
- DECODER_1_CALC_0: first cycle of decoder 1; error correction and output of decoder 2.
- DECODER_1_CALC_1: second cycle of decoder 1; reset decoder 2.
- DECODER_1_CALC_2: third cycle of decoder 1.
- DECODER_1_CALC_3: fourth cycle of decoder 1.
- DECODER_1_CALC_4: fifth cycle of decoder 1.
- DECODER_1_CALC_5: sixth cycle of decoder 1.
- DECODER_1_CALC_6: seventh cycle of decoder 1.
- DECODER_1_OUTPUT: error correction and output of decoder 1; first cycle of decoder 2
- DECODER_1_RESET : reset decoder 1. second cycle of decoder 2.
- DECODER_2_CALC_2: third cycle of decoder 2.
- DECODER_2_CALC_3: fourth cycle of decoder 2.
- DECODER_2_CALC_4: fifth cycle of decoder 2.
- DECODER_2_CALC_5: sixth cycle of decoder 2.
- DECODER_2_CALC_6: seventh cycle of decoder 2.

### Channel
- Model of a bit serial channel with Bit error rate = 1 Bit Error in a 7 bit codeword
- Double bit errors are also possible.
- Error injection can be turned off.

### Properties & Covers
- Stability assumptions to ensure message, error_inject, error_pos1 and error_pos2 do not transition in the middle of a cycle of operation.
- Constraints to ensure error positions do not exceed the maximum possible value.
- Assertion to check if the decoder produces a valid output on every cycle that encoder produces a valid output.
- Assertion to check if transmitted and received data are matching on every cycle decoder output is valid, for upto 1 bit errors.
- Assertion to check every error injected is detected on the error_det signal.
- Covers for checking 1 cycle of operation with and without error, for single bit and double bit errors.
- Cover to check decoder produces a valid output when error is injected. To catch any vacuous passes.
- Cover to check that single error is injected on 2 cycles of operation at 2 different positions, with different non-zero messages.

## FPGA implementation
- Mapping
SW[3:0] -> message[3:0]
SW[15] ->reset
SW[6:4] -> error_pos1[2:0]
SW[9:7] -> error_pos2[2:0]
SW[10]   -> error_inject

LED[6:0] -> RX[6:0]
LED[13:7] -> TX[6:0]
LED[14]   -> rx_valid
LED[15]   -> error_det

## Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_35 Sch=gclk[100]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

## Switches
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { message[0] }]; #IO_L24N_T3_RS0_15 Sch=sw[0]
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { message[1] }]; #IO_L3N_T0_DQS_EMCCLK_14 Sch=sw[1]
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { message[2] }]; #IO_L6N_T0_D08_VREF_14 Sch=sw[2]
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { message[3] }]; #IO_L13N_T2_MRCC_14 Sch=sw[3]
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { error_pos1[0] }]; #IO_L12N_T1_MRCC_14 Sch=sw[4]
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { error_pos1[1] }]; #IO_L7N_T1_D10_14 Sch=sw[5]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { error_pos1[2] }]; #IO_L17N_T2_A13_D29_14 Sch=sw[6]
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { error_pos2[0] }]; #IO_L5N_T0_D07_14 Sch=sw[7]
set_property -dict { PACKAGE_PIN T8    IOSTANDARD LVCMOS18 } [get_ports { error_pos2[1] }]; #IO_L24N_T3_34 Sch=sw[8]
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS18 } [get_ports { error_pos2[2] }]; #IO_25_34 Sch=sw[9]
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { error_inject }]; #IO_L15P_T2_DQS_RDWR_B_14 Sch=sw[10]
# set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports { SW[11] }]; #IO_L23P_T3_A03_D19_14 Sch=sw[11]
# set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports { SW[12] }]; #IO_L24P_T3_35 Sch=sw[12]
# set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { SW[13] }]; #IO_L20P_T3_A08_D24_14 Sch=sw[13]
# set_property -dict { PACKAGE_PIN U11   IOSTANDARD LVCMOS33 } [get_ports { SW[14] }]; #IO_L19N_T3_A09_D25_VREF_14 Sch=sw[14]
set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports { reset }]; #IO_L21P_T3_DQS_14 Sch=sw[15]

## Formal Verification

Run command:
`ebmc -D FORMAL --bound 100 --top dut dut.sv cc_encoder.sv piso.sv lfsr_encoder.sv cc_decoder_ht.sv lfsr_decoder.sv buffer_reg.sv error_correction_and_detection.sv channel.sv --reset reset==1 --vcd wave.vcd`
