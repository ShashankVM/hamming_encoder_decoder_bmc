module error_correction_and_detection(
  input logic [2:0] syndrome_val,
  input logic [6:0] code_in,
  output logic [6:0] code_out,
  output logic error_det);

  logic [2:0] error_pos;
  // calculate error position
  always_comb begin
    unique case (syndrome_val)
        1 : error_pos = 3'd4;
        2 : error_pos = 3'd5;
        3 : error_pos = 3'd2;
        4 : error_pos = 3'd6;
        5 : error_pos = 3'd0;
        6 : error_pos = 3'd3;
        7 : error_pos = 3'd1;
      default : error_pos = 3'd0;
    endcase

    code_out  = code_in;
    error_det = 1'b0;

    //correct and detect error
    if (syndrome_val != 3'd0) begin
      code_out[error_pos] = !code_in[error_pos];
      error_det = 1'b1;
    end
  end

endmodule
