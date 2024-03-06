/*
 * @Design: tb_pe_os
 * @Author: Zhao Siwei
 * @Email:  cheems@foxmail.com
 * @Date:   2024-03-03
 * @Description: Testbench of pe_os
 */
`timescale 1ns/10ps

module tb_isa;

// Parameters
parameter PERIOD          = 10;            // 100MHz
parameter DATA_WIDTH_IN   = 16;
parameter DATA_WIDTH_OUT  = 32;

// Inputs & Outputs
logic                      clk_i    = 0 ;
logic                      rstn_i   = 0 ;

logic                      clear_i  = 1 ;
logic [DATA_WIDTH_IN-1:0]  active_i = 0 ;
logic [DATA_WIDTH_IN-1:0]  weight_i = 0 ;

logic [DATA_WIDTH_IN-1:0]  active_o  ;
logic [DATA_WIDTH_IN-1:0]  weight_o  ;
logic [DATA_WIDTH_OUT-1:0] mac_res_o ;

// clk & rst
initial forever #(PERIOD/2) clk_i  = ~clk_i;
initial         #(PERIOD*2) rstn_i = 1;

// pe_os
pe_os #(
    .DATA_WIDTH_IN  ( DATA_WIDTH_IN  ),
    .DATA_WIDTH_OUT ( DATA_WIDTH_OUT ))
 u_pe_os (
    .clk_i      ( clk_i       ),
    .rstn_i     ( rstn_i      ),

    .clear_i    ( clear_i     ),
    .active_i   ( active_i    ),
    .weight_i   ( weight_i    ),

    .active_o   ( active_o    ),
    .weight_o   ( weight_o    ),
    .mac_res_o  ( mac_res_o   )
);

logic [DATA_WIDTH_IN-1:0] active_array [0:3];
logic [DATA_WIDTH_IN-1:0] weight_array [0:3];

genvar i;
generate
  for (i = 0; i < 4; i = i + 1) begin
    assign active_array[i] = i;
    assign weight_array[i] = i + 1;
  end
endgenerate

initial begin
  #(PERIOD*5);
  input_drive;
    
  #(PERIOD*5);
  $finish;
end

// drive data to input active & weight
integer j;
task input_drive;
  @(posedge clk_i)
    clear_i <= 1'b0;

  for (j = 0; j < 4; j = j + 1) begin
    @(posedge clk_i) begin
      active_i <= active_array[j];
      weight_i <= weight_array[j];
      #1 $display("active = %d, weight = %d, mac_res = %d", active_o, weight_o, mac_res_o);
    end
  end

  @(posedge clk_i)
    #1 $display("active = %d, weight = %d, mac_res = %d", active_o, weight_o, mac_res_o);
    clear_i <= 1'b1;
endtask

// Dump Wave
initial begin
  $dumpfile("sim/wave.vcd");
  $dumpvars(0, tb_isa);
end

endmodule