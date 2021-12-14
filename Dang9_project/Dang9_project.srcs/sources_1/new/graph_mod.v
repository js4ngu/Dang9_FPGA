`include "defines.v"

module graph_mod (
    input clk, 
    input rst, 
    
    input [9:0] x, 
    input [9:0] y, 
    
    input [4:0] key, 
    input [4:0] key_pulse, 
    
    output [2:0] rgb
    );

// RGB �÷���
wire [1:0] ball_rgb;
wire [1:0] cue_rgb;
wire [3:0] hole_rgb;
wire       table_rgb;
wire       font;

// �ν��Ͻ�
ball       ball_inst   (clk, rst, x, y, key, key_pulse, ball_rgb, cue_rgb, font);
table_mod  table_inst  (clk, rst, x, y, table_rgb);
hole       hole_inst   (clk, rst, x, y, hole_rgb);

// ���� ���
assign rgb = (font == 1)           ? `WHITE   : // ���� ���� �� ��Ʈ ����
             (ball_rgb[0] == 1)    ? `YELLOW  : // ��A
             (ball_rgb[1] == 1)    ? `RED    : // ��B
             //(ball_rgb[2] == 1)    ? `GREEN  : // �浹

             (cue_rgb[0] == 1)     ? `YELLOW : // ��A ť
             (cue_rgb[1] == 1)     ? `RED  : // ��B ť

             (hole_rgb[0] == 1)    ? `BLACK  : // ȦA
             (hole_rgb[1] == 1)    ? `BLACK  : // ȦB
             (hole_rgb[2] == 1)    ? `BLACK  : // ȦC
             (hole_rgb[3] == 1)    ? `BLACK  : // ȦD

             (table_rgb == 1)      ? `WHITE  : // ���̺�
                                     `BLACK; 
endmodule