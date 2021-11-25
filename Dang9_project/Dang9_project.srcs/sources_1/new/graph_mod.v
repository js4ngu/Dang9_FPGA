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
parameter BALL_SIZE = 40;
//parameter BALL_V = 4;

reg [9:0] BALL_1Vx = 4;
reg [9:0] BALL_1Vy = 4;
reg [9:0] BALL_2Vx = 4;
reg [9:0] BALL_2Vy = 4;
reg [9:0] BALL_3Vx = 4;
reg [9:0] BALL_3Vy = 4;

wire refr_tick; 
assign refr_tick = (y==MAX_Y-1 && x==MAX_X-1)? 1 : 0; // ?? ????????? ?? clk ????? 1?? ??. 

// table
wire table_out_on, table_in_on;
assign table_out_on = (x >= TABLE_OUT_L && x <= TABLE_OUT_R - 1 && y >= TABLE_OUT_T && y <= TABLE_OUT_B - 1);
assign table_in_on = (x >= TABLE_IN_L && x <= TABLE_IN_R - 1 && y >= TABLE_IN_T && y <= TABLE_IN_B - 1);

// ball
wire ball1_reach_top, ball1_reach_bottom, ball1_reach_left, ball1_reach_right;
wire ball2_reach_top, ball2_reach_bottom, ball2_reach_left, ball2_reach_right;
wire ball3_reach_top, ball3_reach_bottom, ball3_reach_left, ball3_reach_right;

wire Crash_ball1_to_ball2_x_l, Crash_ball1_to_ball2_x_r, Crash_ball1_to_ball2_y_t, Crash_ball1_to_ball2_y_b, Crash_ball1_to_ball2;
wire Crash_ball1_to_ball3_x_l, Crash_ball1_to_ball3_x_r, Crash_ball1_to_ball3_y_t, Crash_ball1_to_ball3_y_b, Crash_ball1_to_ball3;

wire Crash_ball2_to_ball1_x_l, Crash_ball2_to_ball1_x_r, Crash_ball2_to_ball1_y_t, Crash_ball2_to_ball1_y_b, Crash_ball2_to_ball1;
wire Crash_ball2_to_ball3_x_l, Crash_ball2_to_ball3_x_r, Crash_ball2_to_ball3_y_t, Crash_ball2_to_ball3_y_b, Crash_ball2_to_ball3;

wire Crash_ball3_to_ball1_x_l, Crash_ball3_to_ball1_x_r, Crash_ball3_to_ball1_y_t, Crash_ball3_to_ball1_y_b, Crash_ball3_to_ball1;
wire Crash_ball3_to_ball2_x_l, Crash_ball3_to_ball2_x_r, Crash_ball3_to_ball2_y_t, Crash_ball3_to_ball2_y_b, Crash_ball3_to_ball2;

wire ball1_on;
reg [9:0]  ball1_x_reg, ball1_y_reg;
reg [9:0]  ball1_vx_reg, ball1_vy_reg;
wire [9:0] ball1_x_l, ball1_x_r, ball1_y_t, ball1_y_b;

wire ball2_on;
reg [9:0]  ball2_vx_reg, ball2_vy_reg;
reg [9:0]  ball2_x_reg, ball2_y_reg; 
wire [9:0] ball2_x_l, ball2_x_r, ball2_y_t, ball2_y_b;

wire ball3_on;
reg [9:0]  ball3_vx_reg, ball3_vy_reg;
reg [9:0]  ball3_x_reg, ball3_y_reg; 
wire [9:0] ball3_x_l, ball3_x_r, ball3_y_t, ball3_y_b;

// ��1 ����
assign ball1_x_l = ball1_x_reg; //ball�� left
assign ball1_x_r = ball1_x_reg + BALL_SIZE - 1; //ball�� right
assign ball1_y_t = ball1_y_reg; //ball�� top
assign ball1_y_b = ball1_y_reg + BALL_SIZE - 1; //ball�� bottom

// ��2 ����
assign ball2_x_l = ball2_x_reg; //ball�� left
assign ball2_x_r = ball2_x_reg + BALL_SIZE - 1; //ball�� right
assign ball2_y_t = ball2_y_reg; //ball�� top
assign ball2_y_b = ball2_y_reg + BALL_SIZE - 1; //ball�� bottom

//��3 ����
assign ball3_x_l = ball3_x_reg; //ball�� left
assign ball3_x_r = ball3_x_reg + BALL_SIZE - 1; //ball�� right
assign ball3_y_t = ball3_y_reg; //ball�� top
assign ball3_y_b = ball3_y_reg + BALL_SIZE - 1; //ball�� bottom

assign ball1_on = (x>=ball1_x_l && x<=ball1_x_r && y>=ball1_y_t && y<=ball1_y_b)? 1 : 0; //ball1�� �ִ� ����
assign ball2_on = (x>=ball2_x_l && x<=ball2_x_r && y>=ball2_y_t && y<=ball2_y_b)? 1 : 0; //ball2�� �ִ� ����
assign ball3_on = (x>=ball3_x_l && x<=ball3_x_r && y>=ball3_y_t && y<=ball3_y_b)? 1 : 0; //ball2�� �ִ� ����

// ��1 �浹 �ν�
assign ball1_reach_top = (TABLE_IN_T >= ball1_y_t) ? 1 : 0;
assign ball1_reach_bottom = (TABLE_IN_B <= ball1_y_b) ? 1 : 0;
assign ball1_reach_left = (TABLE_IN_L >= ball1_x_l) ? 1 : 0;
assign ball1_reach_right = (TABLE_IN_R <= ball1_x_r) ? 1 : 0;

// ��2 �浹 �ν�
assign ball2_reach_top = (TABLE_IN_T >= ball2_y_t) ? 1 : 0;
assign ball2_reach_bottom = (TABLE_IN_B <= ball2_y_b) ? 1 : 0;
assign ball2_reach_left = (TABLE_IN_L >= ball2_x_l) ? 1 : 0;
assign ball2_reach_right = (TABLE_IN_R <= ball2_x_r) ? 1 : 0;

// ��3 �浹 �ν�
assign ball3_reach_top = (TABLE_IN_T >= ball3_y_t) ? 1 : 0;
assign ball3_reach_bottom = (TABLE_IN_B <= ball3_y_b) ? 1 : 0;
assign ball3_reach_left = (TABLE_IN_L >= ball3_x_l) ? 1 : 0;
assign ball3_reach_right = (TABLE_IN_R <= ball3_x_r) ? 1 : 0;


//�� �� �浹 ����
//ball1 ����
assign Crash_ball1_to_ball2_x_l = ((ball2_x_l <= ball1_x_l) && (ball1_x_l <= ball2_x_r)) ? 1 : 0; // 1?? ?? x????? 2???? x???? ?????? ????
assign Crash_ball1_to_ball2_x_r = ((ball2_x_l <= ball1_x_r) && (ball1_x_r <= ball2_x_r)) ? 1 : 0; // 1?? ?? x????? 2???? x???? ?????? ????
assign Crash_ball1_to_ball2_y_t = ((ball2_y_t <= ball1_y_t) && (ball1_y_t <= ball2_y_b)) ? 1 : 0; // 2?? ?? y????? 1???? y???? ?????? ????
assign Crash_ball1_to_ball2_y_b = ((ball2_y_t <= ball1_y_b) && (ball1_y_b <= ball2_y_b)) ? 1 : 0; // 2?? ?? y????? 1???? y???? ?????? ????

assign Crash_ball1_to_ball3_x_l = ((ball3_x_l <= ball1_x_l) && (ball1_x_l <= ball3_x_r)) ? 1 : 0; // 1?? ?? x????? 2???? x???? ?????? ????
assign Crash_ball1_to_ball3_x_r = ((ball3_x_l <= ball1_x_r) && (ball1_x_r <= ball3_x_r)) ? 1 : 0; // 1?? ?? x????? 2???? x???? ?????? ????
assign Crash_ball1_to_ball3_y_t = ((ball3_y_t <= ball1_y_t) && (ball1_y_t <= ball3_y_b)) ? 1 : 0; // 2?? ?? y????? 1???? y???? ?????? ????
assign Crash_ball1_to_ball3_y_b = ((ball3_y_t <= ball1_y_b) && (ball1_y_b <= ball3_y_b)) ? 1 : 0; // 2?? ?? y????? 1???? y???? ?????? ????

//ball2 ����
assign Crash_ball2_to_ball1_x_l = ((ball1_x_l <= ball2_x_l) && (ball2_x_l <= ball1_x_r)) ? 1 : 0; // 2?? ?? x????? 1???? x???? ?????? ????
assign Crash_ball2_to_ball1_x_r = ((ball1_x_l <= ball2_x_r) && (ball2_x_r <= ball1_x_r)) ? 1 : 0; // 2?? ?? x????? 1???? x???? ?????? ????
assign Crash_ball2_to_ball1_y_t = ((ball1_y_t <= ball2_y_t) && (ball2_y_t <= ball1_y_b)) ? 1 : 0; // 2?? ?? y????? 1???? y???? ?????? ????
assign Crash_ball2_to_ball1_y_b = ((ball1_y_t <= ball2_y_b) && (ball2_y_b <= ball1_y_b)) ? 1 : 0; // 2?? ?? y????? 1???? y???? ?????? ????

assign Crash_ball2_to_ball3_x_l = ((ball3_x_l <= ball2_x_l) && (ball2_x_l <= ball3_x_r)) ? 1 : 0; // 2?? ?? x????? 1???? x???? ?????? ????
assign Crash_ball2_to_ball3_x_r = ((ball3_x_l <= ball2_x_r) && (ball2_x_r <= ball3_x_r)) ? 1 : 0; // 2?? ?? x????? 1???? x???? ?????? ????
assign Crash_ball2_to_ball3_y_t = ((ball3_y_t <= ball2_y_t) && (ball2_y_t <= ball3_y_b)) ? 1 : 0; // 2?? ?? y????? 1???? y???? ?????? ????
assign Crash_ball2_to_ball3_y_b = ((ball3_y_t <= ball2_y_b) && (ball2_y_b <= ball3_y_b)) ? 1 : 0; // 2?? ?? y????? 1???? y???? ?????? ????

//ball3 ����
assign Crash_ball3_to_ball1_x_l = ((ball1_x_l <= ball3_x_l) && (ball3_x_l <= ball1_x_r)) ? 1 : 0; // 2?? ?? x????? 1???? x???? ?????? ????
assign Crash_ball3_to_ball1_x_r = ((ball1_x_l <= ball3_x_r) && (ball3_x_r <= ball1_x_r)) ? 1 : 0; // 2?? ?? x????? 1???? x???? ?????? ????
assign Crash_ball3_to_ball1_y_t = ((ball1_y_t <= ball3_y_t) && (ball3_y_t <= ball1_y_b)) ? 1 : 0; // 2?? ?? y????? 1???? y???? ?????? ????
assign Crash_ball3_to_ball1_y_b = ((ball1_y_t <= ball3_y_b) && (ball3_y_b <= ball1_y_b)) ? 1 : 0; // 2?? ?? y????? 1???? y???? ?????? ????

assign Crash_ball3_to_ball2_x_l = ((ball2_x_l <= ball3_x_l) && (ball3_x_l <= ball2_x_r)) ? 1 : 0; // 2?? ?? x????? 1???? x???? ?????? ????
assign Crash_ball3_to_ball2_x_r = ((ball2_x_l <= ball3_x_r) && (ball3_x_r <= ball2_x_r)) ? 1 : 0; // 2?? ?? x????? 1???? x???? ?????? ????
assign Crash_ball3_to_ball2_y_t = ((ball2_y_t <= ball3_y_t) && (ball3_y_t <= ball2_y_b)) ? 1 : 0; // 2?? ?? y????? 1???? y???? ?????? ????
assign Crash_ball3_to_ball2_y_b = ((ball2_y_t <= ball3_y_b) && (ball3_y_b <= ball2_y_b)) ? 1 : 0; // 2?? ?? y????? 1???? y???? ?????? ????

//�浹 FLAG
assign Crash_ball1_to_ball2 = (Crash_ball1_to_ball2_x_l && Crash_ball1_to_ball2_y_t) ||
                              (Crash_ball1_to_ball2_x_l && Crash_ball1_to_ball2_y_b) ||
                              (Crash_ball1_to_ball2_x_r && Crash_ball1_to_ball2_y_t) ||
                              (Crash_ball1_to_ball2_x_r && Crash_ball1_to_ball2_y_b);
                              
assign Crash_ball1_to_ball3 = (Crash_ball1_to_ball3_x_l && Crash_ball1_to_ball3_y_t) ||
                              (Crash_ball1_to_ball3_x_l && Crash_ball1_to_ball3_y_b) ||
                              (Crash_ball1_to_ball3_x_r && Crash_ball1_to_ball3_y_t) ||
                              (Crash_ball1_to_ball3_x_r && Crash_ball1_to_ball3_y_b);

assign Crash_ball2_to_ball1 = (Crash_ball2_to_ball1_x_l && Crash_ball2_to_ball1_y_t) || 
                              (Crash_ball2_to_ball1_x_l && Crash_ball2_to_ball1_y_b) ||
                              (Crash_ball2_to_ball1_x_r && Crash_ball2_to_ball1_y_t) || 
                              (Crash_ball2_to_ball1_x_r && Crash_ball2_to_ball1_y_b);
                              
assign Crash_ball2_to_ball3 = (Crash_ball2_to_ball3_x_l && Crash_ball2_to_ball3_y_t) || 
                              (Crash_ball2_to_ball3_x_l && Crash_ball2_to_ball3_y_b) ||
                              (Crash_ball2_to_ball3_x_r && Crash_ball2_to_ball3_y_t) || 
                              (Crash_ball2_to_ball3_x_r && Crash_ball2_to_ball3_y_b);
                              
assign Crash_ball3_to_ball1 = (Crash_ball3_to_ball1_x_l && Crash_ball3_to_ball1_y_t) || 
                              (Crash_ball3_to_ball1_x_l && Crash_ball3_to_ball1_y_b) ||
                              (Crash_ball3_to_ball1_x_r && Crash_ball3_to_ball1_y_t) || 
                              (Crash_ball3_to_ball1_x_r && Crash_ball3_to_ball1_y_b);
                              
assign Crash_ball3_to_ball2 = (Crash_ball3_to_ball2_x_l && Crash_ball3_to_ball2_y_t) || 
                              (Crash_ball3_to_ball2_x_l && Crash_ball3_to_ball2_y_b) ||
                              (Crash_ball3_to_ball2_x_r && Crash_ball3_to_ball2_y_t) || 
                              (Crash_ball3_to_ball2_x_r && Crash_ball3_to_ball2_y_b);
// ��1 ���� ������Ʈ
always @ (posedge clk or posedge rst) begin
    if(rst) begin
        ball1_vx_reg <= -1*BALL_1Vx; //game�� ���߸� �������� 
        ball1_vy_reg <= BALL_1Vy; //game�� ���߸� �Ʒ���
    end else begin
        if (ball1_reach_top) ball1_vy_reg <= BALL_1Vy; //õ�忡 �ε����� ���Ʒ���..
        else if (ball1_reach_bottom) ball1_vy_reg <= -1*BALL_1Vy; //�ٴڿ� �ε����� ����
        else if (ball1_reach_left) ball1_vx_reg <= BALL_1Vx; //���� �ε����� ����������
        else if (ball1_reach_right) ball1_vx_reg <= -1*BALL_1Vx; //�ٿ� ƨ��� ��������
        else if ( Crash_ball1_to_ball2 || Crash_ball1_to_ball3 ||
                  Crash_ball2_to_ball1 || Crash_ball3_to_ball1) begin //Crash_ball1_to_ball2 || Crash_ball2_to_ball1
            ball1_vx_reg <= -1 * ball1_vx_reg;
            ball1_vy_reg <= -1 * ball1_vy_reg;
        end
    end  
end

// ��2 ���� ������Ʈ
always @ (posedge clk or posedge rst) begin
    if(rst) begin
        ball2_vx_reg <= BALL_2Vx; ////game�� ���߸� �������� 
        ball2_vy_reg <= -1*BALL_2Vy; //game�� ���߸� �Ʒ���
    end else begin
        if (ball2_reach_top) ball2_vy_reg <= BALL_2Vy; //õ�忡 �ε����� �Ʒ���
        else if (ball2_reach_bottom) ball2_vy_reg <= -1*BALL_2Vy; //.�ٴڿ� �ε����� ����
        else if (ball2_reach_left) ball2_vx_reg <= BALL_2Vx; //���� �ε����� ����������
        else if (ball2_reach_right) ball2_vx_reg <= -1*BALL_2Vx; //�ٿ� ƨ��� ��������
        else if (Crash_ball2_to_ball1 || Crash_ball2_to_ball3 ||
                 Crash_ball1_to_ball2 || Crash_ball3_to_ball2) begin //Crash_ball1_to_ball2 || Crash_ball2_to_ball1
            //ball2_vx_reg <= -1 * ball2_vx_reg;
            //ball2_vy_reg <= -1 * ball2_vy_reg;
        end
    end  
end

// ��3 ���� ������Ʈ
always @ (posedge clk or posedge rst) begin
    if(rst) begin
        ball3_vx_reg <= BALL_3Vx; ////game�� ���߸� �������� 
        ball3_vy_reg <= BALL_3Vy; //game�� ���߸� �Ʒ���
    end else begin
        if (ball3_reach_top) ball3_vy_reg <= BALL_3Vy; //õ�忡 �ε����� �Ʒ���
        else if (ball3_reach_bottom) ball3_vy_reg <= -1*BALL_3Vy; //.�ٴڿ� �ε����� ����
        else if (ball3_reach_left) ball3_vx_reg <= BALL_3Vx; //���� �ε����� ����������
        else if (ball3_reach_right) ball3_vx_reg <= -1*BALL_3Vx; //�ٿ� ƨ��� ��������
        else if ( Crash_ball3_to_ball1 || Crash_ball3_to_ball2 ||
                  Crash_ball1_to_ball3 || Crash_ball2_to_ball3) begin //Crash_ball1_to_ball2 || Crash_ball2_to_ball1 || Crash_ball2_to_ball3
            //ball3_vx_reg <= -1 * ball3_vx_reg;
            //ball3_vy_reg <= -1 * ball3_vy_reg;
        end
    end  
end


// �� 1,2 ��ǥ������Ʈ
always @ (posedge clk or posedge rst) begin
    if(rst) begin
        ball1_x_reg <= 150; ball2_x_reg <= 300;  ball3_x_reg <= 450;// game�� ���߸� �߰����� ����
        ball1_y_reg <= MAX_Y/2; ball2_y_reg <= MAX_Y/2; ball3_y_reg <= MAX_Y/2;// e�� ���߸� �߰����� ����
    end else if (refr_tick) begin
        ball1_x_reg <= ball1_x_reg + ball1_vx_reg;  //�� �����Ӹ��� ball_vx_reg��ŭ ������
        ball1_y_reg <= ball1_y_reg + ball1_vy_reg;  //�� �����Ӹ��� ball_vy_reg��ŭ ������
        ball2_x_reg <= ball2_x_reg + ball2_vx_reg;
        ball2_y_reg <= ball2_y_reg + ball2_vy_reg;
        ball3_x_reg <= ball3_x_reg + ball3_vx_reg;
        ball3_y_reg <= ball3_y_reg + ball3_vy_reg;
    end
end

// �������
assign rgb = (table_out_on == 1 && table_in_on == 0) ? 3'b111 :
             (table_out_on == 1 && table_in_on == 1 && ball1_on == 0 && ball2_on == 0 && ball3_on == 0) ? 3'b000 : 
             (table_out_on == 1 && table_in_on == 1 && ball1_on == 1) ? 3'b001 : 
             (table_out_on == 1 && table_in_on == 1 && ball2_on == 1) ? 3'b100 :
             (table_out_on == 1 && table_in_on == 1 && ball3_on == 1) ? 3'b010 : 3'b000;
endmodule