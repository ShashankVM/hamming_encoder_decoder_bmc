`ifndef NUM_SEGMENTS
`define NUM_SEGMENTS 8
`endif
module dut_fpga
 #
  (
   parameter NUM_SEGMENTS = `NUM_SEGMENTS,
   parameter USE_PLL      = "TRUE"
   )
  (
  input logic clk,
              reset,
              error_inject,
  input logic [3:0] message,
  input logic [2:0] error_pos1,
  input logic [2:0] error_pos2,
  output logic encoder_ready,
               [3:0] message_out,
               [2:0] error_pos1_out,
               [2:0] error_pos2_out,
         logic error_inject_out,
               reset_out,
               error_det,
  output logic [NUM_SEGMENTS-1:0] anode,
  output logic [7:0] cathode
);
  logic [6:0] tx_message,
              tx_final;
  
logic rx_valid, tx_valid;
logic [6:0] rx, tx;
logic                               clk_50;
logic [NUM_SEGMENTS-1:0][3:0]       encoded;
logic [NUM_SEGMENTS-1:0]            digit_point;
  generate
    if (USE_PLL == "TRUE") begin : g_USE_PLL
      sys_pll u_sys_pll
        (
         .clk_in1  (clk),
         .clk_out1 (clk_50)
         );
    end else  begin : g_NO_PLL
      assign clk_50 = clk;
    end
  endgenerate

  dut u_dut(.clk(clk_50), .*);

 seven_segment
    #
    (
     .NUM_SEGMENTS (NUM_SEGMENTS),
     .CLK_PER      (20)
     )
  u_seven_segment
    (
     .clk          (clk_50),
     .encoded      (encoded),
     .digit_point  (digit_point),
     .anode        (anode),
     .cathode      (cathode)
     );

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)              tx_message       <= 'b0;
    else if (encoder_ready) tx_message       <= tx;
     
always_comb begin
    if (encoder_ready && rx_valid)
      tx_final = tx;
    else
      tx_final = tx_message;
    encoded[2]  <= '0;
    encoded[3]  <= '0;
    encoded[6]  <= '0;
    encoded[7]  <= '0;
  end

always @(posedge clk_50 or posedge reset) begin
       digit_point <= '1;
       if (reset) begin
         encoded[0]  <= 'b0;
         encoded[1]  <= 'b0;
         encoded[4]  <= 'b0;
         encoded[5]  <= 'b0;
       end
       else if (rx_valid) begin
         encoded[0]  <= rx[3:0];
         encoded[1]  <= {1'b0, rx[6:4]};
       end
       else if (tx_valid) begin
         encoded[4]  <= tx_final[3:0];
         encoded[5]  <= {1'b0, tx_final[6:4]};
       end
     end

assign reset_out    = reset;
assign message_out  = message;
assign error_inject_out = error_inject;
assign error_pos1_out = error_pos1;
assign error_pos2_out = error_pos2;

endmodule
