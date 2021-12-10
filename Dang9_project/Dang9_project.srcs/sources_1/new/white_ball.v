module white_ball(
    input clk, 
    input rst, 

    input [9:0] x, 
    input [9:0] y, 
    
    input [4:0] key, 
    input [4:0] key_pulse, 

    output [9:0] ball1_center_x,
    output [9:0] ball1_center_y,
    
    output white_ball_on
    );


parameter MAX_HIT_FORCE = 20;

// 60Hz clock
wire refr_tick; 
assign refr_tick = (y==`MAX_Y-1 && x==`MAX_X-1)? 1 : 0; 

// ��1 ����
reg signed [1:0] ball1_dir_x;
reg signed [1:0] ball1_dir_y;

reg [5:0] hit_force;

reg signed [4:0] ball1_vx;
reg signed [4:0] ball1_vy;

reg signed [9:0] ball1_vx_reg;
reg signed [9:0] ball1_vy_reg;

reg [9:0] ball1_center_x;
reg [9:0] ball1_center_y;

// ��1-���̺� �浹 �÷���
wire ball1_reach_top, ball1_reach_bottom, ball1_reach_left, ball1_reach_right;

assign ball1_reach_top = (`TABLE_IN_T >= (ball1_center_y - `BALL_SIZE)) ? 1 : 0;
assign ball1_reach_bottom = (`TABLE_IN_B <= (ball1_center_y + `BALL_SIZE)) ? 1 : 0;
assign ball1_reach_left = (`TABLE_IN_L >= (ball1_center_x - `BALL_SIZE)) ? 1 : 0;
assign ball1_reach_right = (`TABLE_IN_R <= (ball1_center_x + `BALL_SIZE)) ? 1 : 0;

// ���̺� �ε����� �� ���� ������Ʈ
always @(posedge clk or posedge rst) begin
    if(rst) begin
        ball1_dir_x <= 1;
        ball1_dir_y <= -1;
    end
    else begin
        if(ball1_reach_top) begin
            ball1_dir_y <= 1;
        end
        else if (ball1_reach_bottom) begin
            ball1_dir_y <= -1;
        end
        else if (ball1_reach_left) begin
            ball1_dir_x <= 1;
        end
        else if (ball1_reach_right) begin 
            ball1_dir_x <= -1;
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
    if(rst | key_pulse == 5'h10) begin // 0��Ű�� ������ ġ�� ���� ���� ��������. �������� Ư���� 0���� �ʱ�ȭ�Ǳ� �� ���� ball1_vx�� ��.
        ball1_vx <= hit_force;
        ball1_vy <= hit_force;
    end
    else if(refr_tick) begin
        if(cnt2 == 20) begin // 0.3�ʸ��� �ӷ� ����
            if(ball1_vx > 0) ball1_vx <= ball1_vx - 1;
            if(ball1_vy > 0) ball1_vy <= ball1_vy - 1;
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
        ball1_vx_reg <= 0;
        ball1_vy_reg <= 0;
    end
    else begin
        ball1_vx_reg <= ball1_dir_x*ball1_vx;
        ball1_vy_reg <= ball1_dir_y*ball1_vy;
    end
end

// ��1 �߽� ��ǥ ������Ʈ
always @(posedge clk or posedge rst) begin
    if(rst) begin
        ball1_center_x <= `MAX_X/2;
        ball1_center_y <= `MAX_Y/2;
    end
    else if(refr_tick) begin
        ball1_center_x <= ball1_center_x + ball1_vx_reg;
        ball1_center_y <= ball1_center_y + ball1_vy_reg;
    end
end

// ��1 �׸���
assign white_ball_on = (`BALL_SIZE*`BALL_SIZE >= (x-ball1_center_x)*(x-ball1_center_x) + (y-ball1_center_y)*(y-ball1_center_y)) ? 1 : 0;

endmodule
