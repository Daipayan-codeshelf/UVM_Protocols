`timescale 1ns/1ps

`include "usart_if.sv"
`include "usart_pkg.sv"

import uvm_pkg::*;
import usart_pkg::*;

module testbench;

   //////////////////////////////////////
   // Interface
   //////////////////////////////////////

   usart_if vif();

   //////////////////////////////////////
   // Clock
   //////////////////////////////////////

   initial begin
      vif.pclk = 0;
      forever #5 vif.pclk = ~vif.pclk;
   end

   //////////////////////////////////////
   // Reset
   //////////////////////////////////////

   initial begin
      vif.presetn = 0;

      vif.psel    = 0;
      vif.penable = 0;
      vif.pwrite  = 0;
      vif.paddr   = 0;
      vif.pwdata  = 0;

      repeat(10) @(posedge vif.pclk);

      vif.presetn = 1;
   end

   //////////////////////////////////////
   // Loopback
   //////////////////////////////////////

   assign vif.rxd = vif.txd;

   //////////////////////////////////////
   // DUT
   //////////////////////////////////////

   usart_top dut(
      .pclk    (vif.pclk),
      .presetn (vif.presetn),

      .psel    (vif.psel),
      .penable (vif.penable),
      .pwrite  (vif.pwrite),
      .paddr   (vif.paddr),
      .pwdata  (vif.pwdata),

      .prdata  (vif.prdata),
      .pready  (vif.pready),

      .rxd     (vif.rxd),
      .txd     (vif.txd),
      .sclk    (vif.sclk)
   );
  
  
  
  
    always_comb begin
     vif.rx_data_mon  = dut.rx_data;
     vif.rx_valid_mon = dut.rx_valid;
    end

   //////////////////////////////////////
   // UVM Config + Start Test
   //////////////////////////////////////

   initial begin

      uvm_config_db #(virtual usart_if)::set(
         null,
         "*",
         "vif",
         vif
      );

      run_test();

   end
  
  
  initial begin
   $dumpfile("dump.vcd");
   $dumpvars(0,testbench);
end
  
  
  
  always @(posedge vif.pclk)
begin
   $display(
      "[%0t] BUS psel=%0b penable=%0b pwrite=%0b paddr=%h pwdata=%h",
      $time,
      vif.psel,
      vif.penable,
      vif.pwrite,
      vif.paddr,
      vif.pwdata
   );
end

endmodule
