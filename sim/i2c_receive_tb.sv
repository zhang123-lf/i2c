module i2c_receive_tb;
    reg            rst_n           ;
    reg            clk             ;
    reg            i2c_ready       ;
    reg   [3:0]    i2c_data_bytes  ;
    wire           i2c_scl         ;
    wire             i2c_sda         ;
    reg    [7:0]    i2c_data        ;
    wire   [7:0]    i2c_data_receive;
    wire            i2c_data_valid  ;
    
    wire           i2c_sda_i;
    reg            i2c_sda_o;
//    reg   [1:0]    i2c_sda_i_r;
    reg            start_flag;
    reg   [2:0]    cnt;

    assign  i2c_sda_i = i2c_sda;
    assign  i2c_sda =start_flag? (i2c_data_valid?1'bz:i2c_sda_o):1'bz ;

    i2c_receive u_i2c_receive   ( 
      .rst_n         (rst_n         ),  
      .clk           (clk           ),
      .i2c_ready     (i2c_ready     ),
      .i2c_data_bytes(i2c_data_bytes),
      .i2c_scl       (i2c_scl       ),
      .i2c_sda       (i2c_sda       ),
      .i2c_data      (i2c_data_receive),
      .i2c_data_valid(i2c_data_valid)
    );

    initial begin
        rst_n = 1'b0    ;
        clk   = 1'b0    ;
        # 100 rst_n = 1'b1    ;
    end

    always #5 clk = ~clk ;// a clock with a period of 10

    initial begin
        i2c_ready = 1'b0    ;
        i2c_data_bytes = 4'd7;
        # 200 i2c_ready= 1'b1;
    end

//    always@(posedge clk or negedge rst_n)begin
//        if(!rst_n)begin
//            i2c_sda_i_r <= 2'd0 ;
//        end else 
//            i2c_sda_i_r <= {i2c_sda_i_r[1],i2c_sda_i};
//    end
//
//    always@(posedge clk or negedge rst_n)begin
//        if(!rst_n)begin
//            start_flag <= 1'b0;
//        end else begin
//            if(~i2c_sda_i_r[0] & i2c_sda_i_r[1] & ~i2c_scl)
//                start_flag <= 1'b1;
//            else
//                start_flag <= start_flag;
//        end
//    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            start_flag <= 1'b0;
        end else begin
            if(i2c_ready && i2c_data <= 8'hf6)
                start_flag <= 1'b1;
            else if(i2c_data > 8'hf6)
                start_flag <= 1'b0;
            else
                start_flag <= start_flag;
        end
    end




    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            i2c_sda_o = 1'bz   ;
            cnt <= 3'd0;
        end else begin
            if(start_flag & ~i2c_scl & ~i2c_data_valid)begin
                i2c_sda_o <= i2c_data[cnt];
                cnt <= cnt + 3'd1;
            end else if(i2c_data_valid)begin
                i2c_sda_o <= 1'bz ;
                cnt <= 3'd0;
            end else begin
                i2c_sda_o <= i2c_sda_o;
                cnt <= cnt ;
            end
        end
    end
    
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            i2c_data <= 8'b1111_0000;
        else if(i2c_data_valid)
            i2c_data <= i2c_data + 8'd1;
        else
            i2c_data <= i2c_data;
    end

    initial begin
        $fsdbDumpfile("tb.fsdb");
        $fsdbDumpvars(0,i2c_receive_tb);
        #4000 $finish;
    end


endmodule
