`include "defines.v"

module ball(
    input clk, 
    input rst,

    input [9:0] x, 
    input [9:0] y, 
    
    input [4:0] key, 
    input [4:0] key_pulse, 

    output [8:0] ball_rgb
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

reg [2:0] flag;
reg [4:0] cnt4;
reg [4:0] ratio;

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
// HOLE 
//
//  A--------------B
//  |              |
//  |              |
//  C--------------D
//
/*---------------------------------------------------------*/
parameter HOLE_CA_X = 40;
parameter HOLE_CA_Y = 40;
parameter HOLE_CB_X = 600;
parameter HOLE_CB_Y = 40;
parameter HOLE_CC_X = 40;
parameter HOLE_CC_Y = 440;
parameter HOLE_CD_X = 600;
parameter HOLE_CD_Y = 440;
parameter HOLE_SIZE = 30;

reg ha_ba, ha_bb;
reg hb_ba, hb_bb;
reg hc_ba, hc_bb;
reg hd_ba, hd_bb;

reg Ball_a_Hole_Flag, Ball_b_Hole_Flag;


always @(posedge clk or posedge rst) begin
    if (rst) begin

    end
    else begin
        ha_bb = (HOLE_SIZE * HOLE_SIZE >= (HOLE_CA_X-cbx)*(HOLE_CA_X-cbx) + (HOLE_CA_Y-cby)*(HOLE_CA_Y-cby)) ? 1 : 0; // holeA-ballaB ?�� ????
        hb_ba = (HOLE_SIZE * HOLE_SIZE >= (HOLE_CB_X-cax)*(HOLE_CB_X-cax) + (HOLE_CB_Y-cay)*(HOLE_CB_Y-cay)) ? 1 : 0; // holeA-ballaA ?�� ????
        hb_bb = (HOLE_SIZE * HOLE_SIZE >= (HOLE_CB_X-cbx)*(HOLE_CB_X-cbx) + (HOLE_CB_Y-cby)*(HOLE_CB_Y-cby)) ? 1 : 0; // holeA-ballaB ?�� ????
        hc_ba = (HOLE_SIZE * HOLE_SIZE >= (HOLE_CC_X-cax)*(HOLE_CC_X-cax) + (HOLE_CC_Y-cay)*(HOLE_CC_Y-cay)) ? 1 : 0; // holeA-ballaA ?�� ????
        hc_bb = (HOLE_SIZE * HOLE_SIZE >= (HOLE_CC_X-cbx)*(HOLE_CC_X-cbx) + (HOLE_CC_Y-cby)*(HOLE_CC_Y-cby)) ? 1 : 0; // holeA-ballaB ?�� ????
        hd_ba = (HOLE_SIZE * HOLE_SIZE >= (HOLE_CD_X-cax)*(HOLE_CD_X-cax) + (HOLE_CD_Y-cay)*(HOLE_CD_Y-cay)) ? 1 : 0; // holeA-ballaA ?�� ????
        hd_bb = (HOLE_SIZE * HOLE_SIZE >= (HOLE_CD_X-cbx)*(HOLE_CD_X-cbx) + (HOLE_CD_Y-cby)*(HOLE_CD_Y-cby)) ? 1 : 0; // holeA-ballaB ?�� ????

        Ball_a_Hole_Flag = (ha_ba || hb_ba || hc_ba || hd_ba);
        Ball_b_Hole_Flag = (ha_bb || hb_bb || hc_bb || hd_bb);
    end
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

reg PLAYER1_WIN_FLAG, PLAYER2_WIN_FLAG;
always@(posedge clk or posedge rst) begin
    if(rst) begin
        game_status <= PLAYER1;
        PLAYER1_WIN_FLAG <= 0;
        PLAYER2_WIN_FLAG <= 0;
        cue_1_flag <= 0;
        cue_2_flag <= 0;
    end
    else begin
        case(game_status)
            PLAYER1 : begin // PLAYER1�� ���� ĥ ����
                //if(key_pulse == 5'h10) game_status <= PLAYER1_PLAY;
                cue_1_flag <= 1;
                if((vax1 != 0) || (vay1 != 0) || (vbx1 != 0) || (vby1 != 0)) game_status <= PLAYER1_PLAY;
            end
            PLAYER1_PLAY : begin // PLAYER1�� ���� ģ �� ������ �����̴� ����
                cue_1_flag <= 0;
                if(Ball_a_Hole_Flag)begin
                    game_status <= PLAYER2_WIN;
                end
                else if(Ball_b_Hole_Flag)begin
                    game_status <= PLAYER1_WIN;
                end
                else if((vax1 == 0) && (vay1 == 0) && (vbx1 == 0) && (vby1 == 0)) begin
                    game_status <= PLAYER2;
                end
            end
            PLAYER2 : begin // PLAYER2�� ���� ĥ ����
                cue_2_flag <= 1;

                if(key_pulse == 5'h10) begin
                    game_status <= PLAYER2_PLAY;
                end
            end
            PLAYER2_PLAY : begin // PLAYER2�� ���� ģ �� ������ �����̴� ����
                cue_2_flag <= 0;

                if(Ball_a_Hole_Flag)begin
                    game_status = PLAYER1_WIN;
                end
                else if(Ball_b_Hole_Flag)begin
                    game_status = PLAYER2_WIN;
                end
                if((vax1 == 0) && (vay1 == 0) && (vbx1 == 0) && (vby1 == 0)) begin
                    game_status = PLAYER1;
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
// ��A, B, Hole, ť�� �׸���
/*---------------------------------------------------------*/
assign ball_rgb[0] = (`BALL_R*`BALL_R >= (x-cax)*(x-cax) + (y-cay)*(y-cay)) ? 1 : 0;
assign ball_rgb[1] = (`BALL_R*`BALL_R >= (x-cbx)*(x-cbx) + (y-cby)*(y-cby)) ? 1 : 0;
assign ball_rgb[2] = (ba_bb || PLAYER1_WIN_FLAG || PLAYER1_WIN_FLAG); // Flag indicate


assign ball_rgb[3] = (HOLE_SIZE * HOLE_SIZE >= (x - HOLE_CA_X)*(x - HOLE_CA_X) + (y - HOLE_CA_Y)*(y - HOLE_CA_Y)) ? 1 : 0;
assign ball_rgb[4] = (HOLE_SIZE * HOLE_SIZE >= (x - HOLE_CB_X)*(x - HOLE_CB_X) + (y - HOLE_CB_Y)*(y - HOLE_CB_Y)) ? 1 : 0;
assign ball_rgb[5] = (HOLE_SIZE * HOLE_SIZE >= (x - HOLE_CC_X)*(x - HOLE_CC_X) + (y - HOLE_CC_Y)*(y - HOLE_CC_Y)) ? 1 : 0;
assign ball_rgb[6] = (HOLE_SIZE * HOLE_SIZE >= (x - HOLE_CD_X)*(x - HOLE_CD_X) + (y - HOLE_CD_Y)*(y - HOLE_CD_Y)) ? 1 : 0;
assign ball_rgb[7] = (cue_1_flag == 1) ? ((CUE_BALL_SIZE * CUE_BALL_SIZE >= (x - ba_cue_x)*(x - ba_cue_x) + (y - ba_cue_y)*(y - ba_cue_y)) ? 1 : 0) : 0;
assign ball_rgb[8] = (cue_2_flag == 1) ? ((CUE_BALL_SIZE * CUE_BALL_SIZE >= (x - bb_cue_x)*(x - bb_cue_x) + (y - bb_cue_y)*(y - bb_cue_y)) ? 1 : 0) : 0;
//assign ball_rgb[7] = cue_1_flag;
endmodule 