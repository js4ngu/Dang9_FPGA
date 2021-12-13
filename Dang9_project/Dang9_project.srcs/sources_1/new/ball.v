`include "defines.v"

module ball(
    input clk, 
    input rst,

    input [9:0] x, 
    input [9:0] y, 
    
    input [4:0] key, 
    input [4:0] key_pulse, 

    output [2:0] ball_rgb
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
reg signed [1:0] dax1, day1; // ���� ����
wire signed [4:0] vax, vay;
reg signed [4:0] vax1, vay1; // ���� �ӵ�
reg signed [9:0] vax_reg, vay_reg;
reg [9:0] cax, cay; // ��A �߽���ǥ
wire ba_top, ba_bottom, ba_left, ba_right; // ��A-���̺� �浹 �÷���

// ��B�� ����
wire signed [1:0] dbx, dby; 
reg signed [1:0] dbx1, dby1; // ���� ����
wire signed [4:0] vbx, vby;
reg signed [4:0] vbx1, vby1; // ���� �ӵ�
reg signed [9:0] vbx_reg, vby_reg;
reg [9:0] cbx, cby; // ��B �߽���ǥ
wire bb_top, bb_bottom, bb_left, bb_right; // ��B-���̺� �浹 �÷���

// �浹 ����
wire ba_bb;
reg state;
/*
reg [9:0] dx, dy;

reg [9:0] vax_p, vay_p;
reg [9:0] vbx_p, vby_p;

reg [9:0] vax_buf, vay_buf;
reg [9:0] vbx_buf, vby_buf;

reg [9:0] vax_new, vay_new;
reg [9:0] vbx_new, vby_new;
*/

/*---------------------------------------------------------*/
// �浹 ����
//
// <����>
//  ��-���̺� �浹 �Ǵ� ��A-��B �浹�� ����
/*---------------------------------------------------------*/

assign ba_top    = (`TABLE_IN_T >= (cay - `BALL_R)) ? 1 : 0; // ��A-���̺� �浹 ����
assign ba_bottom = (`TABLE_IN_B <= (cay + `BALL_R)) ? 1 : 0;
assign ba_left   = (`TABLE_IN_L >= (cax - `BALL_R)) ? 1 : 0;
assign ba_right  = (`TABLE_IN_R <= (cax + `BALL_R)) ? 1 : 0;

assign bb_top    = (`TABLE_IN_T >= (cby - `BALL_R)) ? 1 : 0; // ��B-���̺� �浹 ����
assign bb_bottom = (`TABLE_IN_B <= (cby + `BALL_R)) ? 1 : 0;
assign bb_left   = (`TABLE_IN_L >= (cbx - `BALL_R)) ? 1 : 0;
assign bb_right  = (`TABLE_IN_R <= (cbx + `BALL_R)) ? 1 : 0;

assign ba_bb = (`BALL_D*`BALL_D >= (cbx-cax)*(cbx-cax) + (cby-cay)*(cby-cay)) ? 1 : 0; // ��A-��B �浹 ����

/*---------------------------------------------------------*/
// ��A-��B �浹 �� �ӵ�
//
// <����>
//  ��A-��B �浹 �� �ӵ��� ����ϰ� ������Ʈ
/*---------------------------------------------------------*/
/*
always @ (*) begin 
    if(ba_bb && state == 0) begin
    vax_p = dbx*vbx*(cbx-cax) + dby*vby*(cby-cay);
    vay_p = day*vay*(cbx-cax) - dax*vax*(cby-cay);
    vbx_p = dax*vax*(cbx-cax) + day*vay*(cby-cay);
    vby_p = dby*vby*(cbx-cax) - dbx*vbx*(cby-cay);
   
    vax_buf = vax_p*(cbx-cax) - vay_p*(cby-cay);
    vay_buf = vax_p*(cby-cay) + vay_p*(cbx-cax);
    vbx_buf = vbx_p*(cbx-cax) - vby_p*(cby-cay);
    vby_buf = vbx_p*(cby-cay) + vby_p*(cbx-cax);

    // ���� �ӵ� ����� ��ȯ. ������ ���� ó��
    if (vax_buf[9] == 1'b1) vax_new = -1 * (vax_buf/12);
    else vax_new = (vax_buf/12);
    if (vay_buf[9] == 1'b1) vay_new = -1 * (vay_buf/12);
    else vay_new = (vay_buf/12);
    if (vbx_buf[9] == 1'b1) vbx_new = -1 * (vbx_buf/12);
    else vbx_new = (vbx_buf/12);
    if (vby_buf[9] == 1'b1) vby_new = -1 * (vby_buf/12);
    else vby_new = (vby_buf/12);

    //�ӵ� ����
    if (vax_new > 12) vax_new = 12;
    if (vay_new > 12) vay_new = 12;
    if (vbx_new > 12) vbx_new = 12;
    if (vby_new > 12) vby_new = 12;

    state = 1;
    end
    else if (ba_bb == 0 && state == 1) begin
        state = 0;
    end
end
*/

/*---------------------------------------------------------*/
// ��A-��B �浹 �� ��B�� �ӵ�
//
// <����>
//  ��A-��B �浹 �� ��B �ӵ� ������Ʈ
/*---------------------------------------------------------*/
reg [5:0] bb_hit_force_t, bb_hit_force;
reg [8:0] bb_hit_angle_t, bb_hit_angle;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        bb_hit_force <= 0;
        bb_hit_angle <= 0;
    end
    else if (ba_bb) begin
        bb_hit_force <= ba_hit_force;
        bb_hit_angle <= bb_hit_angle;
    end
end

/*---------------------------------------------------------*/
// ��A �߻�
//
// <����>
//  Ű�е带 �̿��Ͽ� ��A�� �߻�. �ð��� ���� ��A�� �ӷ��� ���� �����ϰ� �ᱹ�� ����.
//
// <���۹�>
//  KEY[1] : �ݽð� �������� ���� ȸ��
//  KEY[7] : �ð� �������� ���� ȸ��
//  KEY[4] : ġ�� ��(�ӷ�) ����?
//  KEY[0] : ��A �߻�
//
// <NOTE>
//  ġ�� ���� ���� �ӷ����� ġȯ��
//  ���۰��� : 0��
//  �Էµ� ���� ������ deg_set����� ���� ���� �ӵ��� ��ȯ
/*---------------------------------------------------------*/
reg [6:0] cnt1, cnt2, cnt3; // Ű �Է� ����
reg [5:0] ba_hit_force_t, ba_hit_force;
reg [8:0] ba_hit_angle_t, ba_hit_angle;
reg collision;

always @(posedge clk or posedge rst) begin // ġ�� �� ������Ʈ
   if(rst) begin
       ba_hit_force <= 0;
   end
   else if(refr_tick) begin
        if(key == 5'h14) begin // 4��Ű�� ������ ������ ġ�� ���� Ŀ��
            if(ba_hit_force_t < MAX_ba_HIT_FORCE && cnt1 > 5) begin
                ba_hit_force_t <= ba_hit_force_t + 1;
                cnt1 <= 0;
            end
            else begin
                cnt1 <= cnt1 + 1;
            end
        end
        if (cnt2 == 20 && ba_hit_force > 0) begin // ġ�� ���� 0 �̻��̸� �ֱ������� �پ����
            ba_hit_force <= ba_hit_force - 1;
            cnt2 <= 0;
        end
        else begin
            cnt2 <= cnt2 + 1;
        end
   end
   else if(key_pulse == 5'h10) begin // �����
        ba_hit_force <= ba_hit_force_t;
        ba_hit_force_t <= 0;
   end
end

always @(posedge clk or posedge rst) begin // ġ�� ���� ������Ʈ
    if(rst) begin
        ba_hit_angle <= 0;
    end
    else if (refr_tick) begin
        if (key == 5'h11) begin // 1��Ű ������ ������ ���� ����
            if (cnt3 > 3) begin
                if (ba_hit_angle_t < 360) begin
                    ba_hit_angle_t <= ba_hit_angle_t + 5;
                    cnt3 <= 0;
                end
                else if (ba_hit_angle_t == 360) begin // ���� ������ 360���̸� 0���� ��ȯ
                    ba_hit_angle_t <= 0;
                end
            end
            else begin
                cnt3 <= cnt3 + 1;
            end
        end
        if (key == 5'h17) begin // 7��Ű ������ ������ ���� ����
            if (cnt3 > 3) begin
                if (ba_hit_angle_t > 0) begin
                    ba_hit_angle_t <= ba_hit_angle_t - 5;
                    cnt3 <= 0;
                end
                else if (ba_hit_angle_t == 0) begin // ���� ������ 0���̸� 360���� ��ȯ
                    ba_hit_angle_t <= 360;
                end
            end
            else begin
                cnt3 <= cnt3 + 1;
            end
        end
    end 
    else if(key_pulse == 5'h10) begin // �����
        ba_hit_angle <= ba_hit_angle_t;
        ba_hit_angle_t <= 0;
    end
end

deg_set deg_set_inst (ba_hit_force, ba_hit_angle, vax, vay, dax, day); // ġ�� ���� ������ �޾Ƽ� ���ӵ� ���
deg_set deg_set_inst (bb_hit_force, bb_hit_angle, vbx, vby, dbx, dby); // �浹 �� ��B�� �ӵ� ������Ʈ

/*---------------------------------------------------------*/
// ��A�� ��ġ
//
// <����>
//  ����� �ӷ��� ����� ����. 
//  ����� �ӷ��� ���ؼ� ���� �ӵ��� ��A�� �߽���ǥ ������Ʈ
/*---------------------------------------------------------*/
always @(posedge clk or posedge rst) begin // ��A�� ����
    if(rst | key_pulse == 5'h10) begin 
        dax1 <= 0;
        day1 <= 0;
        collision <= 0;
    end
    else begin
        if(ba_top) begin // ���̺� ���� �浹
            day1 <= 1;
            collision <= 1;
        end
        else if (ba_bottom) begin  // ���̺� �Ʒ��� �浹
            day1 <= -1;
            collision <= 1;
        end
        else if (ba_left) begin // ���̺� ���� �浹
            dax1 <= 1;
            collision <= 1;
        end
        else if (ba_right) begin // ���̺� ������ �浹
            dax1 <= -1;
            collision <= 1;
        end
        else if (ba_bb) begin // ��B�� �浹
            if (cbx-cax >= 0)     dax1 <= -1;
            else if (cbx-cax < 0) dax1 <=  1;
            if (cby-cay >= 0)     day1 <= -1;
            else if (cby-cay < 0) day1 <=  1;
            collision <= 1;
        end
        else if(collision == 0) begin // deg_set���� ����ϴ� ������ �־���
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
always @(posedge clk or posedge rst) begin // ��B�� ����
    if(rst) begin
        dbx <= 1;
        dby <= -1;
    end
    else begin
        if(bb_top) begin
            dby <= 1;
        end
        else if (bb_bottom) begin
            dby <= -1;
        end
        else if (bb_left) begin
            dbx <= 1;
        end
        else if (bb_right) begin 
            dbx <= -1;
        end
        else if (ba_bb) begin
            if (cbx-cax >= 0)     dbx <=  1;
            else if (cbx-cax < 0) dbx <= -1;
            if (cby-cay >= 0)     dby <=  1;
            else if (cby-cay < 0) dby <= -1;
        end
    end
end

reg [2:0] flag;
reg [4:0] cnt4;
reg [4:0] ratio;

always @ (posedge clk or posedge rst) begin // ��B�� �ӷ�
    if(rst) begin
        vbx <= 0;
        vby <= 0;
    end
    else begin
        vbx1 <= vbx;
        vby1 <= vby;
    end
end

always @(posedge clk or posedge rst) begin // ��B ���� �ӵ�
    if(rst) begin
        vbx_reg <= 0;
        vby_reg <= 0;
    end
    else begin
        vbx_reg <= dbx*vbx;
        vby_reg <= dby*vby;
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
// HOLE A, B, C, D
/*---------------------------------------------------------*/
reg [9:0] hole_cax, hole_cay;
reg [9:0] hole_cbx, hole_cby;
reg [9:0] hole_ccx, hole_ccy;
reg [9:0] hole_cdx, hole_cdy;

reg ha_ba, ha_bb;
reg hb_ba, hb_bb;
reg hc_ba, hc_bb;
reg hd_ba, hd_bb;

always @(posedge clk or posedge rst) begin
    ha_ba = (`BALL_D*`BALL_D >= (hole_cax-cax)*(hole_cax-cax) + (hole_cay-cay)*(hole_cay-cay)) ? 1 : 0; // holeA-ballaA �浹 ����
    ha_bb = (`BALL_D*`BALL_D >= (hole_cax-cbx)*(hole_cax-cbx) + (hole_cay-cby)*(hole_cay-cby)) ? 1 : 0; // holeA-ballaB �浹 ����
    
    hb_ba = (`BALL_D*`BALL_D >= (hole_cbx-cax)*(hole_cax-cax) + (hole_cby-cay)*(hole_cay-cay)) ? 1 : 0; // holeA-ballaA �浹 ����
    hb_bb = (`BALL_D*`BALL_D >= (hole_cbx-cbx)*(hole_cax-cbx) + (hole_cby-cby)*(hole_cay-cby)) ? 1 : 0; // holeA-ballaB �浹 ����

    hc_ba = (`BALL_D*`BALL_D >= (hole_ccx-cax)*(hole_cax-cax) + (hole_ccy-cay)*(hole_cay-cay)) ? 1 : 0; // holeA-ballaA �浹 ����
    hc_bb = (`BALL_D*`BALL_D >= (hole_ccx-cbx)*(hole_cax-cbx) + (hole_ccy-cby)*(hole_cay-cby)) ? 1 : 0; // holeA-ballaB �浹 ����
    
    hd_ba = (`BALL_D*`BALL_D >= (hole_cdx-cax)*(hole_cax-cax) + (hole_cdy-cay)*(hole_cay-cay)) ? 1 : 0; // holeA-ballaA �浹 ����
    hd_bb = (`BALL_D*`BALL_D >= (hole_cdx-cbx)*(hole_cax-cbx) + (hole_cdy-cby)*(hole_cay-cby)) ? 1 : 0; // holeA-ballaB �浹 ����

    if(ha_ba || ha_bb || hb_ba || hb_bb || hc_ba || hc_bb || hd_ba || hd_bb) ba_bb = 1; //Just test
end

/*---------------------------------------------------------*/
// ��A, B �׸���
/*---------------------------------------------------------*/
assign ball_rgb[0] = (`BALL_R*`BALL_R >= (x-cax)*(x-cax) + (y-cay)*(y-cay)) ? 1 : 0;
assign ball_rgb[1] = (`BALL_R*`BALL_R >= (x-cbx)*(x-cbx) + (y-cby)*(y-cby)) ? 1 : 0;
assign ball_rgb[2] = ba_bb; // ��A-��B �浹�� Ȯ���ϱ� ���� ��ȣ (�ӽ�)

endmodule 