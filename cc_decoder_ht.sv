module cc_decoder_ht(
  input logic clk,
             reset,
             code_in,
             valid_in,
  output logic valid_out,
                error_det,
  output logic [6:0] code_out);

  logic code_in_1, code_in_2,
        valid_code_in, clear_1, clear_2, error_det_signal, sticky_bit;

  logic [6:0] buffer_out;

  logic [2:0] syndrome_val, syndrome_val_1, syndrome_val_2;

  enum logic [3:0] {DECODER_1_CALC_0, DECODER_1_CALC_1, DECODER_1_CALC_2, DECODER_1_CALC_3, DECODER_1_CALC_4, DECODER_1_CALC_5, DECODER_1_CALC_6, DECODER_1_OUTPUT, DECODER_1_CLEAR, DECODER_2_CALC_2, DECODER_2_CALC_3, DECODER_2_CALC_4, DECODER_2_CALC_5, DECODER_2_CALC_6} state, next;

  lfsr_decoder lfsr_decoder_1( .clk(clk), .reset(reset), .lfsr_in(code_in_1), .clear(clear_1), .q(syndrome_val_1) );

  lfsr_decoder lfsr_decoder_2( .clk(clk), .reset(reset), .lfsr_in(code_in_2), .clear(clear_2),  .q(syndrome_val_2) );

  buffer_reg #(7) buffer_inst(.clk(clk), .reset(reset), .enable(valid_in), .buffer_in(code_in), .buffer_out(buffer_out));

  error_correction_and_detection error_correction_and_detection_inst(.syndrome_val(syndrome_val), .code_in(buffer_out), .code_out(code_out), .error_det(error_det_signal));

  // state register
  always_ff @(posedge clk or posedge reset)
    if (reset) state <= DECODER_1_CALC_0;
    else       state <= next;

  // sticky_bit
  always_ff @(posedge clk or posedge reset)
    if (reset)                            sticky_bit <= 1'b0;
    else if (state == DECODER_1_OUTPUT)   sticky_bit <= 1'b1;

  // next_state_assignment logic
  always_comb begin
    next = state;
    unique case (state)
      DECODER_1_CALC_0 : next = DECODER_1_CALC_1;
      DECODER_1_CALC_1 : next = DECODER_1_CALC_2;
      DECODER_1_CALC_2 : next = DECODER_1_CALC_3;
      DECODER_1_CALC_3 : next = DECODER_1_CALC_4;
      DECODER_1_CALC_4 : next = DECODER_1_CALC_5;
      DECODER_1_CALC_5 : next = DECODER_1_CALC_6;
      DECODER_1_CALC_6 : next = DECODER_1_OUTPUT;
      DECODER_1_OUTPUT : next = DECODER_1_CLEAR;
      DECODER_1_CLEAR  : next = DECODER_2_CALC_2;
      DECODER_2_CALC_2 : next = DECODER_2_CALC_3;
      DECODER_2_CALC_3 : next = DECODER_2_CALC_4;
      DECODER_2_CALC_4 : next = DECODER_2_CALC_5;
      DECODER_2_CALC_5 : next = DECODER_2_CALC_6;
      DECODER_2_CALC_6 : next = DECODER_1_CALC_0;
    endcase
  end

  // Decoder switching logic
  always_comb begin
    valid_code_in = valid_in & code_in;
    unique case (state)
       DECODER_1_CALC_0: begin
                           code_in_1 = valid_code_in;
                           code_in_2   = 1'b0;
                           syndrome_val = syndrome_val_2;
                         end
       DECODER_1_CALC_1, DECODER_1_CALC_2, DECODER_1_CALC_3, DECODER_1_CALC_4, DECODER_1_CALC_5, DECODER_1_CALC_6: begin
                           code_in_1 = valid_code_in;
                           code_in_2   = 1'b0;
                           syndrome_val = syndrome_val_1;
                         end
       DECODER_1_OUTPUT: begin
                           code_in_1    = 1'b0;
                           code_in_2    = valid_code_in;
                           syndrome_val = syndrome_val_1;
                         end
       DECODER_1_CLEAR, DECODER_2_CALC_2, DECODER_2_CALC_3, DECODER_2_CALC_4, DECODER_2_CALC_5, DECODER_2_CALC_6: begin
                           code_in_1   = 1'b0;
                           code_in_2   = valid_code_in;
                           syndrome_val = syndrome_val_2;
                         end
       default:         begin
                           code_in_1   = 1'b0;
                           code_in_2   = 1'b0;
                           syndrome_val = 'b0;
                         end
    endcase
    clear_1    = (state == DECODER_1_CLEAR) ;
    clear_2    = (state == DECODER_1_CALC_1) ;
    valid_out  = valid_in & ((state == DECODER_1_OUTPUT) || ((state == DECODER_1_CALC_0) & sticky_bit));
    error_det  = error_det_signal & valid_out;
  end

`ifdef FORMAL
 //   assume property (@(posedge clk) next < 4'hE);
`endif

endmodule
