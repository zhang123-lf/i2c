module i2c_ctrl_tb();

    reg             rst_n           ;
    reg             clk             ;
    reg             slave_ready     ;
    reg             wr_ctrl         ;
    reg [7:0]       w_data          ;
    reg [6:0]       i2c_slave_addr  ;
    reg [7:0]       data_bytes      ;
    wire[7:0]       r_data          ;
    wire            i2c_busy        ;
    wire            byte_done       ;
    wire            i2c_scl         ;
    wire            i2c_sda         ;
    wire            out_flag        ;
    reg [1:0]       i2c_busy_r      ;
    wire            i2c_busy_negedge = ~i2c_busy_r[0] & i2c_busy_r[1];
    reg             start ,r_data_flag;
    reg             i2c_sda_o       ;
    reg [3:0]       r_cnt           ;

    i2c_ctrl u_i2c_ctrl(
        .rst_n         (rst_n           ),  
        .clk           (clk             ),  
        .slave_ready   (slave_ready     ),  
        .wr_ctrl       (wr_ctrl         ),  
        .w_data        (w_data          ),  
        .i2c_slave_addr(i2c_slave_addr  ),  
        .data_bytes    (data_bytes      ),  
        .out_flag      (out_flag        ),
        .r_data        (r_data          ),  
        .i2c_busy      (i2c_busy        ),  
        .byte_done     (byte_done       ),  
        .i2c_scl       (i2c_scl         ),  
        .i2c_sda       (i2c_sda         )  
    );

    assign i2c_sda = wr_ctrl?(out_flag?1'b0:1'bz):(~r_data_flag?i2c_sda_o:(out_flag?1'bz:i2c_sda_o));
    

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            r_cnt <= 4'd0;
        end else if(~wr_ctrl & i2c_busy_r[0] & i2c_scl & ~out_flag)begin
            r_cnt <= r_cnt + 4'd1;
        end else if(out_flag) 
            r_cnt <= 4'd0;
        else
            r_cnt <= r_cnt ;
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            r_data_flag <= 1'b0;
        else if(r_cnt >= 4'd8)
            r_data_flag <= 1'b1;
        else
            r_data_flag <= r_data_flag;
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            i2c_sda_o <= 1'bz;
        end else if(r_data_flag && ~i2c_scl && ~out_flag)
            i2c_sda_o <= w_data[r_cnt];
        else if(~r_data_flag && r_cnt == 4'd8)
            i2c_sda_o <= 1'b0;
        else if(out_flag)
            i2c_sda_o <= 1'bz;
        else
            i2c_sda_o <= i2c_sda_o;
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            wr_ctrl <= 1'b1;
        end else if(i2c_busy_negedge)begin
           #40  wr_ctrl <= 1'b0;
        end
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            i2c_busy_r <= 2'd0 ;
        end else begin
            i2c_busy_r <= {i2c_busy_r[0], i2c_busy};
        end
    end


    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            w_data <= 8'hf0;
        end else if(byte_done) begin
            w_data <= w_data + 8'd1;
        end else begin
            w_data <= w_data    ;
        end
    end

    initial begin
        $fsdbDumpfile("tb.fsdb");
        $fsdbDumpvars(0,i2c_ctrl_tb);
        # 5000 $finish;
    end
    
    always@(*)begin
        slave_ready = start | out_flag;
    end

    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        i2c_slave_addr = 7'b1010101;
    //    wr_ctrl = 1'b1;
        data_bytes = 8'h10;
        #150 rst_n = 1'b1;
        #30 start = 1'b1;
        #20 start = 1'b0;
        @i2c_busy_negedge
            #40 start = 1'b1;
        #30 start = 1'b0;
    end

    initial begin
        clk = 1'b1;
        forever begin
            # 5 clk = ~clk;
        end
    end

endmodule
