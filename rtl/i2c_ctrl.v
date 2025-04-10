module i2c_ctrl(
    input   wire            rst_n           ,
    input   wire            clk             ,
    input   wire            slave_ready     ,
    input   wire            wr_ctrl         ,// W:1/R:0
    input   wire    [7:0]   w_data          ,
    input   wire    [6:0]   i2c_slave_addr  ,
    input   wire    [7:0]   data_bytes      ,
    output  reg     [7:0]   r_data          ,
    output  wire            out_flag        ,// only for simulation
  //  output  reg             r_valid         ,
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
    reg [6:0]   state       ;
    reg [3:0]   cnt         ;
    reg [7:0]   w_data_reg  ;
    reg [7:0]   data_bytes_reg;
    reg [7:0]   cnt_bytes   ;
    wire [3:0]  data_num    ;
    reg  [7:0]  ctrl_cmd    ;

    localparam      IDLE    =   7'b0        ,
                    START   =   7'b1        ,
                    ADDRESS =   7'b10       ,
                    WDATA   =   7'b100      ,
                    RDATA   =   7'b1000     ,
                    SANSWER =   7'b10000    ,// send ack
                    WANSWER =   7'b100000   ,// wait ack
                    STOP    =   7'b1000000  ;
    assign  out_flag= state == SANSWER || state == WANSWER ?1'b1:1'b0;
    assign  i2c_sda =   i2c_sda_o   ;
    assign  i2c_sda_i   =   i2c_sda ;
    assign  i2c_scl     =   working_flag ? clk_2 & clk : 1'b1 ;
    assign  data_num    =   cnt == 4'd0 ? 4'd0 : cnt - 4'd1;

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            w_data_reg <= 8'd0    ;
            data_bytes_reg <= 8'd0;
            ctrl_cmd <= 8'd0      ;
        end else if(slave_ready)begin
            data_bytes_reg <= data_bytes;
            w_data_reg <= w_data  ;
            ctrl_cmd <= {wr_ctrl, i2c_slave_addr};
        end else begin
            data_bytes_reg <= data_bytes_reg;
            w_data_reg <= w_data_reg    ;
            ctrl_cmd <= ctrl_cmd    ;
        end
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
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            state <= IDLE   ;
        end else begin
            if(slave_ready && state == IDLE)begin
                state <= START  ;
            end else if(state == START)begin
                state <= ADDRESS;
            end else if(state == ADDRESS && cnt == 4'd8 && clk_2 == 1'b0)begin
                state <= WANSWER ;
            end else if(state == WANSWER && ack_flag == 1'b0 && ctrl_cmd[7] == 1'b1)begin
                state <= WDATA   ;
            end else if((state == WANSWER || state == SANSWER)&& ack_flag == 1'b0 && ctrl_cmd[7] == 1'b0)begin
                state <= RDATA   ;
            end else if(state == RDATA && cnt == 4'd8 && clk_2 == 1'b0)begin
                state <= SANSWER ;
            end else if(state == WDATA && cnt == 4'd8 && clk_2 == 1'b0)begin
                state <= WANSWER ;
            end else if((state == SANSWER ||state == WANSWER)&& ack_flag == 1'b1)begin
                state <= STOP   ;
            end else begin
                state <= state  ;
            end
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt_bytes <= 8'd0   ;
        end else if(state == WANSWER || state == SANSWER)begin
            cnt_bytes <= cnt_bytes + 8'd1   ;
        end else if(state == STOP || state == IDLE)begin
            cnt_bytes <= 8'd0   ;
        end else begin
            cnt_bytes <= cnt_bytes  ;
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            r_data <= 8'd0;
        end else if(state == RDATA && i2c_scl == 1'b1)begin
            r_data[data_num] <= i2c_sda_i   ;
        end else begin
            r_data <= r_data ;
        end
    end

    always@(posedge clk_2 or negedge rst_n)begin
        if(!rst_n)begin
            cnt <= 4'd0 ;
        end else begin
            if(state == ADDRESS || state == WDATA || state == RDATA)
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
                end
                ADDRESS:begin
                    working_flag = 1'b1 ;
                    i2c_sda_o    = ctrl_cmd >> data_num;
                    byte_done    = 1'b0 ;
                    ack_flag     = 1'b0 ;
                    i2c_busy     = 1'b1 ;
                end
                WANSWER:begin
                    working_flag = 1'b1 ;
                    i2c_sda_o    = 1'bz ;
                    // byte_done    = 1'b1 ;
                    // i2c_busy     = 1'b1 ;
                    if(i2c_sda_i && i2c_scl && cnt_bytes >= data_bytes_reg - 8'd1)begin
                        ack_flag = 1'b1 ;
                        byte_done= 1'b0 ; 
                        i2c_busy = 1'b0 ;
                    end else if(~i2c_sda_i && i2c_scl && cnt_bytes >= data_bytes_reg - 8'd1)begin
                        ack_flag = 1'b1 ;
                        byte_done= 1'b1 ;
                        i2c_busy = 1'b0 ;
                    end else if(~i2c_sda_i && i2c_scl && cnt < data_bytes_reg - 8'd1)begin
                        byte_done= 1'b1 ;
                        i2c_busy = 1'b1 ;
                        ack_flag = 1'b0 ;
                    end else begin
                        byte_done= byte_done ;
                        i2c_busy = i2c_busy;
                        ack_flag = ack_flag;
                    end
                end
                WDATA:begin
                    working_flag = 1'b1 ;
                    i2c_sda_o    = w_data_reg >> data_num;
                    byte_done    = 1'b0 ;
                    ack_flag     = 1'b0 ;
                    i2c_busy     = 1'b1 ;
                end
                RDATA:begin
                    working_flag = 1'b1 ;
                    i2c_sda_o    = 1'bz ;
                    byte_done    = 1'b0 ;
                    ack_flag     = 1'b0 ;
                    i2c_busy     = 1'b1 ;
                end
                SANSWER:begin
                    working_flag = 1'b1 ;
                    byte_done    = 1'b1 ;
                    if(cnt_bytes >= data_bytes_reg - 8'd1)begin
                        i2c_sda_o = 1'b1    ;
                        ack_flag  = 1'b1    ;
                    end else begin
                        i2c_sda_o = 1'b0    ;
                        ack_flag  = 1'b0    ;
                    end
                end
                STOP:begin
                    if(~i2c_scl)begin
                        working_flag = working_flag ;
                        i2c_sda_o    = 1'b0 ;
                    end else begin
                        if(clk)
                            i2c_sda_o= i2c_sda_o    ;
                        else
                            i2c_sda_o= 1'b1     ;
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
