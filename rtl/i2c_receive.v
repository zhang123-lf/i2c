module i2c_receive(
    input   wire           rst_n           ,
    input   wire           clk             ,
    input   wire           i2c_ready       ,
    input   wire           i2c_data_bytes  ,
    output  reg            i2c_scl         ,
    inout   wire           i2c_sda         ,
    output  reg     [7:0]  i2c_data        ,
    output  wire           i2c_data_valid  
);
    
    reg         start_flag          ;
    wire        i2c_sda_i           ;
    reg         i2c_sda_o           ;
    reg         clk_2               ;
    reg   [2:0] state               ;
    reg   [3:0] cnt                 ;
    reg   [2:0] data_i              ;
    reg   [3:0] cnt_bytes           ;
    reg   [3:0] data_bytes          ;
    
    assign  i2c_sda_i   =   i2c_sda ;
    assign  i2c_sda     =   i2c_sda_o   ;
    
    assign  i2c_scl     =   start_flag ? clk_2 & clk : 1'b1 ;
    assign  data_i      =   cnt == 4'd0 ? cnt : cnt -4'd1   ;

    localparam      IDLE    =   4'd0    ,
                    START   =   4'd1    ,
                    RECEIVE =   4'd2    ,
                    ANSWER  =   4'd4    ,
                    STOP    =   4'd8    ;

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            data_bytes <= 4'd0  ;
        end else if(i2c_ready)begin
            data_bytes <= i2c_data_bytes;
        end else
            data_bytes <= data_bytes    ;
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
           clk_2    <= 1'b1     ;
       end else begin
           if(start_flag)
               clk_2<=~clk_2    ;
           else
               clk_2<=1'b1      ;
       end
    end

    always@(posedge clk_2 or negedge rst_n)begin
        if(!rst_n)begin
            cnt <= 4'd0 ;
        end else begin
            if(state == RECEIVE)begin
                cnt <= cnt + 4'd1   ;
            end else begin
                cnt <= 4'd0         ;
            end 
        end
    end

    alwasy@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            state   <= IDLE ;
        end else begin
            if(state == IDLE && i2c_ready == 1'b1)begin
                state <= START  ;
            end else if(state == START)begin
                state <= RECEIVE    ;
            end else if(state == RECEIVE && cnt == 4'd8 && clk_2 == 1'b0)begin
                state <= ANSWER     ;
            end else if(state == ANSWER && cnt_bytes <  data_bytes - 4'd1)begin
                state <= RECEIVE    ;
            end else if(state == ANSWER && cnt_bytes == data_bytes - 4'd1)begin
                state <= STOP       ;
            end else
                state <= state  ;
        end
    end

    alwasy@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            i2c_data <= 8'd0    ;
        end else if(state == RECEIVE && i2c_scl == 1'b1)begin
            i2c_data[data_i] <= i2c_sda_i   ;
        end else begin
            i2c_data <= i2c_data    ;
        end
    end


    alwasy@(*)begin
        case(state)
            IDLE:begin
                start_flag  =   1'b0    ;
                i2c_sda_o   =   1'b1    ;
                i2c_data_valid = 1'b0   ;
            end
            START:begin
                start_flag  =   1'b1    ;
                i2c_sda_o   =   1'b0    ;
                i2c_data_valid = 1'b0   ;
            end
            RECEIVE:begin
                start_flag  =   1'b1    ;
                i2c_sda_o   =   1'bz    ;
                i2c_data_valid = 1'b0   ;
            end
            ANSWER:begin
                start_flag  =   1'b1    ;
                i2c_data_valid = 1'b1   ;
                if(cnt_bytes == data_bytes - 4'd1)
                    i2c_sda_o = 1'b1    ;
                else
                    i2c_sda_o = 1'b0    ;
                end
            STOP:begin
                if(~i2c_scl)begin
                    i2c_sda_o = 1'b0    ;
                    start_flag = start_flag;
                end else begin
                    if(clk)
                        i2c_sda_o = i2c_sda_o;
                    else
                        i2c_sda_o = 1'b1    ;
                    start_flag  =   1'b0    ;
                end
                 i2c_data_valid = 1'b0   ;               

        endcase







           
endmodule
