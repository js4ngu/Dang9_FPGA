module graph_mod (clk, rst, x, y, key, key_pulse, rgb);

input clk, rst;
input [9:0] x, y;
input [4:0] key, key_pulse; 
output [2:0] rgb; 

// ȭ�� ũ�� ����
parameter MAX_X = 640; 
parameter MAX_Y = 480;  

// table�� ��ǥ ���� 
parameter TABLE_OUT_L = 20;
parameter TABLE_OUT_R = 620;
parameter TABLE_OUT_T = 20;
parameter TABLE_OUT_B = 460;

parameter TABLE_IN_L = 40;
parameter TABLE_IN_R = 600;
parameter TABLE_IN_T = 40;
parameter TABLE_IN_B = 440;

// ball�� �ӵ�, ũ�� ����
parameter BALL_SIZE = 8;
parameter BALL_V = 4;

wire refr_tick; 
assign refr_tick = (y==MAX_Y-1 && x==MAX_X-1)? 1 : 0; // �� �����Ӹ��� �� clk ���ȸ� 1�� ��. 

// table
wire table_out_on, table_in_on;
assign table_out_on = (x >= TABLE_OUT_L && x <= TABLE_OUT_R - 1 && y >= TABLE_OUT_T && y <= TABLE_OUT_B - 1);
assign table_in_on = (x >= TABLE_IN_L && x <= TABLE_IN_R - 1 && y >= TABLE_IN_T && y <= TABLE_IN_B - 1);

// ball
wire ball_on;
wire reach_top, reach_bottom, reach_left, reach_right;
reg [9:0] ball_x_reg, ball_y_reg;
reg [9:0]  ball_vx_reg, ball_vy_reg; 
wire [9:0] ball_x_l, ball_x_r, ball_y_t, ball_y_b;

assign ball_x_l = ball_x_reg; //ball�� left
assign ball_x_r = ball_x_reg + BALL_SIZE - 1; //ball�� right
assign ball_y_t = ball_y_reg; //ball�� top
assign ball_y_b = ball_y_reg + BALL_SIZE - 1; //ball�� bottom

assign ball_on = (x>=ball_x_l && x<=ball_x_r && y>=ball_y_t && y<=ball_y_b)? 1 : 0; //ball�� �ִ� ����

// �� ��ǥ ������Ʈ
always @ (posedge clk or posedge rst) begin
    if(rst) begin
        ball_x_reg <= MAX_X/2; // game�� ���߸� �߰����� ����
        ball_y_reg <= MAX_Y/2; // game�� ���߸� �߰����� ����
    end else if (refr_tick) begin
        ball_x_reg <= ball_x_reg + ball_vx_reg; //�� �����Ӹ��� ball_vx_reg��ŭ ������
        ball_y_reg <= ball_y_reg + ball_vy_reg; //�� �����Ӹ��� ball_vy_reg��ŭ ������
    end
end

// �浹 �ν�
assign reach_top = (TABLE_IN_T >= ball_y_t) ? 1 : 0;
assign reach_bottom = (TABLE_IN_B <= ball_y_b) ? 1 : 0;
assign reach_left = (TABLE_IN_L >= ball_x_l) ? 1 : 0;
assign reach_right = (TABLE_IN_R <= ball_x_r) ? 1 : 0;

// �� ���� ������Ʈ
always @ (posedge clk or posedge rst) begin
    if(rst) begin
        ball_vx_reg <= -1*BALL_V; //game�� ���߸� �������� 
        ball_vy_reg <= BALL_V; //game�� ���߸� �Ʒ���
    end else begin
        if (reach_top) ball_vy_reg <= BALL_V; //õ�忡 �ε����� �Ʒ���.
        else if (reach_bottom) ball_vy_reg <= -1*BALL_V; //�ٴڿ� �ε����� ����
        else if (reach_left) ball_vx_reg <= BALL_V; //���� �ε����� ���������� 
        else if (reach_right) ball_vx_reg <= -1*BALL_V; //�ٿ� ƨ��� ��������
    end  
end

// ���� ���
assign rgb = (table_out_on == 1 && table_in_on == 0) ? 3'b111 :
             (table_out_on == 1 && table_in_on == 1 && ball_on == 0) ? 3'b000 : 
             (table_out_on == 1 && table_in_on == 1 && ball_on == 1) ? 3'b001 : 3'b000;
endmodule