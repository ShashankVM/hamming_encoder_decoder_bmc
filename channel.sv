module channel(
  input logic clk,
              reset,
              channel_in,
              valid_in,
              error_inject,
  input logic [2:0] error_pos1,
  input logic [2:0] error_pos2,
  output logic valid_out,
               channel_out);

 logic [2:0] cycle;

always_ff @(posedge clk or posedge reset) begin
  if (reset)
    cycle <= 'b0;
  else if (valid_in && error_inject)
    cycle <= (cycle == 3'd6) ? 'b0 : cycle + 1;
end

always_comb begin
  channel_out = channel_in;
  valid_out   = reset ? 1'b0 : valid_in;
  if (((cycle == error_pos1) || (cycle == error_pos2)) && error_inject)
    channel_out = !channel_in;
end

endmodule
