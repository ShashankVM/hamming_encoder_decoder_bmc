module piso
 #(parameter N = 4)
 (input logic clk,
            reset,
            load,
  input logic [N-1:0] piso_in,
  output logic piso_out);

  logic [N-2:0] q;

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      q <= 'b0;
    else if (load)
      q <= piso_in[N-1:1];
    else
      q <= q >> 1;
  end

  assign piso_out = load ? piso_in[0] : q[0];

endmodule

