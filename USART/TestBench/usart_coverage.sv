class usart_coverage extends uvm_subscriber #(apb_seq_item);

   `uvm_component_utils(usart_coverage)

   apb_seq_item tr;

   //--------------------------------------------------
   // Covergroup
   //--------------------------------------------------

   covergroup usart_cg;

      //-----------------------------------------
      // Address Coverage
      //-----------------------------------------

      ADDR_CP : coverpoint tr.paddr
      {
         bins CTRL   = {8'h00};
         bins BAUD   = {8'h04};
         bins TXDATA = {8'h08};
         bins RXDATA = {8'h0C};
         bins STATUS = {8'h10};
      }

      //-----------------------------------------
      // Read/Write Coverage
      //-----------------------------------------

      RW_CP : coverpoint tr.pwrite
      {
         bins READ  = {0};
         bins WRITE = {1};
      }

      //-----------------------------------------
      // CTRL Register Fields
      //-----------------------------------------

      MODE_CP : coverpoint tr.pwdata[0]
      iff(tr.pwrite && tr.paddr == 8'h00)
      {
         bins ASYNC = {0};
         bins SYNC  = {1};
      }

      DATA_LEN_CP : coverpoint tr.pwdata[2:1]
      iff(tr.pwrite && tr.paddr == 8'h00)
      {
         bins LEN5 = {0};
         bins LEN6 = {1};
         bins LEN7 = {2};
         bins LEN8 = {3};
      }

      PARITY_EN_CP : coverpoint tr.pwdata[3]
      iff(tr.pwrite && tr.paddr == 8'h00)
      {
         bins OFF = {0};
         bins ON  = {1};
      }

      PARITY_TYPE_CP : coverpoint tr.pwdata[4]
      iff(tr.pwrite && tr.paddr == 8'h00)
      {
         bins EVEN = {0};
         bins ODD  = {1};
      }

      STOP_CP : coverpoint tr.pwdata[6:5]
      iff(tr.pwrite && tr.paddr == 8'h00)
      {
         bins ONE = {0};
         bins TWO = {1};
      }

      //-----------------------------------------
      // TX Data Coverage
      //-----------------------------------------

      TXDATA_CP : coverpoint tr.pwdata[7:0]
      iff(tr.pwrite && tr.paddr == 8'h08)
      {
         bins ZERO = {8'h00};
         bins FF   = {8'hFF};

         bins LOW  = {[8'h01:8'h3F]};
         bins MID  = {[8'h40:8'hBF]};
         bins HIGH = {[8'hC0:8'hFE]};
      }

      //-----------------------------------------
      // Cross Coverage
      //-----------------------------------------

      MODE_X_PARITY_TYPE :
      cross MODE_CP,
            PARITY_EN_CP,
            PARITY_TYPE_CP;

      DATA_LEN_X_PARITY :
      cross DATA_LEN_CP,
            PARITY_EN_CP;

      MODE_X_STOP :
      cross MODE_CP,
            STOP_CP;

   endgroup

   //--------------------------------------------------
   // Constructor
   //--------------------------------------------------

   function new(string name,
                uvm_component parent);

      super.new(name,parent);

      usart_cg = new();

   endfunction

   //--------------------------------------------------
   // Sample
   //--------------------------------------------------

   function void write(apb_seq_item t);

      tr = t;

      usart_cg.sample();

   endfunction

  
endclass
