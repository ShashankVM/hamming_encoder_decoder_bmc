module buffer_reg
  #(parameter N = 4)
(input logic clk,
            reset,
           enable,
        buffer_in,
 output logic [N-1:0] buffer_out);

 always_ff @(posedge clk or posedge reset) begin
   if (reset)
     buffer_out <= 'b0;
   else if (enable)
     buffer_out <= {buffer_in, buffer_out[N-1:1]};
 end

endmodule
