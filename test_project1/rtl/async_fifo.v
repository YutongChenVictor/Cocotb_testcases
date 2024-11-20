//深度为8，数据位宽为8的异步FIFO
module async_fifo #(
    parameter   DATA_DEPTH = 8,	//深度为8
    parameter   DATA_WIDTH = 8,	//数据位宽为8
    parameter   PTR_WIDTH  = 3	//读写指针位宽为3
    )(
    input  [DATA_WIDTH - 1 : 0] wr_data, 	//写数据
    input                   	wr_clk,	 	//写时钟
    input                   	wr_rst_n,	//写时钟复位
    input                   	wr_en,		//写使能
    input                   	rd_clk,		//读数据
    input                   	rd_rst_n,	//读时钟复位
    input                   	rd_en,		//读使能
    output reg                 	fifo_full,	//“满”标志位
    output reg                 	fifo_empty,	//“空”标志位
    output reg [DATA_WIDTH - 1 : 0] rd_data //写时钟
);

/*-----------------------------------------------------------------
-----------------------------伪双口RAM模块--------------------------
------------------------------------------------------------------*/

//定义一个宽度为8，深度为DEPTH的8的RAM_FIFO
reg [DATA_WIDTH - 1 : 0] ram_fifo [DATA_DEPTH - 1 : 0];

//写指针计数
reg [PTR_WIDTH : 0]  wr_ptr; //信息位+地址位所以指针位宽为4
always@ (posedge wr_clk or negedge wr_rst_n) begin
    if(!wr_rst_n) begin
        wr_ptr <= 0;
    end
    else if(wr_en && !fifo_full) begin
        wr_ptr <= wr_ptr + 1;
    end
    else begin
        wr_ptr <= wr_ptr;
    end
end

//RAM写入数据
wire [PTR_WIDTH -1 : 0]  wr_addr; 
assign wr_addr = wr_ptr[PTR_WIDTH -1 : 0];	//RAM写数据只需要地址位不需要信息位，所以寻址地址位宽为3
always@ (posedge wr_clk or negedge wr_rst_n) begin
    if(!wr_rst_n) begin
        ram_fifo[wr_addr] <= 0;	//复位
    end
    else if(wr_en && !fifo_full) begin
        ram_fifo[wr_addr] <= wr_data;	//数据写入
    end
    else begin
        ram_fifo[wr_addr] <= ram_fifo[wr_addr];	//保持不变
    end
end


//读指针计数
reg [PTR_WIDTH : 0]  rd_ptr;
always@ (posedge rd_clk or negedge rd_rst_n) begin
    if(!rd_rst_n) begin
        rd_ptr <= 0;
    end
    else if(rd_en && !fifo_empty) begin
        rd_ptr <= rd_ptr + 1;
    end
    else begin
        rd_ptr <= rd_ptr;
    end
end

//RAM读出数据
wire [PTR_WIDTH -1 : 0]  rd_addr;
assign rd_addr = rd_ptr[PTR_WIDTH -1 : 0];//RAM读数据只需要地址位不需要信息位，所以寻址地址位宽为3
always@ (posedge rd_clk or negedge rd_rst_n) begin
    if(!rd_rst_n) begin
        rd_data <= 0;	//复位
    end
    else if(rd_en && !fifo_empty) begin
        rd_data <= ram_fifo[rd_addr];	//读数据
    end
    else begin
        rd_data <= rd_data;		//保持不变
    end
end

/*--------------------------------------------------------------------------------------
---------------------------读写指针（格雷码）转换与跨时钟域同步模块------------------------
---------------------------------------------------------------------------------------*/

//读写指针转换成格雷码
wire [PTR_WIDTH : 0] wr_ptr_gray;
wire [PTR_WIDTH : 0] rd_ptr_gray;
assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

//写指针同步到读时钟域
//打两拍
reg [PTR_WIDTH : 0] wr_ptr_gray_r1;
reg [PTR_WIDTH : 0] wr_ptr_gray_r2;
always@ (posedge rd_clk or negedge rd_rst_n) begin
    if(!rd_rst_n) begin
        wr_ptr_gray_r1 <= 0;
        wr_ptr_gray_r2 <= 0;
    end
    else begin
        wr_ptr_gray_r1 <= wr_ptr_gray;
        wr_ptr_gray_r2 <= wr_ptr_gray_r1;
    end
end

//读指针同步到写时钟域
//打两拍
reg [PTR_WIDTH : 0] rd_ptr_gray_r1;
reg [PTR_WIDTH : 0] rd_ptr_gray_r2;
always@ (posedge wr_clk or negedge wr_rst_n) begin
    if(!wr_rst_n) begin
        rd_ptr_gray_r1 <= 0;
        rd_ptr_gray_r2 <= 0;
    end
    else begin
        rd_ptr_gray_r1 <= rd_ptr_gray;
        rd_ptr_gray_r2 <= rd_ptr_gray_r1;
    end
end

/*--------------------------------------------------------------------------------------
--------------------------------------空满信号判断模块-----------------------------------
---------------------------------------------------------------------------------------*/

//组合逻辑判断写满
always@ (*) begin
    if(!wr_rst_n) begin
        fifo_full <= 0;
    end
    else if( wr_ptr_gray == { ~rd_ptr_gray_r2[PTR_WIDTH : PTR_WIDTH - 1],
                               rd_ptr_gray_r2[PTR_WIDTH - 2 : 0] }) begin
        fifo_full <= 1;
    end
    else begin
        fifo_full <= 0;
    end
end

//组合逻辑判断读空
always@ (*) begin
    if(!rd_rst_n) begin
        fifo_empty <= 0;
    end
    else if(rd_ptr_gray == wr_ptr_gray_r2) begin
        fifo_empty <= 1;
    end
    else begin
        fifo_empty <= 0;
    end
end

endmodule
