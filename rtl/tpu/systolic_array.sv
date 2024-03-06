/*
 * @Design: systolic_array
 * @Author: Zhao Siwei
 * @Email:  cheems@foxmail.com
 * @Date:   2024-03-03
 * @Description: Systolic array
 */

module systolic_array #(
  parameter PE_DATA_WIDTH_IN  = 32,
  parameter PE_DATA_WIDTH_OUT = 32,
  parameter ARRAY_WIDTH       = 4,
  parameter ARRAY_HEIGHT      = 4
) (
  input  logic                        clk_i,
  input  logic                        rstn_i,
  
  input  logic                        ctrl_start_i,
  
  input  logic [PE_DATA_WIDTH_IN-1:0] active_i [0:ARRAY_HEIGHT-1],
  input  logic [PE_DATA_WIDTH_IN-1:0] weight_i [0:ARRAY_WIDTH -1],
  
  // output logic                        result_vld_o,
  output logic [PE_DATA_WIDTH_IN-1:0] result_o [0:ARRAY_HEIGHT-1][0:ARRAY_WIDTH-1]
);
  // PE array input & output
  logic [PE_DATA_WIDTH_IN-1:0] active_i_w [0:ARRAY_HEIGHT-1][0:ARRAY_WIDTH-1];
  logic [PE_DATA_WIDTH_IN-1:0] weight_i_w [0:ARRAY_HEIGHT-1][0:ARRAY_WIDTH-1];
  logic [PE_DATA_WIDTH_IN-1:0] active_o_w [0:ARRAY_HEIGHT-1][0:ARRAY_WIDTH-1];
  logic [PE_DATA_WIDTH_IN-1:0] weight_o_w [0:ARRAY_HEIGHT-1][0:ARRAY_WIDTH-1];
  logic [PE_DATA_WIDTH_IN-1:0] result_o_w [0:ARRAY_HEIGHT-1][0:ARRAY_WIDTH-1];

  // Generate PE array
  genvar i, j;
  generate
    for (i = 0; i < ARRAY_HEIGHT; i = i + 1) begin: sys_array_row
      for (j = 0; j < ARRAY_WIDTH; j = j + 1) begin: sys_array_col
        pe_os #(
          .DATA_WIDTH_IN  ( PE_DATA_WIDTH_IN  ),
          .DATA_WIDTH_OUT ( PE_DATA_WIDTH_OUT )
        ) u_pe_os (
          .clk_i      ( clk_i            ),
          .rstn_i     ( rstn_i           ),
          
          .clear_i    ( ctrl_start_i     ),
          .active_i   ( active_i_w[i][j] ),
          .weight_i   ( weight_i_w[i][j] ),
          
          .active_o   ( active_o_w[i][j] ),
          .weight_o   ( weight_o_w[i][j] ),
          .mac_res_o  ( result_o_w[i][j] )
        );
      end
    end
  endgenerate

  // PE array connection
  //            [ weight ]
  //           ------------
  // [active] | sys_array  |
  //           ------------
  generate
    for (i = 0; i < ARRAY_HEIGHT; i = i + 1) begin
      for (j = 0; j < ARRAY_WIDTH; j = j + 1) begin
        if ((i ==0) & (j == 0)) begin
          assign active_i_w[i][j] = active_i[i];
          assign weight_i_w[i][j] = weight_i[j];
        end else if (i == 0) begin
          assign active_i_w[i][j] = active_o_w[i][j-1];
          assign weight_i_w[i][j] = weight_i[j];
        end else if (j == 0) begin
          assign active_i_w[i][j] = active_i[i];
          assign weight_i_w[i][j] = weight_o_w[i-1][j];
        end else begin
          assign active_i_w[i][j] = active_o_w[i][j-1];
          assign weight_i_w[i][j] = weight_o_w[i-1][j];
        end
        assign result_o[i][j] = result_o_w[i][j];
      end
    end
  endgenerate
  
  // // debug
  // integer m, n;
  // always @(posedge clk_i) begin
  //   $display("active");
  //   for (m = 0; m < ARRAY_HEIGHT; m = m + 1) begin
  //     for (n = 0; n < ARRAY_WIDTH; n = n + 1) begin
  //       $write("[%0d][%0d] = %0d\t", m, n, active_i_w[m][n]);
  //     end
  //     $write("\n");
  //   end
  //   $write("\n\n");
  //   $display("weight");
  //   for (m = 0; m < ARRAY_HEIGHT; m = m + 1) begin
  //     for (n = 0; n < ARRAY_WIDTH; n = n + 1) begin
  //       $write("[%0d][%0d] = %0d\t", m, n, weight_i_w[m][n]);
  //     end
  //     $write("\n");
  //   end
  //   $write("\n\n");
  // end

endmodule