`include "defines.v"

module ball(
    input clk, 
    input rst,

    input [9:0] x, 
    input [9:0] y, 
    
    output [2:0] ball_rgb
    );

// ��������
parameter BA_START_X = `MAX_X/3;
parameter BA_START_Y = `MAX_Y/2;
parameter BB_START_X = `MAX_X/3*2;
parameter BB_START_Y = `MAX_Y/2;

// 60Hz clock
wire refr_tick; 
assign refr_tick = (y==`MAX_Y-1 && x==`MAX_X-1)? 1 : 0; 

// ��A�� ����
reg signed [1:0] dax, day;
reg signed [4:0] vax, vay;
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

reg signed [9:0] dx, dy;

reg signed [9:0] vax_p, vay_p;
reg signed [9:0] vbx_p, vby_p;

reg signed [9:0] vax_buf, vay_buf;
reg signed [9:0] vbx_buf, vby_buf;

reg signed [9:0] vax_new, vay_new;
reg signed [9:0] vbx_new, vby_new;


// ��A-���̺� �浹 ����
assign ba_top = (`TABLE_IN_T >= (cay - `BALL_R)) ? 1 : 0;
assign ba_bottom = (`TABLE_IN_B <= (cay + `BALL_R)) ? 1 : 0;
assign ba_left = (`TABLE_IN_L >= (cax - `BALL_R)) ? 1 : 0;
assign ba_right = (`TABLE_IN_R <= (cax + `BALL_R)) ? 1 : 0;

// ��B-���̺� �浹 ����
assign bb_top = (`TABLE_IN_T >= (cby - `BALL_R)) ? 1 : 0;
assign bb_bottom = (`TABLE_IN_B <= (cby + `BALL_R)) ? 1 : 0;
assign bb_left = (`TABLE_IN_L >= (cbx - `BALL_R)) ? 1 : 0;
assign bb_right = (`TABLE_IN_R <= (cbx + `BALL_R)) ? 1 : 0;

// ��A-��B �浹 ����
assign ba_bb = (`BALL_D*`BALL_D >= (cbx-cax)*(cbx-cax) + (cby-cay)*(cby-cay)) ? 1 : 0;

// ��A-��B �浹 �� �ӷ�
always @ (*) begin 
    if(ba_bb) begin
    vax_p = dbx*vbx*((cbx-cax)/24) + dby*vby*((cby-cay)/24);
    vay_p = day*vay*((cbx-cax)/24) - dax*vax*((cby-cay)/24);
    vbx_p = dax*vax*((cbx-cax)/24) + day*vay*((cby-cay)/24);
    vby_p = dby*vby*((cbx-cax)/24) - dbx*vbx*((cby-cay)/24);
    
    vax_buf = vax_p*((cbx-cax)/24) - vay_p*((cby-cay)/24);
    vay_buf = vax_p*((cby-cay)/24) + vay_p*((cbx-cax)/24);
    vbx_buf = vbx_p*((cbx-cax)/24) - vby_p*((cby-cay)/24);
    vby_buf = vbx_p*((cby-cay)/24) + vby_p*((cbx-cax)/24);

    // ���� �ӵ� ����� ��ȯ. ������ ���� ó��
    vax_new = vax_buf[9]? ~(vax_buf-1):vax_buf;
    vay_new = vay_buf[9]? ~(vay_buf-1):vay_buf;
    vbx_new = vbx_buf[9]? ~(vbx_buf-1):vbx_buf;
    vby_new = vby_buf[9]? ~(vby_buf-1):vby_buf;
    end
    else begin
        vax_new = 0;
        vay_new = 0;
        vbx_new = 0;
        vby_new = 0;
    end
end

// ��A�� ����
always @(posedge clk or posedge rst) begin
    if(rst) begin
        dax <= 1;
        day <= -1;
    end
    else begin
        if(ba_top) begin
            day <= 1;
        end
        else if (ba_bottom) begin
            day <= -1;
        end
        else if (ba_left) begin
            dax <= 1;
        end
        else if (ba_right) begin 
            dax <= -1;
        end
        else if (ba_bb) begin
            if (cbx-cax >= 0)     dax <= -1;
            else if (cbx-cax < 0) dax <=  1;
            if (cby-cay >= 0)     day <= -1;
            else if (cby-cay < 0) day <=  1;
        end
    end
end

// ��B�� ����
always @(posedge clk or posedge rst) begin
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

// ��A�� �ӷ�
always @ (posedge clk or posedge rst) begin
    if(rst) begin
        vax <= 8;
        vay <= 8;
    end
    else if (ba_bb) begin
        vax <= vax_new;
        vay <= vay_new;
    end
end

// ��B�� �ӷ�
always @ (posedge clk or posedge rst) begin
    if(rst) begin
        vbx <= 8;
        vby <= 8;
    end
    else if (ba_bb) begin
        vbx <= vbx_new;
        vby <= vby_new;
    end
end

// ��A ���� �ӵ�
always @(posedge clk or posedge rst) begin
    if(rst) begin
        vax_reg <= 0;
        vay_reg <= 0;
    end
    else begin
        vax_reg <= dax*vax;
        vay_reg <= day*vay;
    end
end

// ��B ���� �ӵ�
always @(posedge clk or posedge rst) begin
    if(rst) begin
        vbx_reg <= 0;
        vby_reg <= 0;
    end
    else begin
        vbx_reg <= dbx*vbx;
        vby_reg <= dby*vby;
    end
end

// ��A �߽� ��ǥ ������Ʈ
always @(posedge clk or posedge rst) begin
    if(rst) begin
        cax <= BA_START_X;
        cay <= BA_START_Y;
    end
    else if(refr_tick) begin
        cax <= cax + vax_reg;
        cay <= cay + vay_reg;
    end
end

// ��B �߽� ��ǥ ������Ʈ
always @(posedge clk or posedge rst) begin
    if(rst) begin
        cbx <= BB_START_X;
        cby <= BB_START_Y;
    end
    else if(refr_tick) begin
        cbx <= cbx + vbx_reg;
        cby <= cby + vby_reg;
    end
end

// �� �׸���
assign ball_rgb[0] = (`BALL_R*`BALL_R >= (x-cax)*(x-cax) + (y-cay)*(y-cay)) ? 1 : 0;
assign ball_rgb[1] = (`BALL_R*`BALL_R >= (x-cbx)*(x-cbx) + (y-cby)*(y-cby)) ? 1 : 0;
assign ball_rgb[2] = ba_bb;

endmodule