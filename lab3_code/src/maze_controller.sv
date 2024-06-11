/*******************************************************************************
 * CS220: Digital Circuit Lab
 * Computer Science Department
 * University of Crete
 * 
 * Date: 2024/05/02
 * Author: Alexandros Fourtounis
 * Filename: maze_controller.sv
 * Description: Your description here
 *
 ******************************************************************************/

module maze_controller(
  input  logic clk,
  input  logic rst,

  input  logic i_control,
  input  logic i_up,
  input  logic i_down,
  input  logic i_left,
  input  logic i_right,

  output logic        o_rom_en,
  output logic [10:0] o_rom_addr,
  input  logic [15:0] i_rom_data,

  output logic [5:0] o_player_bcol,
  output logic [5:0] o_player_brow,

  input  logic [5:0] i_exit_bcol,
  input  logic [5:0] i_exit_brow,

  output logic [7:0] o_leds,
  input logic i_timeout
);

// fsm states, CTRL is used for the consecutive ctrl presses.
typedef enum logic [3:0] {IDLE, PLAY, UP, DOWN, LEFT, RIGHT, READROM, CHECK, UPDATE, ENDD, CTRL} state_fsm;
state_fsm curr_state, next_state;

//ctrl counter must be 3 to start the game
logic [1:0] ctrl_counter;
//temporal coordinates
logic [5:0] new_col_q;
logic [5:0] new_row_q;

logic [5:0] new_col_d;
logic [5:0] new_row_d;

logic [5:0] check_col_d;
logic [5:0] check_row_d;

logic [5:0] check_row_q;
logic [5:0] check_col_q;

logic [2:0] end_counter;


//colors
logic [3:0] i_red;
logic [3:0] i_green;
logic [3:0] i_blue;

logic wall;
logic grass;
logic white;

logic reach_exit; //signal for reaching the exit

always_ff @(posedge clk) begin
    if (rst) begin
      curr_state <= IDLE; 
      ctrl_counter <= 2'b0;
      end_counter <= 3'b0;
      new_col_q <= {5'b0,1'b1};
      new_row_q <= 6'b0;
      check_col_q <= 6'b0;
      check_row_q <= 6'b0;
    end
    else begin
      check_col_q <= check_col_d;
      check_row_q <= check_row_d;
      new_col_q <= new_col_d;
      new_row_q <= new_row_d;

      if (i_control && ctrl_counter == 3) begin
        end_counter <= end_counter + 1;
      end

      if(curr_state == IDLE && i_control && ctrl_counter==0) begin
        ctrl_counter <= ctrl_counter + 1;
        curr_state <= CTRL;
      end else begin
        curr_state <= next_state; //get next state
        if(curr_state == CTRL && (i_up || i_down || i_left || i_right))
          ctrl_counter <= -1;
        if(curr_state == CTRL && i_control && ctrl_counter == -1) ctrl_counter <= 1;
        if(curr_state == CTRL && i_control && ctrl_counter != -1) ctrl_counter <= ctrl_counter + 1;
        if(i_timeout) curr_state <= ENDD;
      end
      if(curr_state == ENDD) ctrl_counter <= 2'b0;
      if(curr_state == IDLE) end_counter <= 3'b0;
    end
end

logic update;

always_comb begin
  o_rom_en = 0; //default value
  update = 0; //default value
  i_blue = 0; //default value
  i_green = 0; //default value
  i_red = 0; //default value
  wall = 0; //default value
  grass = 0; //default value
  white = 0; //default value
  o_rom_addr = 0; //default value
  next_state = curr_state; //default value
  new_col_d = new_col_q; //default value
  new_row_d = new_row_q; //default value
  check_col_d = check_col_q; //default value
  check_row_d = check_row_q; //default value

  case (curr_state)

    IDLE: begin //idle state
      new_col_d = {5'b0,1'b1};
      new_row_d = 6'b0;
      if(i_control) next_state = CTRL;
    end

    CTRL: begin
      if(ctrl_counter == 3) next_state = PLAY;
    end

    PLAY: begin
      if(end_counter == 6) next_state = IDLE;
      check_col_d = new_col_q; //previous valid column
      check_row_d = new_row_q; //previous valid row
      if(i_up) next_state = UP;
      else if(i_down) next_state = DOWN;
      else if(i_left) next_state = LEFT;
      else if(i_right) next_state = RIGHT;
    end

    UP: begin
      if(end_counter == 6) next_state = IDLE;

      if(check_row_d == 0) begin //check if the player is at the top of the maze
        next_state = PLAY;
      end
      else begin
        check_row_d -= 1;
        next_state = READROM; // transition to READROM state
      end
    end

    DOWN: begin
      if(end_counter == 6) next_state = IDLE;

      if(check_row_d == 63) begin //check if the player is at the bottom of the maze
        next_state = PLAY;
      end
      else begin
        check_row_d += 1;
        next_state = READROM; // transition to READROM state
      end
    end

    LEFT: begin
      if(end_counter == 6) next_state = IDLE;

      if(check_col_d == 0) begin
        next_state = PLAY;
      end
      else begin
        check_col_d -= 1;
        next_state = READROM; // transition to READROM state
      end
    end

    RIGHT: begin
      if(end_counter == 6) next_state = IDLE;

      if(check_col_d == 63) begin
        next_state = PLAY;
      end
      else begin
        check_col_d += 1;
        next_state = READROM; // transition to READROM state
      end
    end

    READROM: begin
      if(end_counter == 6) next_state = IDLE;

      o_rom_addr = ( check_row_d * 64) + (check_col_d % 64); 
      o_rom_en = 1;
      next_state = CHECK;
    end

    CHECK: begin  
      if(end_counter == 6) next_state = IDLE;
    
      i_blue = i_rom_data[7:4];
      i_green = i_rom_data[11:8];
      i_red = i_rom_data[15:12];
      wall = (i_red == 4'h0 && i_green == 4'h0 && i_blue == 4'h0) ? 1'b1 : 1'b0;
      grass = (i_red == 4'd2 && i_green == 4'd4 && i_blue == 4'd1) ? 1'b1 : 1'b0;
      white = (i_red == 4'hf && i_green == 4'hf && i_blue == 4'hf) ? 1'b1 : 1'b0;
      if(!grass && !wall && white) begin
        next_state = UPDATE;
      end
      else begin
        next_state = PLAY;
      end
    end
    UPDATE: begin
      new_col_d = check_col_d; //update the new column
      new_row_d = check_row_d; //update the new row
      if(end_counter == 6) next_state = IDLE;

      if (check_col_d == i_exit_bcol && check_row_d == i_exit_brow) begin //exit condition
         next_state = ENDD; //reached the exit
      end
      else begin 
        next_state = PLAY;
      end
    end
    ENDD: begin
      if (i_control) next_state = IDLE;
    end
  endcase
end

assign o_leds = curr_state; //output the current state
assign o_player_bcol = new_col_q; //output the player's column
assign o_player_brow = new_row_q; //output the player's row

endmodule
