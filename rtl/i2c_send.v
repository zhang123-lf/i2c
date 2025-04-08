module i2c_send(
    input       wire                    rst_n           ,
    input       wire                    clk             ,// i2c clk 2x  
    input       wire                    pre_ready       ,// must be beased on the clk
    input       wire        [7:0]       pre_data        ,
    output      reg                     byte_done       ,
    output      wire                    out_flag        ,// only for simulation
    output      wire                    i2c_scl         ,// five mode:100kHz,400kHz,1MHz,3.4MHz,5MHz
    inout       wire                    i2c_sda          // set high in ACK
);
    wire    i2c_sda_i       ;
    reg     i2c_sda_o       ;
    reg     clk_2           ;
    reg     start_flag      ;
    reg     ack_flag        ;
    reg [4:0]   status      ;
    reg [3:0]   cnt         ;
    reg [7:0]   data_r      ;
    wire [3:0] data_i       ;
    localparam      IDLE    =   5'b0    ,
                    START   =   5'b10   ,
                    SEND    =   5'b100  ,
                    ANSWER  =   5'b1000 ,
                    STOP    =   5'b10000;

    assign i2c_sda   = i2c_sda_o ;
    assign i2c_sda_i = i2c_sda   ;
    assign i2c_scl = start_flag ? clk_2 & clk : 1'b1 ;// duty cycle 75%
    assign data_i = cnt == 4'd0 ? 4'd0 :cnt -4'd1;    
    assign out_flag = status == ANSWER ? 1'b1:1'b0;

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            data_r <= 8'd0   ;
        end else begin
            if(pre_ready)
                data_r  <= pre_data ;
            else
                data_r  <= data_r   ;
        end
    end

    // hit a beat to keep the timing stable
//    always@(posedge clk or negedge rst_n)begin
//        if(!rst_n)begin
//            i2c_sda_o <=  1'b1    ;
//            // i2c_scl   <=  1'b1    ;
//        end else begin
//            i2c_sda_o <=  i2c_sda_o_r   ;
//          // i2c_scl   <=  clk_2     ;
//        end
//    end
    
    //count 2
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            clk_2   <=  1'b1    ;
        end else begin
            if(start_flag)
                clk_2   <=  ~clk_2  ;
            else
                clk_2   <=  1'b1    ;
        end
    end

    // state machine state transfer
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            status  <=  IDLE    ;
        end else begin
            if(pre_ready && status == IDLE)begin
                status  <=  START   ;
            end else if(status == START)begin
                status  <=  SEND    ;
            end else if(status == SEND && cnt == 4'd8 && clk_2 == 1'b0)begin
                status  <=  ANSWER  ;
            end else if(status == ANSWER && ack_flag == 1'b0)begin
                status  <=  SEND     ;
            end else if(status == ANSWER && ack_flag == 1'b1)begin
                status  <=  STOP    ;
            end else if(status== STOP && start_flag == 1'b0)begin
                status  <=  IDLE    ;
            end else
                status  <=  status  ;
        end
    end

    // data cnt 7
    always@(posedge clk_2 or negedge rst_n)begin
        if(!rst_n)begin
            cnt     <=  4'd0    ;
        end else begin
            if(status == SEND)
                cnt <= cnt + 4'd1 ;
            else 
                cnt <=  4'd0    ;
        end
    end

    // combinational logic
    always@(*)begin
        if(!rst_n)begin
            start_flag  =   1'b0    ;
            i2c_sda_o   =   1'b1    ;
            byte_done   =   1'b1    ;
            ack_flag    =   1'b0    ;
        end else begin
            case(status)
                IDLE:begin
                    start_flag  =   1'b0    ;
                    i2c_sda_o   =   1'b1    ;
                    byte_done   =   1'b0    ;
                    ack_flag    =   1'b0    ;
                end
                START:begin
                    start_flag  =   1'b1    ;
                    i2c_sda_o   =   1'b0    ;
                    byte_done   =   1'b0    ;
                    ack_flag    =   1'b0    ;
                end
                SEND:begin
                    start_flag  =   1'b1    ;
                    i2c_sda_o   =   pre_data[data_i];
                    byte_done   =   1'b0    ;
                    ack_flag    =   1'b0    ;
                end
                ANSWER:begin
                    start_flag  =   1'b1    ;
                    i2c_sda_o   =   1'bz    ;
                    byte_done   =   1'b1    ;
                    if(i2c_scl && i2c_sda_i)
                        ack_flag    =   1'b1;
                    else if(~i2c_sda_i && i2c_scl)
                        ack_flag    =   1'b0;
                    else
                        ack_flag    =   ack_flag;
                end
                STOP:begin
                    if(~i2c_scl)begin
                        start_flag  =   start_flag    ;
                        i2c_sda_o   =   1'b0    ;
                    end else begin
                        if(clk)
                            i2c_sda_o = i2c_sda_o;
                        else
                            i2c_sda_o = 1'b1;
                        start_flag  =   1'b0  ;
                    end

                    ack_flag    =   ack_flag    ;
                    byte_done   =   1'b0    ;
                end
            endcase
        end
    end
    
    

endmodule
