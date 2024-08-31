module dut(
  input logic clk,
              reset,
              error_inject,
  input logic [3:0] message,
  input logic [2:0] error_pos1,
  input logic [2:0] error_pos2,
  output logic encoder_ready,
               tx_valid,
               rx_valid,
               error_det,
  output logic [6:0] tx,
                     rx);

  logic code_out_encoded,
        channel_valid_out,
        channel_out;


  cc_encoder cc_encoder_inst( .clk(clk), .reset(reset), .code_in(message), .ready(encoder_ready), .valid(tx_valid), .code_out(code_out_encoded) );

  channel    channel_inst( .clk(clk), .reset(reset), .valid_in(tx_valid), .channel_in(code_out_encoded), .valid_out(channel_valid_out), .error_inject(error_inject), .error_pos1(error_pos1), .error_pos2(error_pos2), .channel_out(channel_out) );
  buffer_reg #(7) buffer_inst( .clk(clk), .reset(reset), .enable(tx_valid), .buffer_in(code_out_encoded), .buffer_out(tx) );

  cc_decoder_ht cc_decoder_ht_inst(.clk(clk), .reset(reset), .valid_in(channel_valid_out), .code_in(channel_out), .error_det(error_det), .valid_out(rx_valid), .code_out(rx) );

`ifdef FORMAL
logic [6:0] tx_message,
              tx_final;

  logic error_inject_reg;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      tx_message       <= 'b0;
      error_inject_reg <= 'b0;
    end else if (encoder_ready) begin
      tx_message       <= tx;
      error_inject_reg <= error_inject;
    end
  end

  always_comb begin
    if (encoder_ready && rx_valid)
      tx_final = tx;
    else
      tx_final = tx_message;
  end

ASSUME_STABLE_MESSAGE: assume property (@(posedge clk) disable iff (reset) $fell(encoder_ready) or !encoder_ready |-> $stable(message));
ASSUME_STABLE_ERROR_INJECT: assume property (@(posedge clk) disable iff (reset) $fell(encoder_ready) or !encoder_ready |-> $stable(error_inject));
ASSUME_STABLE_ERROR_POSITION1: assume property (@(posedge clk) disable iff (reset) $fell(encoder_ready) or !encoder_ready |-> $stable(error_pos1));
ASSUME_STABLE_ERROR_POSITION2: assume property (@(posedge clk) disable iff (reset) $fell(encoder_ready) or !encoder_ready |-> $stable(error_pos2));
ASSUME_VALID_ERROR_POSITION1: assume property (@(posedge clk) disable iff (reset) error_pos1 < 3'd7);
ASSUME_VALID_ERROR_POSITION2: assume property (@(posedge clk) disable iff (reset) error_pos2 < 3'd7);

ASSERT_RX_EQUAL_TX_NO_INJECTION: assert property (@(posedge clk) disable iff (reset) rx_valid && !error_inject_reg |-> (tx_final == rx));
ASSERT_RX_EQUAL_TX_SINGLE_ERROR_WITH_INJECTION: assert property (@(posedge clk) disable iff (reset) rx_valid && ($past(error_pos1) == $past(error_pos2)) && error_inject_reg |-> (tx_final == rx));
ASSERT_RX_NOT_EQUAL_TX_FOR_DOUBLE_ERROR: assert property (@(posedge clk) disable iff (reset) rx_valid && ($past(error_pos1) != $past(error_pos2)) && error_inject_reg |-> (tx_final != rx));

ASSERT_ENCODER_LATENCY: assert property (@(posedge clk) disable iff (reset) $rose(encoder_ready) |-> ##7 encoder_ready);
ASSERT_DECODER_LATENCY: assert property (@(posedge clk) disable iff (reset) $rose(rx_valid) |-> ##7 rx_valid);

ASSERT_ERROR_DET_IF_ERROR_INJECT: assert property (@(posedge clk) disable iff (reset) rx_valid && error_inject_reg |-> error_det);
ASSERT_ERROR_DET_IMPLIES_ERROR_INJECT: assert property (@(posedge clk) disable iff (reset) error_det |-> error_inject_reg);

ASSERT_RX_EVENTUALLY: assert property (@(posedge clk) disable iff (reset) s_eventually rx_valid);

COVER_ZERO_MESSAGE: cover property (@(posedge clk) disable iff (reset) (message == 4'b0000));
COVER_NON_ZERO_MESSAGE: cover property (@(posedge clk) disable iff (reset) (message != 4'b0000));
COVER_ERROR_INJECT_OFF: cover property (@(posedge clk) disable iff (reset) !error_inject ##9 error_inject);
COVER_ERROR_DET: cover property (@(posedge clk) disable iff (reset) error_det);
//COVER_ERROR_INJECT_ON_ERROR_CORRECTION: cover property ((error_pos1 == error_pos2) throughout error_inject [*8] );
////COVER_ERROR_INJECT_ON_ERROR_DETECTION: cover property ((error_pos1 != error_pos2) throughout  error_inject [*8] );
COVER_NO_VACUOUS_PASS: cover property (@(posedge clk) disable iff (reset) rx_valid && error_inject_reg && (error_pos1 == error_pos2) && (tx_final == rx));
//COVER_ERROR_INJECT_ON_TWO_CYCLES: cover property (error_inject [*16] );
// COVER_TWO_DIFFERENT_NON_ZERO_MESSAGES_WITH_ERROR: cover property (@(posedge clk) disable iff (reset) (error_pos1 == error_pos2) throughout (error_inject && (message == 4'b1001) && (error_pos1 == 3'b101) ##8 error_inject && (message == 4'b1010) && (error_pos1 == 3'b110) ##8 message == 4'b0000));
`endif
endmodule
