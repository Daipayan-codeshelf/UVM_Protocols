interface usart_if;

   logic pclk;
   logic presetn;

   logic psel;
   logic penable;
   logic pwrite;

   logic [7:0]  paddr;
   logic [31:0] pwdata;
   logic [31:0] prdata;

   logic pready;

   logic txd;
   logic rxd;
   logic sclk;
  
   logic [7:0] rx_data_mon;
   logic       rx_valid_mon;

endinterface
