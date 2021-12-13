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

parameter MAX_HIT_FORCE = 12;
parameter MAT_HIT_ANGLE = 360;

// 60Hz clock
wire refr_tick; 
assign refr_tick = (y==`MAX_Y-1 && x==`MAX_X-1)? 1 : 0; 

// ��A�� ����
wire signed [1:0] dax, day;
reg signed [1:0] dax1, day1; // ���̺� �浹�� ���� ������Ʈ
wire signed [4:0] vax, vay;
reg signed [4:0] vax1, vay1;
reg signed [9:0] vax_reg, vay_reg;
reg [9:0] cax, cay; // ��A �߽���ǥ
wire ba_top, ba_bottom, ba_left, ba_right; // ��A-���̺� �浹 �÷���

// ��B�� ����
reg signed [1:0] dbx, dby;
reg signed [4:0] vbx, vby;
reg signed [9:0] vbx_reg, vby_reg;
reg [9:0] cbx, cby; // ��B �߽���ǥ
wire bb_top, bb_bottom, bb_left, bb_right; // ��B-���̺� �浹 �÷���

// �浹 ����

wire ba_bb;
reg state;

reg [9:0] dx, dy;

reg [9:0] vax_p, vay_p;
reg [9:0] vbx_p, vby_p;

reg [9:0] vax_buf, vay_buf;
reg [9:0] vbx_buf, vby_buf;

reg [9:0] vax_new, vay_new;
reg [9:0] vbx_new, vby_new;


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

// ��A-��B �浹 �� �ӷ�

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
    state = 1;
    end
    else if (ba_bb == 0 && state == 1) begin
        state = 0;
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
reg [5:0] hit_force_t, hit_force;
reg [8:0] hit_angle_t, hit_angle;
reg collision;

always @(posedge clk or posedge rst) begin // ġ�� �� ������Ʈ
   if(rst) begin
       hit_force <= 0;
   end
   else if(refr_tick) begin
        if(key == 5'h14) begin // 4��Ű�� ������ ������ ġ�� ���� Ŀ��
            if(hit_force_t < MAX_HIT_FORCE && cnt1 > 5) begin
                hit_force_t <= hit_force_t + 1;
                cnt1 <= 0;
            end
            else begin
                cnt1 <= cnt1 + 1;
            end
        end
        if (cnt2 == 20 && hit_force > 0) begin // ġ�� ���� 0 �̻��̸� �ֱ������� �پ����
            hit_force <= hit_force - 1;
            cnt2 <= 0;
        end
        else begin
            cnt2 <= cnt2 + 1;
        end
   end
   else if(key_pulse == 5'h10) begin // �����
        hit_force <= hit_force_t;
        hit_force_t <= 0;
   end
end

always @(posedge clk or posedge rst) begin // ġ�� ���� ������Ʈ
    if(rst) begin
        hit_angle <= 0;
    end
    else if (refr_tick) begin
        if (key == 5'h11) begin // 1��Ű ������ ������ ���� ����
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
        if (key == 5'h17) begin // 7��Ű ������ ������ ���� ����
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
        hit_angle <= hit_angle_t;
        hit_angle_t <= 0;
    end
end

deg_set deg_set_inst (hit_force, hit_angle, vax, vay, dax, day); // ġ�� ���� ������ �޾Ƽ� ���ӵ� ���

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
    else if (state == 1) begin // �浹 �� �ӷ� ������Ʈ
        vbx <= vbx_new;
        vby <= vby_new;

        if (vbx > vby) begin
           ratio <= vbx / vby;
           flag <= 0;
        end
        else if (vbx < vby) begin
            ratio <= vby / vbx;
            flag <= 1;
        end
        else if (vbx == vby) begin
            ratio <= 1;
            flag <= 2;
        end     
    end
    else if (refr_tick) begin // �ð��� ���� �ӵ� ����
        if ((cnt4 == 20) && (vbx > 0 || vby > 0)) begin
            if (flag == 0) begin
                vbx <= vbx - ratio;
                vby <= vby - 1;
                cnt4 <= 0;
            end
            else if (flag == 1) begin
                vbx <= vbx - 1;
                vby <= vby - ratio;
                cnt4 <= 0;
            end
            else if (flag == 2) begin
                vbx <= vbx - 1;
                vby <= vby - 1;
                cnt4 <= 0;
            end
        end
        else begin
            cnt4 <= cnt4 + 1;
        end
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
// ��A, B �׸���
/*---------------------------------------------------------*/
assign ball_rgb[0] = (`BALL_R*`BALL_R >= (x-cax)*(x-cax) + (y-cay)*(y-cay)) ? 1 : 0;
assign ball_rgb[1] = (`BALL_R*`BALL_R >= (x-cbx)*(x-cbx) + (y-cby)*(y-cby)) ? 1 : 0;
assign ball_rgb[2] = ba_bb; // ��A-��B �浹�� Ȯ���ϱ� ���� ��ȣ (�ӽ�)

endmodule 