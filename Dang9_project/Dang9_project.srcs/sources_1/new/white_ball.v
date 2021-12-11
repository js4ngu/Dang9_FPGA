module white_ball(
    input clk, 
    input rst, 

    input [9:0] x, 
    input [9:0] y, 
    
    input [4:0] key, 
    input [4:0] key_pulse, 

    output [9:0] center_x,
    output [9:0] center_y,
    
    output white_ball_on
    );


parameter MAX_HIT_FORCE = 20;

// 60Hz clock
wire refr_tick; 
assign refr_tick = (y==`MAX_Y-1 && x==`MAX_X-1)? 1 : 0; 

// �Ͼ�� ����
reg signed [1:0] dir_x;
reg signed [1:0] dir_y;

reg signed [4:0] vx;
reg signed [4:0] vy;

reg signed [9:0] vx_reg;
reg signed [9:0] vy_reg;

reg [9:0] center_x;
reg [9:0] center_y;

reg [5:0] hit_force;

// �Ͼ��-���̺� �浹 �÷���
wire reach_top, reach_bottom, reach_left, reach_right;

assign reach_top = (`TABLE_IN_T >= (center_y - `BALL_R)) ? 1 : 0;
assign reach_bottom = (`TABLE_IN_B <= (center_y + `BALL_R)) ? 1 : 0;
assign reach_left = (`TABLE_IN_L >= (center_x - `BALL_R)) ? 1 : 0;
assign reach_right = (`TABLE_IN_R <= (center_x + `BALL_R)) ? 1 : 0;

// ���̺� �ε����� �� ���� ������Ʈ
always @(posedge clk or posedge rst) begin
    if(rst) begin
        dir_x <= 1;
        dir_y <= -1;
    end
    else begin
        if(reach_top) begin
            dir_y <= 1;
        end
        else if (reach_bottom) begin
            dir_y <= -1;
        end
        else if (reach_left) begin
            dir_x <= 1;
        end
        else if (reach_right) begin 
            dir_x <= -1;
        end
    end
end

// ġ�� �� ������Ʈ
reg [6:0] cnt1;

always @(posedge clk or posedge rst) begin
   if(rst) begin
       hit_force <= 0;
   end
   else if(refr_tick) begin
        if(key == 5'h14) // 4��Ű�� ������ ������ ġ�� ���� Ŀ��
            if(hit_force < MAX_HIT_FORCE && cnt1 > 5) begin
                hit_force <= hit_force + 1;
                cnt1 <= 0;
            end
            else
                cnt1 <= cnt1 + 1;
   end
   else if(key_pulse == 5'h10) // 0��Ű�� ������ hit_force �ʱ�ȭ
        hit_force <= 0;
end

// �ð��� ���� �ӷ� ����
reg [6:0] cnt2;

always @(posedge clk or posedge rst) begin
    if(rst | key_pulse == 5'h10) begin // 0��Ű�� ������ ġ�� ���� ���� ��������. �������� Ư���� 0���� �ʱ�ȭ�Ǳ� �� ���� vx�� ��.
        vx <= hit_force;
        vy <= hit_force;
    end
    else if(refr_tick) begin
        if(cnt2 == 20) begin // 0.3�ʸ��� �ӷ� ����
            if(vx > 0) vx <= vx - 1;
            if(vy > 0) vy <= vy - 1;
            cnt2 <= 0;
        end
        else begin
            cnt2 <= cnt2 + 1;
        end
    end
end

// ���� �ӵ�
always @(posedge clk or posedge rst) begin
    if(rst) begin
        vx_reg <= 0;
        vy_reg <= 0;
    end
    else begin
        vx_reg <= dir_x*vx;
        vy_reg <= dir_y*vy;
    end
end

// �Ͼ�� �߽� ��ǥ ������Ʈ
always @(posedge clk or posedge rst) begin
    if(rst) begin
        center_x <= `MAX_X/2;
        center_y <= `MAX_Y/2;
    end
    else if(refr_tick) begin
        center_x <= center_x + vx_reg;
        center_y <= center_y + vy_reg;
    end
end

// �Ͼ�� �׸���
assign white_ball_on = (`BALL_R*`BALL_R >= (x-center_x)*(x-center_x) + (y-center_y)*(y-center_y)) ? 1 : 0;

endmodule
