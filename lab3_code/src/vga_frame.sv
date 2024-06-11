  /*******************************************************************************
  * CS220: Digital Circuit Lab
  * Computer Science Department
  * University of Crete
  * 
  * Date: 2023/02/06
  * Author: Alexandros Fourtounis
  * Filename: vga_frame.sv
  * Description: This module paints each frame.
  *
  ******************************************************************************/

  module vga_frame(
    input logic clk,
    input logic rst,

    input logic i_pix_valid,
    input logic [9:0] i_col,
    input logic [9:0] i_row,

    input logic [5:0] i_player_bcol,
    input logic [5:0] i_player_brow,

    input logic [5:0] i_exit_bcol,
    input logic [5:0] i_exit_brow,

    output logic [3:0] o_red,
    output logic [3:0] o_green,
    output logic [3:0] o_blue,

    input logic i_rom_en,
    input logic [10:0] i_rom_addr,
    output logic [15:0] o_rom_data,

    input logic [5:0] last_red_block_position

  );

  logic [5:0] block_c;
  logic [5:0] block_r; 

  logic [5:0] prev_block_c;
  logic [5:0] prev_block_r; 

  logic player_en;
  logic exit_en;
  logic maze_en;

  logic [15:0] ext_player_pixel;
  logic [15:0] maze_pixel;
  logic [15:0] player_pixel;
  logic [15:0] exit_pixel;  

  logic [10:0] maze_addr;
  logic [7:0] player_addr;
  logic [7:0] exit_addr;

  logic [9:0] tmp_col;
  logic [9:0] tmp_row;
  logic tmp_pix_valid;

  always_ff @(posedge clk) begin
    if (rst) begin
      tmp_col <= 0;
      tmp_row <= 0;
      tmp_pix_valid <= 0;
    end else begin
      tmp_col <= i_col; //store the current column
      tmp_row <= i_row; //store the current row
      tmp_pix_valid <= i_pix_valid; //store the pixel valid signal
    end
  end

  always_comb begin
    o_red = 4'h0; //default value
    o_blue = 4'h0; //default value
    o_green = 4'h0; //default value
    player_en = 1'b0; //default value
    exit_en = 1'b0; //default value
    maze_en = 1'b0; //default value
    
    block_c = i_col >> 4; //right shift by 4 bits == division by 16
    block_r = i_row >> 4; //right shift by 4 bits == division by 16
    prev_block_r = tmp_row >> 4; //previous block row
    prev_block_c = tmp_col >> 4; //previous block column

    maze_addr = (( block_r * 64) + (block_c % 64)); //calculate address
    player_addr = (i_row * 16) + (i_col % 16); //calculate address
    exit_addr = ( i_row * 16) + (i_col % 16); //calculate address
    //check if player is in the current block based on the previous block 
    player_en = ((i_player_bcol == prev_block_c) && (i_player_brow == prev_block_r) && tmp_pix_valid) ? 1'b1 : 1'b0; 
    //check if exit is in the current block based on the previous block and player_en is not 1
    exit_en = ((i_exit_bcol == prev_block_c) && (i_exit_brow == prev_block_r) && !player_en && tmp_pix_valid) ? 1'b1 : 1'b0;
    //check if maze is in the current block based on the previous block and player_en and exit_en are not 1
    maze_en = (!player_en & !exit_en && tmp_pix_valid) ? 1'b1 : 1'b0;

    if (player_en) begin
      o_red = player_pixel[15:12];
      o_green = player_pixel[11:8];
      o_blue = player_pixel[7:4];
    end
    if (exit_en) begin
      o_red = exit_pixel[15:12];
      o_green = exit_pixel[11:8];
      o_blue = exit_pixel[7:4];
    end
    if(maze_en) begin
      o_red = maze_pixel[15:12];
      o_green = maze_pixel[11:8];
      o_blue = maze_pixel[7:4];
    end

    if(block_r == 29 && i_pix_valid) begin
      if (block_c <= last_red_block_position) begin //paint the next block red
        o_red = 4'hf;
        o_blue = 4'h0;
        o_green = 4'h0;    
      end
    end 
  end


  // ROM Template Instantiation
  // NOTE: make sure that you put the correct path for the ROM files
  rom_dp #(
    .size(2048),
    .file("C:/Users/thead/Downloads/lab3_code/lab3_code/src/roms/maze1.rom") 
  )
  maze_rom (
    .clk(clk),
    .en(i_pix_valid),
    .addr(maze_addr),
    .dout(maze_pixel),
    .en_b(i_rom_en),
    .addr_b(i_rom_addr),
    .dout_b(o_rom_data)
  );

  rom #(
    .size(256),
    .file("C:/Users/thead/Downloads/lab3_code/lab3_code/src/roms/player.rom") 
  )
  player_rom (
    .clk(clk),
    .en(i_pix_valid),
    .addr(player_addr),
    .dout(player_pixel)
  );

  rom #(
    .size(256),
    .file("C:/Users/thead/Downloads/lab3_code/lab3_code/src/roms/exit.rom") 
  )

  exit_rom (
    .clk(clk),
    .en(i_pix_valid),
    .addr(exit_addr),
    .dout(exit_pixel)
  );

  endmodule