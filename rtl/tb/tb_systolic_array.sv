/*
 * @Design: tb_systolic_array
 * @Author: Zhao Siwei
 * @Email:  cheems@foxmail.com
 * @Date:   2024-03-04
 * @Description: Testbench of systolic array
 */
`timescale 1ns/10ps

module tb_isa;

// Parameters
parameter PERIOD            = 10; // 100MHz
parameter PE_DATA_WIDTH_IN  = 32;
parameter PE_DATA_WIDTH_OUT = 32;
parameter ARRAY_WIDTH       = 7;
parameter ARRAY_HEIGHT      = 10;
parameter ACTIVE_WIDTH      = 5;
parameter WEIGHT_HEIGHT     = ACTIVE_WIDTH;

// Inputs & Outputs
logic                        clk_i         = 1'b0 ;
logic                        rstn_i        = 1'b0 ;

logic                        ctrl_start_i  = 1'b0 ;
logic [PE_DATA_WIDTH_IN-1:0] active_i [0:ARRAY_HEIGHT-1];
logic [PE_DATA_WIDTH_IN-1:0] weight_i [0:ARRAY_WIDTH -1];

logic [PE_DATA_WIDTH_IN-1:0] result_o [0:ARRAY_HEIGHT-1][0:ARRAY_WIDTH-1];

// clk & rst
initial forever #(PERIOD/2) clk_i  = ~clk_i;
initial         #(PERIOD*2) rstn_i = 1;

// systolic array
systolic_array #(
    .PE_DATA_WIDTH_IN  ( PE_DATA_WIDTH_IN  ),
    .PE_DATA_WIDTH_OUT ( PE_DATA_WIDTH_OUT ),
    .ARRAY_WIDTH       ( ARRAY_WIDTH       ),
    .ARRAY_HEIGHT      ( ARRAY_HEIGHT      ))
 u_systolic_array (
    .clk_i        ( clk_i        ),
    .rstn_i       ( rstn_i       ),

    .ctrl_start_i ( ctrl_start_i ),

    .active_i     ( active_i     ),
    .weight_i     ( weight_i     ),
                            
    .result_o     ( result_o     )
);

logic [PE_DATA_WIDTH_IN-1:0] active_array [0:ARRAY_HEIGHT -1][0:ACTIVE_WIDTH-1];
logic [PE_DATA_WIDTH_IN-1:0] weight_array [0:WEIGHT_HEIGHT-1][0:ARRAY_WIDTH -1];

// generate matrix data
genvar i, j;
generate
  for (i = 0; i < ARRAY_HEIGHT; i = i + 1) begin
    for (j = 0; j < ACTIVE_WIDTH; j = j + 1) begin
      assign active_array[i][j] = i + j + 1;
    end
  end
  for (i = 0; i < WEIGHT_HEIGHT; i = i + 1) begin
    for (j = 0; j < ARRAY_WIDTH; j = j + 1) begin
      assign weight_array[i][j] = i + j + 1;
    end
  end
endgenerate

logic [PE_DATA_WIDTH_IN-1:0] active_array_skew [0:ARRAY_HEIGHT   -1][0:ACTIVE_WIDTH+ARRAY_HEIGHT-2];
logic [PE_DATA_WIDTH_IN-1:0] weight_array_skew [0:WEIGHT_HEIGHT+ARRAY_WIDTH-2][0:ARRAY_WIDTH   -1];

// skew matrix
generate
  for (i = 0; i < ARRAY_HEIGHT; i = i + 1) begin
    for (j = 0; j < ACTIVE_WIDTH+ARRAY_HEIGHT-1; j = j + 1) begin
      if (j < i) begin
        assign active_array_skew[i][j] = '0;
      end else if ((j - i) >= ACTIVE_WIDTH) begin
        assign active_array_skew[i][j] = '0;
      end else begin
        assign active_array_skew[i][j] = active_array[i][j - i];
      end
    end
  end
  for (j = 0; j < ARRAY_WIDTH; j = j + 1) begin
    for (i = 0; i < WEIGHT_HEIGHT+ARRAY_WIDTH-1; i = i + 1) begin
      if (i < j) begin
        assign weight_array_skew[i][j] = '0;
      end else if ((i - j) >= WEIGHT_HEIGHT) begin
        assign weight_array_skew[i][j] = '0;
      end else begin
        assign weight_array_skew[i][j] = weight_array[i - j][j];
      end
    end
  end
endgenerate

integer x, y, n, m;
initial begin
  for (x = 0; x < ARRAY_HEIGHT; x = x + 1)
    active_i[x] = '0;
  for (y = 0; y < ACTIVE_WIDTH; y = y + 1)
    weight_i[y] = '0;

  #(PERIOD*5);
  
  // display array data
  display_array;

  // drive data to active & weight input
  input_drive;
    
  $finish;
end

// drive data to active & weight input
task input_drive;
  // send start signal (output clear will be done at the same time)
  @(posedge clk_i)
    ctrl_start_i <= 1'b1;
  @(posedge clk_i)
    ctrl_start_i <= 1'b0;
  
  if ((ACTIVE_WIDTH+ARRAY_HEIGHT-1) > (WEIGHT_HEIGHT+ARRAY_WIDTH-1)) begin  // max cycle
    for (n = 0; n < (ACTIVE_WIDTH+ARRAY_HEIGHT-1); n = n + 1) begin
      if (n < (WEIGHT_HEIGHT+ARRAY_WIDTH-1)) begin  // drive active & weight
        @(posedge clk_i) begin
          $display("---------------------------- clk %0d ----------------------------", n);
          $display("active input");
          for (m = 0; m < ARRAY_HEIGHT; m = m + 1) begin
            active_i[m] <= active_array_skew[m][n];
            $write("[%0d][%0d]\t= %0d\t", m, n, active_array_skew[m][n]);
          end
          $display("\n");

          $display("weight input");
          for (m = 0; m < ARRAY_WIDTH; m = m + 1) begin
            weight_i[m] <= weight_array_skew[n][m];
            $write("[%0d][%0d]\t= %0d\t", n, m, weight_array_skew[n][m]);
          end
          $display("\n");
        end
      end else begin                                // drive active only
        @(posedge clk_i) begin
          $display("---------------------------- clk %0d ----------------------------", n);
          $display("active input");
          for (m = 0; m < ARRAY_HEIGHT; m = m + 1) begin
            active_i[m] <= active_array_skew[m][n];
            $write("[%0d][%0d]\t= %0d\t", m, n, active_array_skew[m][n]);
          end
          $display("\n");

          $display("weight input");
          for (m = 0; m < ARRAY_WIDTH; m = m + 1) begin
            weight_i[m] <= '0;
            $write("[%0d][%0d]\t= %0d\t", n, m, '0);
          end
          $display("\n");
        end
      end
    end
  end else begin
    for (n = 0; n < (WEIGHT_HEIGHT+ARRAY_WIDTH-1); n = n + 1) begin
      if (n < (ACTIVE_WIDTH+ARRAY_HEIGHT-1)) begin  // drive active & weight
        @(posedge clk_i) begin
          $display("---------------------------- clk %0d ----------------------------", n);
          $display("active input");
          for (m = 0; m < ARRAY_HEIGHT; m = m + 1) begin
            active_i[m] <= active_array_skew[m][n];
            $write("[%0d][%0d]\t= %0d\t", m, n, active_array_skew[m][n]);
          end
          $display("\n");

          $display("weight input");
          for (m = 0; m < ARRAY_WIDTH; m = m + 1) begin
            weight_i[m] <= weight_array_skew[n][m];
            $write("[%0d][%0d]\t= %0d\t", n, m, weight_array_skew[n][m]);
          end
          $display("\n");
        end
      end else begin                                // drive weight only
        @(posedge clk_i) begin
          $display("---------------------------- clk %0d ----------------------------", n);
          $display("active input");
          for (m = 0; m < ARRAY_HEIGHT; m = m + 1) begin
            active_i[m] <= '0;
            $write("[%0d][%0d]\t= %0d\t", m, n, '0);
          end
          $display("\n");

          $display("weight input");
          for (m = 0; m < ARRAY_WIDTH; m = m + 1) begin
            weight_i[m] <= weight_array_skew[n][m];
            $write("[%0d][%0d]\t= %0d\t", n, m, weight_array_skew[n][m]);
          end
          $display("\n");
        end
      end
    end
  end

  // wait for matmul done
  #(PERIOD*500);

  // display result
  @(posedge clk_i)
    $display("---------------------------- result ----------------------------");
    for (m = 0; m < ARRAY_HEIGHT; m = m + 1) begin
      for (n = 0; n < ARRAY_WIDTH; n = n + 1) begin
        $write("[%0d][%0d]\t= %0d\t", m, n, result_o[m][n]);
      end
      $write("\n");
    end
    $write("\n");
endtask

task display_array;
  // display array data
  $display("active_array:");
  for (x = 0; x < ARRAY_HEIGHT; x = x + 1) begin
    for (y = 0; y < ACTIVE_WIDTH; y = y + 1) begin
      $write("[%0d][%0d]\t= %0d\t", x, y, active_array[x][y]);
    end
    $write("\n");
  end
  $write("\n");

  $display("active_array_skew:");
  for (x = 0; x < ARRAY_HEIGHT; x = x + 1) begin
    for (y = 0; y < ACTIVE_WIDTH+ARRAY_HEIGHT-1; y = y + 1) begin
      $write("[%0d][%0d]\t= %0d\t", x, y, active_array_skew[x][y]);
    end
    $write("\n");
  end
  $write("\n");

  $display("weight_array:");
  for (x = 0; x < WEIGHT_HEIGHT; x = x + 1) begin
    for (y = 0; y < ARRAY_WIDTH; y = y + 1) begin
      $write("[%0d][%0d]\t= %0d\t", x, y, weight_array[x][y]);
    end
    $write("\n");
  end
  $write("\n");

  $display("weight_array_skew:");
  for (x = 0; x < WEIGHT_HEIGHT+ARRAY_WIDTH-1; x = x + 1) begin
    for (y = 0; y < ARRAY_WIDTH; y = y + 1) begin
      $write("[%0d][%0d]\t= %0d\t", x, y, weight_array_skew[x][y]);
    end
    $write("\n");
  end
  $write("\n");
endtask

// Dump Wave
initial begin
  $dumpfile("sim/wave.vcd");
  $dumpvars(0, tb_isa);
end

endmodule