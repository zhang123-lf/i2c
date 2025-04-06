module i2c_send_tb();
    reg             rst_n       ;
    reg             clk         ;
    reg             pre_ready   ;
    reg   [7:0]     pre_data    ;
    wire            i2c_scl     ;
    wire            i2c_sda     ;
    wire            byte_done   ;
    wire            out_flag    ;

    i2c_send u_i2c_send(
      .rst_n     (rst_n    ),        
      .clk       (clk      ),   
      .pre_ready (pre_ready), 
      .pre_data  (pre_data ), 
      .out_flag  (out_flag ),
      .i2c_scl   (i2c_scl  ), 
      .i2c_sda   (i2c_sda  ), 
      .byte_done (byte_done) 
    );

    initial begin
    clk = 1'b1;
    forever
        # 10 clk = ~clk ;
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            pre_ready <= 1'b1   ;
            pre_data  <= 8'b1111_0000;
        end else if(byte_done)begin
            pre_ready <= 1'b1   ;
            pre_data  <= pre_data + 8'd1;
        end else begin
            pre_ready <= 1'b0   ;
            pre_data  <= pre_data;
        end
    end

    assign i2c_sda = out_flag ? (pre_data <= 8'b1111_0011 ? 1'b0:1'b1):1'bz;
   
    initial begin
        rst_n = 0;
        # 100 rst_n = 1;
    end

    initial begin 
        $fsdbDumpfile("tb.fsdb");
        $fsdbDumpvars(0,i2c_send_tb);
        #3000 $finish;
    end

endmodule
