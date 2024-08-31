 module cc_encoder(
  input logic clk,
            reset,
  input logic [3:0] code_in,
  output logic ready,
               valid,
               code_out);

  logic [2:0] lfsr_reg;
  logic piso_load, piso_out;
  logic [3:0] piso_in;

  enum logic [2:0] {MESSAGE_0, MESSAGE_1, MESSAGE_2, MESSAGE_3, SYNDROME_0, SYNDROME_1, SYNDROME_2}  state, next;

  piso #(4) piso_inst(.clk(clk), .reset(reset), .load(piso_load), .piso_in(piso_in), .piso_out(piso_out));

  lfsr_encoder lfsr_encoder_inst(.clk(clk), .reset(reset), .lfsr_in(piso_out), .q(lfsr_reg));

  // state registers
  always_ff @(posedge clk or posedge reset)
    if (reset) state <= MESSAGE_0;
    else       state <= next;

  // next_state_assignment logic
  always_comb begin
    next = state;
    unique case (state)
      MESSAGE_0  : next = MESSAGE_1;
      MESSAGE_1  : next = MESSAGE_2;
      MESSAGE_2  : next = MESSAGE_3;
      MESSAGE_3  : next = SYNDROME_0;
      SYNDROME_0 : next = SYNDROME_1;
      SYNDROME_1 : next = SYNDROME_2;
      SYNDROME_2 : next = MESSAGE_0;
    endcase
  end

  // output calculation logic
  always_comb begin
    unique case (state)
      MESSAGE_0: begin
                   ready     = 1'b1;
                   piso_in   = code_in;
                   piso_load = 1'b1;
                 end
      MESSAGE_1, MESSAGE_2, MESSAGE_3: begin
                   ready      = 1'b0;
                   piso_load  = 1'b0;
                   piso_in    = code_in;
                 end
      SYNDROME_0: begin
                    ready      = 1'b0;
                    piso_load = 1'b1;
                    piso_in   = {1'b0,lfsr_reg};
                  end
      SYNDROME_1, SYNDROME_2: begin
                   ready      = 1'b0;
                   piso_load  = 1'b0;
                   piso_in    = {1'b0,lfsr_reg};
                  end
    endcase
    valid = !reset;
    code_out = piso_out;
  end

endmodule
