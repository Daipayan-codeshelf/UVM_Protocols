class usart_scoreboard extends uvm_scoreboard;

   `uvm_component_utils(usart_scoreboard)

   uvm_tlm_analysis_fifo #(apb_seq_item)   apb_fifo;
   uvm_tlm_analysis_fifo #(usart_seq_item) usart_fifo;
   bit [7:0] exp_q[$];

   function new(string name,
                uvm_component parent);

      super.new(name, parent);

   endfunction


   function void build_phase(uvm_phase phase);

      super.build_phase(phase);

      apb_fifo   = new("apb_fifo", this);
      usart_fifo = new("usart_fifo", this);

   endfunction


   function void clear();

      apb_seq_item   apb_tmp;
      usart_seq_item rx_tmp;

      while (apb_fifo.try_get(apb_tmp));
      while (usart_fifo.try_get(rx_tmp));
     exp_q.delete();

   endfunction


   task run_phase(uvm_phase phase);

      apb_seq_item   apb_tr;
      usart_seq_item rx_tr;


      bit [7:0] expected_data;
      bit [1:0] current_data_len;

      current_data_len = 2'd3; // default 8-bit

      forever begin

         apb_fifo.get(apb_tr);

         //--------------------------------
         // Track CTRL register writes
         //--------------------------------
         if (apb_tr.pwrite &&
             apb_tr.paddr == 8'h00)
         begin

            current_data_len = apb_tr.pwdata[2:1];

            `uvm_info(
               "SCOREBOARD",
               $sformatf(
                  "Updated DATA_LEN=%0d",
                  current_data_len
               ),
               UVM_LOW
            );

         end

         //--------------------------------
         // TXDATA write
         //--------------------------------
         if (apb_tr.pwrite &&
             apb_tr.paddr == 8'h08)
         begin

            //--------------------------------
            // Apply correct mask
            //--------------------------------
            case (current_data_len)

               2'd0:
                  expected_data =
                     apb_tr.pwdata[7:0] & 8'h1F; // 5-bit

               2'd1:
                  expected_data =
                     apb_tr.pwdata[7:0] & 8'h3F; // 6-bit

               2'd2:
                  expected_data =
                     apb_tr.pwdata[7:0] & 8'h7F; // 7-bit

               default:
                  expected_data =
                     apb_tr.pwdata[7:0];         // 8-bit

            endcase
           exp_q.push_back(expected_data);

          `uvm_info(
             "SCOREBOARD",
             $sformatf(
                "QUEUE EXP=%h SIZE=%0d",
                expected_data,
                exp_q.size()
             ),
             UVM_LOW
          );

          

         end

      end
     
     fork

//----------------------------------
// APB THREAD
//----------------------------------
begin

   forever begin

      apb_fifo.get(apb_tr);

      // existing APB code

   end

end

//----------------------------------
// RX THREAD
//----------------------------------
begin

   forever begin

      usart_fifo.get(rx_tr);

      if(exp_q.size() == 0)
      begin

         `uvm_error(
            "SCOREBOARD",
            "RX received but queue empty"
         );

      end
      else
      begin

         expected_data =
         exp_q.pop_front();

         if(expected_data ==
            rx_tr.rx_data)
         begin

            `uvm_info(
               "SCOREBOARD",
               $sformatf(
                  "PASS EXP=%h RX=%h",
                  expected_data,
                  rx_tr.rx_data
               ),
               UVM_LOW
            );

         end
         else
         begin

            `uvm_error(
               "SCOREBOARD",
               $sformatf(
                  "FAIL EXP=%h RX=%h",
                  expected_data,
                  rx_tr.rx_data
               )
            );

         end

      end

   end

end

join

   endtask

endclass
