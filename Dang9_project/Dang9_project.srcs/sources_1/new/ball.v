`include "defines.v"

module ball(
    input clk, 
    input rst,

    input [9:0] x, 
    input [9:0] y, 
    
    input [4:0] key, 
    input [4:0] key_pulse, 

    output [1:0] ball_rgb,
    output [1:0] cue_rgb,
    output font
    );

// ��������
parameter BA_START_X = `MAX_X/3;
parameter BA_START_Y = `MAX_Y/2;
parameter BB_START_X = `MAX_X/3*2;
parameter BB_START_Y = `MAX_Y/2;

parameter MAX_ba_HIT_FORCE = 12;
parameter MAT_ba_HIT_ANGLE = 360;

// 60Hz clock
wire refr_tick; 
assign refr_tick = (y==`MAX_Y-1 && x==`MAX_X-1)? 1 : 0; 

// ��A�� ����
wire signed [1:0] dax, day;
reg signed [1:0] dax1, day1;  // ���� ����
wire signed [4:0] vax, vay;
reg signed [4:0] vax1, vay1;  // ���� �ӵ�
reg signed [9:0] vax_reg, vay_reg;
reg [9:0] cax, cay; // ��A �߽���ǥ

// ��B�� ����
wire signed [1:0] dbx, dby; 
reg signed [1:0] dbx1, dby1; // ���� ����
wire signed [4:0] vbx, vby;
reg signed [4:0] vbx1, vby1;// ���� �ӵ�
reg signed [9:0] vbx_reg, vby_reg;
reg [9:0] cbx, cby; // ��B �߽���ǥ

/*---------------------------------------------------------*/
// �浹 ����
//
// <����>
//  ��-���̺� �浹 �Ǵ� ��A-��B �浹�� ����
/*---------------------------------------------------------*/
wire ba_top, ba_bottom, ba_left, ba_right;  // ��A-���̺� �浹 �÷���
wire bb_top, bb_bottom, bb_left, bb_right;  // ��B-���̺� �浹 �÷���
wire ba_bb; // ��A-��B �浹 �÷���

assign ba_top    = (`TABLE_IN_T >= (cay - `BALL_R)) ? 1 : 0;  // ��A-���̺� �浹 ����
assign ba_bottom = (`TABLE_IN_B <= (cay + `BALL_R)) ? 1 : 0;
assign ba_left   = (`TABLE_IN_L >= (cax - `BALL_R)) ? 1 : 0;
assign ba_right  = (`TABLE_IN_R <= (cax + `BALL_R)) ? 1 : 0;

assign bb_top    = (`TABLE_IN_T >= (cby - `BALL_R)) ? 1 : 0;// ��B-���̺� �浹 ����
assign bb_bottom = (`TABLE_IN_B <= (cby + `BALL_R)) ? 1 : 0;
assign bb_left   = (`TABLE_IN_L >= (cbx - `BALL_R)) ? 1 : 0;
assign bb_right  = (`TABLE_IN_R <= (cbx + `BALL_R)) ? 1 : 0;

assign ba_bb = (`BALL_D*`BALL_D >= (cbx-cax)*(cbx-cax) + (cby-cay)*(cby-cay)) ? 1 : 0;  // ��A-��B �浹 ����


/*---------------------------------------------------------*/
// �� �߻�
//
// <����>
//  Ű�е带 �̿��Ͽ� ��A �Ǵ� ��B�� �߻�. 
//  �ð��� ���� ���� �ӷ��� ���� �����ϰ� �ᱹ�� ����.
//
// <���۹�>
//  KEY[1] : �ݽð� �������� ���� ȸ��
//  KEY[7] : �ð� �������� ���� ȸ��
//  KEY[4] : ġ�� ��(�ӷ�) ����?
//  KEY[0] : �� �߻�
//
// <NOTE>
//  ġ�� ���� ���� �ӷ����� ġȯ��
//  ���۰��� : 0��
//  �Էµ� ���� ������ deg_set����� ���� ���� �ӵ��� ��ȯ
/*---------------------------------------------------------*/

/*---------------------------------------------------------*/
// �� �߻� �ӷ�
/*---------------------------------------------------------*/
reg [6:0] cnt1, cnt2;  // Ű �Է� ����
reg [5:0] hit_force_t; // �ӽ� �ӷ�
reg [5:0] ba_hit_force, bb_hit_force; // ��A, ��B �ӷ�

always @(posedge clk or posedge rst) begin // ���߻� �ӷ�
   if(rst) begin
       ba_hit_force <= 0;
       bb_hit_force <= 0;
   end
   else if(refr_tick) begin
        if(key == 5'h14) begin// KEY[4] ������ ������ ġ�� ���� Ŀ��
            if(hit_force_t < MAX_ba_HIT_FORCE && cnt1 > 5) begin
                hit_force_t <= hit_force_t + 1;
                cnt1 <= 0;
            end
            else begin
                cnt1 <= cnt1 + 1;
            end
        end
        if (cnt2 == 20) begin// �ð��� ���� �ӷ� ����
            if (bb_hit_force > 0) begin
                bb_hit_force <= bb_hit_force - 1;
            end
            if (ba_hit_force > 0) begin
                ba_hit_force <= ba_hit_force - 1;
            end
            cnt2 <= 0;
        end
        else begin
            cnt2 <= cnt2 + 1;
        end
    end
    else if(key_pulse == 5'h10) begin // �����
        if (game_status == PLAYER1) begin // �÷��̾�1�� ������ �� ��A�� ħ
            ba_hit_force <= hit_force_t;
            hit_force_t <= 0;
        end
        else if (game_status == PLAYER2) begin // �÷��̾��� ������ �� ��B�� ħ
            bb_hit_force <= hit_force_t;
            hit_force_t <= 0;
        end
    end
    else if (ba_bb) begin // ��A-��B �浹
        if (game_status == PLAYER1_PLAY) begin // �浹 �� ��A�� �ӷ¸� ��B�� ����
            bb_hit_force <= ba_hit_force;
        end
        else if (game_status == PLAYER2_PLAY) begin // �浹 �� ��B�� �ӷ¸� ��A�� ����
            ba_hit_force <= bb_hit_force;
        end
    end
end

/*---------------------------------------------------------*/
// �� �߻� ����
/*---------------------------------------------------------*/
reg [6:0] cnt3;
reg [8:0] hit_angle_t; // �ӽ� ����
reg [8:0] ba_hit_angle, bb_hit_angle; // ��A, ��B ����

always @(posedge clk or posedge rst) begin // ���߻� ����
    if(rst) begin
        ba_hit_angle <= 0;
    end
    else if (refr_tick) begin
        if (key == 5'h11) begin // KEY[1] ������ ������ ���� ����
            if (cnt3 > 3) begin
                if (hit_angle_t < 360) begin
                    hit_angle_t <= hit_angle_t + 5;
                    cnt3 <= 0;
                end
                else if (hit_angle_t == 360) begin // ���� ������ 360���̸� 0���� ��ȯ
                    hit_angle_t <= 0;
                end
            end
            else begin
                cnt3 <= cnt3 + 1;
            end
        end
        if (key == 5'h17) begin  // KEY[7] ������ ������ ���� ����
            if (cnt3 > 3) begin
                if (hit_angle_t > 0) begin
                    hit_angle_t <= hit_angle_t - 5;
                    cnt3 <= 0;
                end
                else if (hit_angle_t == 0) begin // ���� ������ 0���̸� 360���� ��ȯ
                    hit_angle_t <= 360;
                end
            end
            else begin
                cnt3 <= cnt3 + 1;
            end
        end
    end
    else if(key_pulse == 5'h10) begin // �����
        if (game_status == PLAYER1) begin
            ba_hit_angle <= hit_angle_t;
            hit_angle_t <= 0;
        end
        else if (game_status == PLAYER2) begin
            bb_hit_angle <= hit_angle_t;
            hit_angle_t <= 0;
        end
    end
    else if (ba_bb) begin // ��A-��B �浹
        if (game_status == PLAYER1_PLAY) begin // �浹 �� ��A�� ������ ��B�� ����
            bb_hit_angle <= ba_hit_angle;
        end
        else if (game_status == PLAYER2_PLAY) begin // �浹 �� ��B�� ������ ��A�� ����
            ba_hit_angle <= bb_hit_angle;
        end
    end
end


/*---------------------------------------------------------*/
// ������ �浹 �� �� �ӵ�
//
// <����>
//  ��A-��B �浹 �� ��B �ӵ� ������Ʈ
/*---------------------------------------------------------*/
/*
reg [5:0] cnt5;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        bb_hit_force <= 0;
        bb_hit_angle <= 0;
    end
    else if (ba_bb) begin
        if (game_status == PLAYER1_PLAY) begin // �浹 �� ��A�� �ӵ��� ��B�� ����
            bb_hit_force <= ba_hit_force;
            bb_hit_angle <= ba_hit_angle;
        end
        else if (game_status == PLAYER2_PLAY) begin // �浹 �� ��B�� �ӵ��� ��A�� ����
            ba_hit_force <= bb_hit_force;
            ba_hit_angle <= bb_hit_angle;
        end
    end
    else if (refr_tick) begin
        if (cnt5 == 20) begin
            if (game_status == PLAYER1_PLAY && bb_hit_force > 0) begin
            bb_hit_force <= bb_hit_force - 1;
            cnt5 <= 0;
            end
            else if (game_status == PLAYER2_PLAY && ba_hit_force > 0) begin
            ba_hit_force <= ba_hit_force - 1;
            cnt5 <= 0;
            end
        end
        else begin
            cnt5 <= cnt5 + 1;
        end
    end
end
*/

/*---------------------------------------------------------*/
// ���� ���ӵ� ���
//
// <����>
//  deg_set ����� �̿��Ͽ� ���� �ӷ°� ������ ���� �� �ӵ��� ���
/*---------------------------------------------------------*/
deg_set deg_set_ba (ba_hit_force, ba_hit_angle, vax, vay, dax, day);// ġ�� ���� ������ �޾Ƽ� ���ӵ� ���
deg_set deg_set_bb (bb_hit_force, bb_hit_angle, vbx, vby, dbx, dby); // ġ�� ���� ������ �޾Ƽ� ���ӵ� ���


/*---------------------------------------------------------*/
// ��A�� ��ġ
//
// <����>
//  ����� �ӷ��� ����� ����. 
//  ����� �ӷ��� ���ؼ� ���� �ӵ��� ��A�� �߽���ǥ ������Ʈ
/*---------------------------------------------------------*/
reg ba_collision;

always @(posedge clk or posedge rst) begin // ��A�� ����
    if(rst | key_pulse == 5'h10) begin 
        dax1 <= 0;
        day1 <= 0;
        ba_collision <= 0;
    end
    else begin
        if(ba_top) begin // ���̺� ���� �浹
            day1 <= 1;
            ba_collision <= 1;
        end
        else if (ba_bottom) begin   // ���̺� �Ʒ��� �浹
            day1 <= -1;
            ba_collision <= 1;
        end
        else if (ba_left) begin // ���̺� ���� �浹
            dax1 <= 1;
            ba_collision <= 1;
        end
        else if (ba_right) begin // ���̺� ������ �浹
            dax1 <= -1;
            ba_collision <= 1;
        end
        else if (ba_bb) begin // ��B�� �浹
            if (cbx-cax >= 0)     dax1 <= -1;
            else if (cbx-cax < 0) dax1 <=  1;
            if (cby-cay >= 0)     day1 <= -1;
            else if (cby-cay < 0) day1 <=  1;
            ba_collision <= 1;
        end
        else if(ba_collision == 0) begin// deg_set���� ����ϴ� ������ �־���
            dax1 <= dax;
            day1 <= day;
        end
    end
end

always @ (posedge clk or posedge rst) begin // ��A�� �ӷ�
    if(rst) begin
        vax1 <= 0;
        vay1 <= 0;
    end
    else begin
        vax1 <= vax;
        vay1 <= vay;
    end
end

always @(posedge clk or posedge rst) begin // ��A ���� �ӵ�
    if(rst) begin
        vax_reg <= 0;
        vay_reg <= 0;
    end
    else begin
        vax_reg <= dax1*vax1;
        vay_reg <= day1*vay1;
    end
end

always @(posedge clk or posedge rst) begin // ��A �߽� ��ǥ ������Ʈ
    if(rst) begin
        cax <= BA_START_X;
        cay <= BA_START_Y;
    end
    else if(refr_tick) begin
        cax <= cax + vax_reg;
        cay <= cay + vay_reg;
    end
end

/*---------------------------------------------------------*/
// ��B�� ��ġ
//
// <����>
//  ����� �ӷ��� ����� ����. 
//  ����� �ӷ��� ���ؼ� ���� �ӵ��� ��B�� �߽���ǥ ������Ʈ
/*---------------------------------------------------------*/
reg bb_collision;

always @(posedge clk or posedge rst) begin // ��B�� ����
    if(rst | key_pulse == 5'h10) begin
        dbx1 <= 0;
        dby1 <= 0;
        bb_collision <= 0;
    end
    else begin
        if(bb_top) begin
            dby1 <= 1;
            bb_collision <= 1;
        end
        else if (bb_bottom) begin
            dby1 <= -1;
            bb_collision <= 1;
        end
        else if (bb_left) begin
            dbx1 <= 1;
            bb_collision <= 1;
        end
        else if (bb_right) begin 
            dbx1 <= -1;
            bb_collision <= 1;
        end
        else if (ba_bb) begin // ��A�� �浹
            if (cbx-cax >= 0)     dbx1 <=  1;
            else if (cbx-cax < 0) dbx1 <= -1;
            if (cby-cay >= 0)     dby1 <=  1;
            else if (cby-cay < 0) dby1 <= -1;
            bb_collision <= 1;
        end
        else if(bb_collision == 0) begin// deg_set���� ����ϴ� ������ �־���
            dbx1 <= dbx;
            dby1 <= dby;
        end
    end
end

always @ (posedge clk or posedge rst) begin // ��B�� �ӷ�
    if(rst) begin
        vbx1 <= 0;
        vby1 <= 0;
    end
    else begin
        vbx1 <= vbx;
        vby1 <= vby;
    end
end

always @(posedge clk or posedge rst) begin// ��B ���� �ӵ�
    if(rst) begin
        vbx_reg <= 0;
        vby_reg <= 0;
    end
    else begin
        vbx_reg <= dbx1*vbx1;
        vby_reg <= dby1*vby1;
    end
end

always @(posedge clk or posedge rst) begin // ��B �߽� ��ǥ ������Ʈ
    if(rst) begin
        cbx <= BB_START_X;
        cby <= BB_START_Y;
    end
    else if(refr_tick) begin
        cbx <= cbx + vbx_reg;
        cby <= cby + vby_reg;
    end
end

/*---------------------------------------------------------*/
// Ȧ-�� �ν�
//
// [����]
//  ���� Ȧ�� �������� �ν���.
//
//  A--------------B
//  |              |
//  |              |
//  C--------------D
//
/*---------------------------------------------------------*/
/*
parameter HOLE_CA_X = 40;
parameter HOLE_CA_Y = 40;
parameter HOLE_CB_X = 600;
parameter HOLE_CB_Y = 40;
parameter HOLE_CC_X = 40;
parameter HOLE_CC_Y = 440;
parameter HOLE_CD_X = 600;
parameter HOLE_CD_Y = 440;
parameter HOLE_R = 30;
*/

reg ha_ba, hb_ba, hc_ba, hd_ba; // Ȧ-��A �ν� �÷���
reg ha_bb, hb_bb, hc_bb, hd_bb; // Ȧ-��B �ν� �÷���

reg Ball_a_Hole_Flag, Ball_b_Hole_Flag;

always @ (*) begin
    ha_ba = (`HOLE_R * `HOLE_R >= (`HOLE_CA_X-cbx)*(`HOLE_CA_X-cbx) + (`HOLE_CA_Y-cay)*(`HOLE_CA_Y-cay)) ? 1 : 0; // ȦA-��A
    hb_ba = (`HOLE_R * `HOLE_R >= (`HOLE_CB_X-cax)*(`HOLE_CB_X-cax) + (`HOLE_CB_Y-cay)*(`HOLE_CB_Y-cay)) ? 1 : 0; // ȦB-��A
    hc_ba = (`HOLE_R * `HOLE_R >= (`HOLE_CC_X-cax)*(`HOLE_CC_X-cax) + (`HOLE_CC_Y-cay)*(`HOLE_CC_Y-cay)) ? 1 : 0; // ȦC-��A
    hd_ba = (`HOLE_R * `HOLE_R >= (`HOLE_CD_X-cax)*(`HOLE_CD_X-cax) + (`HOLE_CD_Y-cay)*(`HOLE_CD_Y-cay)) ? 1 : 0; // ȦD-��A
    ha_bb = (`HOLE_R * `HOLE_R >= (`HOLE_CA_X-cbx)*(`HOLE_CA_X-cbx) + (`HOLE_CA_Y-cby)*(`HOLE_CA_Y-cby)) ? 1 : 0; // ȦA-��B
    hb_bb = (`HOLE_R * `HOLE_R >= (`HOLE_CB_X-cbx)*(`HOLE_CB_X-cbx) + (`HOLE_CB_Y-cby)*(`HOLE_CB_Y-cby)) ? 1 : 0; // ȦB-��B
    hc_bb = (`HOLE_R * `HOLE_R >= (`HOLE_CC_X-cbx)*(`HOLE_CC_X-cbx) + (`HOLE_CC_Y-cby)*(`HOLE_CC_Y-cby)) ? 1 : 0; // ȦC-��B
    hd_bb = (`HOLE_R * `HOLE_R >= (`HOLE_CD_X-cbx)*(`HOLE_CD_X-cbx) + (`HOLE_CD_Y-cby)*(`HOLE_CD_Y-cby)) ? 1 : 0; // ȦD-��B

    Ball_a_Hole_Flag = (ha_ba || hb_ba || hc_ba || hd_ba);
    Ball_b_Hole_Flag = (ha_bb || hb_bb || hc_bb || hd_bb);
end

/*---------------------------------------------------------*/
// CUE
/*---------------------------------------------------------*/
wire [9:0] ba_cue_x, ba_cue_y; // ��A ť�� ��ǥ
wire [9:0] bb_cue_x, bb_cue_y; // ��B ť�� ��ǥ
parameter CUE_BALL_SIZE = 5;

cue_deg cue_deg_ba (hit_angle_t, cax, cay, ba_cue_x, ba_cue_y);
cue_deg cue_deg_bb (hit_angle_t, cbx, cby, bb_cue_x, bb_cue_y);


/*---------------------------------------------------------*/
// FSM
/*---------------------------------------------------------*/
parameter PLAYER1 = 0, PLAYER1_PLAY = 1;
parameter PLAYER2 = 2, PLAYER2_PLAY = 3;
parameter PLAYER1_WIN = 4, PLAYER2_WIN = 5;

reg [4:0] game_status;
reg cue_1_flag, cue_2_flag;
reg ba_flag, bb_flag; // ���� ���ۿ� ���� �� �÷���

reg PLAYER1_WIN_FLAG, PLAYER2_WIN_FLAG;
always @ (posedge clk or posedge rst) begin
    if(rst) begin
        game_status <= PLAYER1;
        PLAYER1_WIN_FLAG <= 0;
        PLAYER2_WIN_FLAG <= 0;
        cue_1_flag <= 0;
        cue_2_flag <= 0;
        ba_flag <= 0;
        bb_flag <= 0;
    end
    else begin
        case(game_status)
            PLAYER1 : begin // PLAYER1�� ���� ĥ ����
                cue_1_flag <= 1;
                if((vax1 != 0) || (vay1 != 0) || (vbx1 != 0) || (vby1 != 0)) game_status <= PLAYER1_PLAY;
            end
            PLAYER1_PLAY : begin // PLAYER1�� ���� ģ �� ������ �����̴� ����
                cue_1_flag <= 0;

                if(Ball_a_Hole_Flag)begin
                    game_status <= PLAYER2_WIN;
                    ba_flag <= 1;
                end
                else if(Ball_b_Hole_Flag)begin
                    game_status <= PLAYER1_WIN;
                    bb_flag <= 1;
                end
                else if((vax1 == 0) && (vay1 == 0) && (vbx1 == 0) && (vby1 == 0)) begin
                    game_status <= PLAYER2;
                end
            end
            PLAYER2 : begin // PLAYER2�� ���� ĥ ����
                cue_2_flag <= 1;
                if((vax1 != 0) || (vay1 != 0) || (vbx1 != 0) || (vby1 != 0)) game_status <= PLAYER2_PLAY;
            end
            PLAYER2_PLAY : begin // PLAYER2�� ���� ģ �� ������ �����̴� ����
                cue_2_flag <= 0;

                if(Ball_a_Hole_Flag)begin
                    game_status <= PLAYER2_WIN;
                    ba_flag <= 1;
                end
                else if(Ball_b_Hole_Flag)begin
                    game_status <= PLAYER1_WIN;
                    bb_flag <= 1;
                end
                if((vax1 == 0) && (vay1 == 0) && (vbx1 == 0) && (vby1 == 0)) begin
                    game_status <= PLAYER1;
                end
            end
            PLAYER1_WIN : begin
                PLAYER1_WIN_FLAG <= 1;
            end
            PLAYER2_WIN : begin
                PLAYER2_WIN_FLAG <= 1;
            end
        endcase
    end
end

/*---------------------------------------------------------*/
// text on screen 
/*---------------------------------------------------------*/
// P1_win region
wire [6:0] char_addr1;
reg [6:0] char_addr1_s1;
wire [2:0] bit_addr1;
reg [2:0] bit_addr1_s1;
wire [3:0] row_addr1, row_addr1_s1; 
wire P1_win_on1;

wire font_bit1;
wire [7:0] font_word1;
wire [10:0] rom_addr1;

parameter xFont = 235;
parameter yFont = 236;

font_rom_vhd font_rom_inst1 (clk, rom_addr1, font_word1);

assign rom_addr1 = {char_addr1, row_addr1};
assign font_bit1 = font_word1[~bit_addr1]; //ȭ�� x��ǥ�� ������ ������, rom�� bit�� �������� �����Ƿ� reverse

assign char_addr1 = (P1_win_on1)? char_addr1_s1 : 0;
assign row_addr1  = (P1_win_on1)? row_addr1_s1  : 0; 
assign bit_addr1  = (P1_win_on1)? bit_addr1_s1  : 0; 

// LINE1
wire [9:0] P1_win_x_l1, P1_win_y_t1;
assign P1_win_x_l1 = xFont; 
assign P1_win_y_t1 = yFont; 
assign P1_win_on1 = (y>=P1_win_y_t1 && y<P1_win_y_t1+16 && x>=P1_win_x_l1 && x<P1_win_x_l1+8*11)? 1 : 0; 
assign row_addr1_s1 = y-P1_win_y_t1;


always @ (*) begin
    if      (x>=P1_win_x_l1+8*0 && x<P1_win_x_l1+8*1) begin 
        if(PLAYER1_WIN_FLAG || PLAYER2_WIN_FLAG) begin bit_addr1_s1 = x-P1_win_x_l1-8*0; char_addr1_s1 = 7'b101_0000; end // P X50
        else begin  bit_addr1_s1 = x-P1_win_x_l1-8*6; char_addr1_s1 = 7'b000_0000; end
    end
    else if (x>=P1_win_x_l1+8*1 && x<P1_win_x_l1+8*2) begin 
        if(PLAYER1_WIN_FLAG || PLAYER2_WIN_FLAG) begin bit_addr1_s1 = x-P1_win_x_l1-8*1; char_addr1_s1 = 7'b100_1100; end // L X4C
        else begin  bit_addr1_s1 = x-P1_win_x_l1-8*6; char_addr1_s1 = 7'b000_0000; end
    end
    else if (x>=P1_win_x_l1+8*2 && x<P1_win_x_l1+8*3) begin 
        if(PLAYER1_WIN_FLAG || PLAYER2_WIN_FLAG)begin bit_addr1_s1 = x-P1_win_x_l1-8*2; char_addr1_s1 = 7'b100_0001; end // A X41
        else begin  bit_addr1_s1 = x-P1_win_x_l1-8*6; char_addr1_s1 = 7'b000_0000; end
    end
    else if (x>=P1_win_x_l1+8*3 && x<P1_win_x_l1+8*4) begin 
        if(PLAYER1_WIN_FLAG || PLAYER2_WIN_FLAG)begin bit_addr1_s1 = x-P1_win_x_l1-8*3; char_addr1_s1 = 7'b101_1001; end // Y X59
        else begin  bit_addr1_s1 = x-P1_win_x_l1-8*6; char_addr1_s1 = 7'b000_0000; end
    end
    else if (x>=P1_win_x_l1+8*4 && x<P1_win_x_l1+8*5) begin 
        if(PLAYER1_WIN_FLAG || PLAYER2_WIN_FLAG)begin bit_addr1_s1 = x-P1_win_x_l1-8*4; char_addr1_s1 = 7'b100_0101; end // E x45
        else begin  bit_addr1_s1 = x-P1_win_x_l1-8*6; char_addr1_s1 = 7'b000_0000; end
    end
    else if (x>=P1_win_x_l1+8*5 && x<P1_win_x_l1+8*6) begin
        if(PLAYER1_WIN_FLAG || PLAYER2_WIN_FLAG)begin bit_addr1_s1 = x-P1_win_x_l1-8*5; char_addr1_s1 = 7'b101_0010; end // R x52
        else begin  bit_addr1_s1 = x-P1_win_x_l1-8*6; char_addr1_s1 = 7'b000_0000; end
    end

    else if (x>=P1_win_x_l1+8*6 && x<P1_win_x_l1+8*7) begin
        if(PLAYER1_WIN_FLAG)begin bit_addr1_s1 = x-P1_win_x_l1-8*6; char_addr1_s1 = 7'b011_0001; end // 1 x31
        else if(PLAYER2_WIN_FLAG)begin bit_addr1_s1 = x-P1_win_x_l1-8*6; char_addr1_s1 = 7'b011_0010; end // 2 x32
        else begin  bit_addr1_s1 = x-P1_win_x_l1-8*6; char_addr1_s1 = 7'b000_0000; end
    end

    else if (x>=P1_win_x_l1+8*7 && x<P1_win_x_l1+8*8) begin //NULL
        bit_addr1_s1 = x-P1_win_x_l1-8*7; char_addr1_s1 = 7'b000_0000;
    end
    else if (x>=P1_win_x_l1+8*8 && x<P1_win_x_l1+8*9) begin
        if(PLAYER1_WIN_FLAG || PLAYER2_WIN_FLAG)begin bit_addr1_s1 = x-P1_win_x_l1-8*8; char_addr1_s1 = 7'b101_0111; end // W x57
        else begin  bit_addr1_s1 = x-P1_win_x_l1-8*6; char_addr1_s1 = 7'b000_0000; end
    end
    else if (x>=P1_win_x_l1+8*9 && x<P1_win_x_l1+8*10) begin
        if(PLAYER1_WIN_FLAG || PLAYER2_WIN_FLAG)begin bit_addr1_s1 = x-P1_win_x_l1-8*9; char_addr1_s1 = 7'b100_1001; end // I x49
        else begin  bit_addr1_s1 = x-P1_win_x_l1-8*6; char_addr1_s1 = 7'b000_0000; end
    end
    else if (x>=P1_win_x_l1+8*10 && x<P1_win_x_l1+8*11) begin
        if(PLAYER1_WIN_FLAG || PLAYER2_WIN_FLAG)begin bit_addr1_s1 = x-P1_win_x_l1-8*10; char_addr1_s1 = 7'b100_1110; end // N x4e
        else begin  bit_addr1_s1 = x-P1_win_x_l1-8*6; char_addr1_s1 = 7'b000_0000; end
    end
    else begin bit_addr1_s1 = 0; char_addr1_s1 = 0; end                         
end


/*---------------------------------------------------------*/
// ��, ť �׸���
/*---------------------------------------------------------*/
assign ball_rgb[0] = (ba_flag == 1) ? 0 : // ��A�� ���ۿ� ���� ��A ����
                     (`BALL_R*`BALL_R >= (x-cax)*(x-cax) + (y-cay)*(y-cay)) ? 1 : 0;
assign ball_rgb[1] = (bb_flag == 1) ? 0 : // ��B�� ���ۿ� ���� ��B ����
                     (`BALL_R*`BALL_R >= (x-cbx)*(x-cbx) + (y-cby)*(y-cby)) ? 1 : 0;

assign cue_rgb[0] = (cue_1_flag == 1) ? ((CUE_BALL_SIZE * CUE_BALL_SIZE >= (x - ba_cue_x)*(x - ba_cue_x) + (y - ba_cue_y)*(y - ba_cue_y)) ? 1 : 0) : 0;
assign cue_rgb[1] = (cue_2_flag == 1) ? ((CUE_BALL_SIZE * CUE_BALL_SIZE >= (x - bb_cue_x)*(x - bb_cue_x) + (y - bb_cue_y)*(y - bb_cue_y)) ? 1 : 0) : 0;

assign font = (font_bit1 & P1_win_on1)? 1 : 0;

endmodule 