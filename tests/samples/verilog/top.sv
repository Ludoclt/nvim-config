module top (
    input  logic       clk,
    input  logic       rst_n,
    output logic [3:0] leds
);
  logic [7:0] count;

  counter #(.WIDTH(8)) u_counter (
      .clk  (clk),
      .rst_n(rst_n),
      .count(count)
  );

  assign leds = count;
endmodule
