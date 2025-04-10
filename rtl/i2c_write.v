module i2c_write(
    input   wire            rst_n           ,
    input   wire            clk             ,
    input   wire            pre_ready       ,
    input   wire    [7:0]   pre_data        ,
    input   wire    [6:0]   i2c_slave_addr  ,
    output  reg             i2c_busy        ,
    output  reg             byte_done       ,
    output  wire            i2c_scl         ,
    inout   wire            i2c_sda     
);

    wire        i2c_sda_i   ;
    reg         i2c_sda_o   ;
    reg         clk_2       ;
    reg         working_flag;
    reg         ack_flag    ;
    reg [4:0]   state       ;
    reg [3:0]   cnt         ;
    reg [7:0]   data_r      ;
    wire [3:0]  data_num    ;
    wire [7:0]   add_cmd = {1'b1,i2c_slave_addr};    

    localparam      IDLE    =   5'b0        ,
                    START   =   5'b1        ,
                    ADDRESS =   5'b10       ,
                    DATA    =   5'b100      ,
                    ANSWER  =   5'b1000     ,
                    STOP    =   5'b10000    ;

    assign  i2c_sda =   i2c_sda_o   ;
    assign  i2c_sda_i   =   i2c_sda ;
    assign  i2c_scl     =   working_flag ? clk_2 & clk : 1'b1 ;
    assign  data_num    =   cnt == 4'd0 ? 4'd0 : cnt - 4'd1;

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            data_r <= 8'd0      ;
        end else if(pre_ready)begin
            data_r <= pre_data  ;
        end else
            data_r <= data_r    ;
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            clk_2 <= 1'b1   ;
        end else begin
            if(working_flag)begin
                clk_2 <= ~clk_2 ;
            end else begin
                clk_2 <= 1'b1   ;
            end
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            state <= IDLE   ;
        end else begin
            if(pre_ready && state == IDLE)begin
                state <= START  ;
            end else if(state == START)begin
                state <= ADDRESS;
            end else if(state == ADDRESS && cnt == 4'd8 && clk_2 == 1'b0)begin
                state <= ANSWER ;
            end else if(state == ANSWER && ack_flag == 1'b0)begin
                state <= DATA   ;
            end else if(state == DATA && cnt == 4'd8 && clk_2 == 1'b0)begin
                state <= ANSWER ;
            end else if(state == ANSWER && ack_flag == 1'b1)begin
                state <= STOP   ;
            end else begin
                state <= state  ;
            end
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt <= 4'd0 ;
        end else begin
            if(state == ADDRESS || state == DATA)
                cnt <= cnt + 4'd1   ;
            else
                cnt <= 4'd0 ;
        end
    end

    always@(*)begin
        if(!rst_n)begin
            working_flag = 1'b0 ;
            i2c_sda_o    = 1'b1 ;
            byte_done    = 1'b0 ;
            ack_flag     = 1'b0 ;
            i2c_busy     = 1'b0 ;
        end else begin
            case(state)
                IDLE:begin
                    working_flag = 1'b0 ;
                    i2c_sda_o    = 1'b1 ;
                    byte_done    = 1'b0 ;
                    ack_flag     = 1'b0 ;
                    i2c_busy     = 1'b0 ;
                end
                START:begin
                    working_flag = 1'b1 ;
                    i2c_sda_o    = 1'b0 ;
                    byte_done    = 1'b0 ;
                    ack_flag     = 1'b0 ;
                    i2c_busy     = 1'b1 ;
                ADDRESS:begin
                    working_flag = 1'b1 ;
                    i2c_sda_o    = add_cmd << data_num;
                    byte_done    = 1'b0 ;
                    ack_flag     = 1'b0 ;
                    i2c_busy     = 1'b1 ;
                end
                ANSWER:begin
                    working_flag = 1'b1 ;
                    i2c_sda_o    = 1'bz ;
                    byte_done    = 1'b1 ;
                    i2c_busy     = 1'b1 ;
                    if(i2c_scl && i2c_sda_i)
                        ack_flag = 1'b1 ;
                    else if(~i2c_sda_i && i2c_scl)
                        ack_flag = 1'b0 ;
                    else 
                        ack_flag = ack_flag;
                end
                DATA:begin
                    working_flag = 1'b1 ;
                    i2c_sda_o    = data_r  << data_num;
                    byte_done    = 1'b0 ;
                    ack_flag     = 1'b0 ;
                    i2c_busy     = 1'b1 ;
                end
                STOP:begin
                    if(~i2c_scl)begin
                        working_flag = working_flag ;
                        i2c_sda_o    = 1'b0 ;
                    end else begin
                        if(clk)
                            i2c_sda_o= i2c_sda_o    ;
                        else
                            i2c_sda_o= 1'b0     ;
                        working_flag = 1'b0     ;
                    end
                    ack_flag =  ack_flag  ;
                    byte_done   =   1'b0;
                    i2c_busy    =   1'b0;
                end
            endcase
        end
    end

endmodule
