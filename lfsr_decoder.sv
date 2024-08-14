module lfsr_decoder (
  input logic clk,
            reset,
          lfsr_in,
          clear,
  output logic [2:0] q);

  always_ff @(posedge clk or posedge reset)
    if (reset)
      q <= 'b0;
    else begin
      if (clear)
        q <= 'b0;
      else begin
        q[2] <= lfsr_in ^ q[0];
        q[1] <= q[0] ^ q[2];
        q[0] <= q[1];
      end
    end

endmodule
