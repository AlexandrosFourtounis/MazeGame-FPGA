/*******************************************************************************
 * CS220: Digital Circuit Lab
 * Computer Science Department
 * University of Crete
 * 
 * Date: 2024/31/03
 * Author: Alexandros Fourtounis
 * Filename: vga_sync.sv
 * Description: Implements VGA HSYNC and VSYNC timings for 640 x 480 @ 60Hz
 *
 ******************************************************************************/

module vga_sync (
  input logic clk,
  input logic rst,
  output logic o_pix_valid,
  output logic [9:0] o_col,
  output logic [9:0] o_row,
  output logic o_hsync,
  output logic o_vsync
);


parameter int FRAME_HSPULSE = 96;
parameter int FRAME_HBPORCH = 48;
parameter int FRAME_HPIXELS = 640;
parameter int FRAME_HFPORCH = 16;
parameter int FRAME_MAX_HCOUNT = 800;

parameter int FRAME_VSPULSE = 2;
parameter int FRAME_VBPORCH = 29;
parameter int FRAME_VLINES = 480;
parameter int FRAME_VFPORCH = 10;
parameter int FRAME_MAX_VCOUNT = 521;

logic [9:0] hcnt;
logic [9:0] vcnt;
logic hsync_d;
logic hsync_q;

logic hsync_d_delayed;
logic hsync_q_delayed;

logic vsync_d;
logic vsync_q;

always_ff @(posedge clk) begin
  if (rst) begin
    hcnt <= 0;
    vcnt <= 0;
    hsync_q <= 1'b0;
    vsync_q <= 1'b0;
    hsync_q_delayed <= 1'b0;
  end else begin
    hsync_q <= hsync_d;
    hsync_q_delayed <= hsync_d_delayed;
    vsync_q <= vsync_d;
    if (hcnt == FRAME_MAX_HCOUNT - 1) begin
      hcnt <= 0;
      if(vcnt == FRAME_MAX_VCOUNT - 1) begin
        vcnt <= 0;
      end else begin
        vcnt <= vcnt + 1;
      end
    end else begin
      hcnt <= hcnt + 1;
      vcnt <= vcnt;
    end
  end
end

logic hs_set;
logic hs_clr;
logic vs_set;
logic vs_clr;

always_comb begin
  hsync_d = hsync_q; //keep prev value - default
  hsync_d_delayed = hsync_q_delayed; //keep prev value - default
  vsync_d = vsync_q; //keep prev value - default
  hs_set = 1'b0;
  hs_clr = 1'b0;
  vs_set = 1'b0;
  vs_clr = 1'b0;

  if(hcnt == FRAME_HPIXELS + FRAME_HFPORCH - 1) begin
    hs_set = 1'b1;
  end
  else hs_set = 1'b0;

  if(hcnt == FRAME_HPIXELS + FRAME_HFPORCH + FRAME_HSPULSE - 1) begin
     hs_clr = 1'b1;
  end
  else begin 
    hs_clr = 1'b0;   
  end  

  if(vcnt == FRAME_VLINES + FRAME_VFPORCH - 1) begin
    if(hcnt == FRAME_MAX_HCOUNT - 1) begin
       vs_set = 1'b1;
    end
    else vs_set = 1'b0;
  end

  if(vcnt == FRAME_VLINES + FRAME_VFPORCH + FRAME_VSPULSE - 1) begin
    if(hcnt == FRAME_MAX_HCOUNT - 1) begin
       vs_clr = 1'b1;
    end
    else vs_clr = 1'b0;
  end

  if(hcnt < FRAME_HPIXELS && vcnt < FRAME_VLINES) begin
    o_pix_valid = 1'b1;
  end else begin
    o_pix_valid = 1'b0;
  end

  hsync_d = (hs_set | hsync_q) & ~hs_clr;
  hsync_d_delayed = hsync_q;
  vsync_d = (vs_set | vsync_q) & ~vs_clr;
  o_hsync = ~hsync_q_delayed;
  o_vsync = ~vsync_q;
  o_col = hcnt[9:0];
  o_row = vcnt[9:0];
end



endmodule
