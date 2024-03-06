/*
 * @Design: pe_os
 * @Author: Zhao Siwei
 * @Email:  cheems@foxmail.com
 * @Date:   2024-03-03
 * @Description: MAC PE with output-stationary data-flow
 */

module pe_os #(
  parameter DATA_WIDTH_IN   = 32, // <= 32
  parameter DATA_WIDTH_OUT  = 32
) (
  input  logic                      clk_i,
  input  logic                      rstn_i,

  input  logic                      clear_i,

  input  logic [DATA_WIDTH_IN-1:0]  weight_i,
  input  logic [DATA_WIDTH_IN-1:0]  active_i,
  
  output logic [DATA_WIDTH_IN-1:0]  weight_o,
  output logic [DATA_WIDTH_IN-1:0]  active_o,

  output logic [DATA_WIDTH_OUT-1:0] mac_res_o
);
  // Multiplier
  // logic [2*DATA_WIDTH_IN-1:0] mul_res_w;
  logic [63:0] mul_res_w;

  // assign mul_res_w = active_i * weight_i;

  utils_multiplier_32  u_utils_multiplier_32 (
    .operand1_i ( {{(32-DATA_WIDTH_IN){1'b0}}, active_i} ),
    .operand2_i ( {{(32-DATA_WIDTH_IN){1'b0}}, weight_i} ),
    .mul_mode_i ( 3'b000                                 ),
    .res_low_o  ( mul_res_w[31:0 ]                       ),
    .res_high_o ( mul_res_w[63:32]                       )
  );

  // Adder
  logic [2*DATA_WIDTH_IN:0] mac_res_w, mac_res_q;
  // logic [64:0] mac_res_w, mac_res_q;
  
  assign mac_res_w = mac_res_q + mul_res_w[2*DATA_WIDTH_IN-1:0];

  // Hold output
  always @(posedge clk_i or negedge rstn_i) begin
    if      (~rstn_i) mac_res_q <= '0;
    else if (clear_i) mac_res_q <= '0;
    else              mac_res_q <= mac_res_w;
  end
  
  assign mac_res_o = mac_res_q[DATA_WIDTH_OUT-1:0];

  // Flow active & weight
  always @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i) begin
      active_o <= '0;
      weight_o <= '0;
    end else begin
      active_o <= active_i;
      weight_o <= weight_i;
    end
  end
  
endmodule