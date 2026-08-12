class usart_regression_test extends uvm_test;

   `uvm_component_utils(usart_regression_test)

   usart_env env;
   virtual usart_if vif;

   function new(
      string name="usart_regression_test",
      uvm_component parent=null
   );
      super.new(name,parent);
   endfunction

   function void build_phase(
      uvm_phase phase
   );

      super.build_phase(phase);

      env =
      usart_env::type_id::create(
         "env",
         this
      );

      if(!uvm_config_db#
         (virtual usart_if)::get(
            this,
            "",
            "vif",
            vif
         ))
      begin
         `uvm_fatal(
            "NOVIF",
            "No interface"
         );
      end

   endfunction
   task reset_dut();

       `uvm_info("RESET",
                 "Applying DUT reset",
                 UVM_LOW)

       vif.presetn <= 0;

       repeat(5)
          @(posedge vif.pclk);

       vif.presetn <= 1;

       repeat(20)
          @(posedge vif.pclk);

       `uvm_info("RESET",
                 "DUT reset complete",
                 UVM_LOW)

    endtask

   task run_phase(
      uvm_phase phase
   );

      sync_mode_seq      sync_seq;
      parity_even_seq    even_seq;
      parity_odd_seq     odd_seq;
      stop_bit_seq       stop_seq;
      data_len_seq       len_seq;
      data_len_5_seq     len5_seq;
      reg_readback_seq   reg_seq;
      csr_stress_seq     csr_seq;
      multi_byte_seq     multi_seq;
      fifo_overflow_seq  ovf_seq;
      fifo_underflow_seq udf_seq;
      random_cfg_seq     rand_seq;

      phase.raise_objection(this);

      wait(vif.presetn);

     repeat(5)
         @(posedge vif.pclk);

      //----------------------------------
      // SYNC MODE
      //----------------------------------

      `uvm_info("REGRESSION",
                "START sync_mode_seq",
                UVM_LOW)

      sync_seq =
      sync_mode_seq::type_id::create(
         "sync_seq"
      );

      sync_seq.start(
         env.apb_agt.seqr
      );

     reset_dut();
     repeat(200) @(posedge vif.pclk);


      //----------------------------------
      // PARITY EVEN
      //----------------------------------

      `uvm_info("REGRESSION",
                "START parity_even_seq",
                UVM_LOW)

      even_seq =
      parity_even_seq::type_id::create(
         "even_seq"
      );

      even_seq.start(
         env.apb_agt.seqr
      );

      reset_dut();
      repeat(200) @(posedge vif.pclk);

   

      //----------------------------------
      // PARITY ODD
      //----------------------------------

      `uvm_info("REGRESSION",
                "START parity_odd_seq",
                UVM_LOW)

      odd_seq =
      parity_odd_seq::type_id::create(
         "odd_seq"
      );

      odd_seq.start(
         env.apb_agt.seqr
      );

       reset_dut();
      repeat(200) @(posedge vif.pclk);

 

      //----------------------------------
      // STOP BITS
      //----------------------------------

      `uvm_info("REGRESSION",
                "START stop_bit_seq",
                UVM_LOW)

      stop_seq =
      stop_bit_seq::type_id::create(
         "stop_seq"
      );

      stop_seq.start(
         env.apb_agt.seqr
      );

      reset_dut();
      repeat(200) @(posedge vif.pclk);

 

      //----------------------------------
      // DATA LENGTH
      //----------------------------------

      `uvm_info("REGRESSION",
                "START data_len_seq",
                UVM_LOW)

      len_seq =
      data_len_seq::type_id::create(
         "len_seq"
      );

      len_seq.start(
         env.apb_agt.seqr
      );

       reset_dut();
      repeat(200) @(posedge vif.pclk);


     
      //----------------------------------
      // DATA LEN 5
      //----------------------------------

      `uvm_info("REGRESSION",
                "START data_len_5_seq",
                UVM_LOW)

      len5_seq =
      data_len_5_seq::type_id::create(
         "len5_seq"
      );

      len5_seq.start(
         env.apb_agt.seqr
      );

       reset_dut();
      repeat(200) @(posedge vif.pclk);



      //----------------------------------
      // REGISTER READBACK
      //----------------------------------

      `uvm_info("REGRESSION",
                "START reg_readback_seq",
                UVM_LOW)

      reg_seq =
      reg_readback_seq::type_id::create(
         "reg_seq"
      );

      reg_seq.start(
         env.apb_agt.seqr
      );

       reset_dut();
      repeat(200) @(posedge vif.pclk);


     
     
     //----------------------------------
      // CSR STRESS
      //----------------------------------

      `uvm_info("REGRESSION",
                "START csr_stress_seq",
                UVM_LOW)

      csr_seq =
      csr_stress_seq::type_id::create(
         "csr_seq"
      );

      csr_seq.start(
         env.apb_agt.seqr
      );

       reset_dut();
      repeat(200) @(posedge vif.pclk);

 

      //----------------------------------
      // MULTI BYTE
      //----------------------------------

      `uvm_info("REGRESSION",
                "START multi_byte_seq",
                UVM_LOW)

      multi_seq =
      multi_byte_seq::type_id::create(
         "multi_seq"
      );

      multi_seq.start(
         env.apb_agt.seqr
      );

     reset_dut();
      repeat(200) @(posedge vif.pclk);



      //----------------------------------
      // FIFO OVERFLOW
      //----------------------------------

      `uvm_info("REGRESSION",
                "START fifo_overflow_seq",
                UVM_LOW)

      ovf_seq =
      fifo_overflow_seq::type_id::create(
         "ovf_seq"
      );

      ovf_seq.start(
         env.apb_agt.seqr
      );

     reset_dut();
      repeat(200) @(posedge vif.pclk);

     

      //----------------------------------
      // FIFO UNDERFLOW
      //----------------------------------

      `uvm_info("REGRESSION",
                "START fifo_underflow_seq",
                UVM_LOW)

      udf_seq =
      fifo_underflow_seq::type_id::create(
         "udf_seq"
      );

      udf_seq.start(
         env.apb_agt.seqr
      );

      reset_dut();
      repeat(200) @(posedge vif.pclk);


      //----------------------------------
      // RANDOM CONFIG
      //----------------------------------

      `uvm_info("REGRESSION",
                "START random_cfg_seq",
                UVM_LOW)

      rand_seq =
      random_cfg_seq::type_id::create(
         "rand_seq"
      );

      rand_seq.start(
         env.apb_agt.seqr
      );

    reset_dut();
      repeat(200) @(posedge vif.pclk);


      `uvm_info("REGRESSION",
                "ALL SEQUENCES COMPLETED",
                UVM_LOW)

      phase.drop_objection(this);

   endtask

endclass
