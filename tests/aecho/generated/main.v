module top(input CLK, input nRST);
  always @( posedge CLK) begin
    if (!nRST) then begin
    end
    else begin

//processing _ZN4Echo7respond8respond26updateEv
    if (_ZN4Echo7respond8respond26updateEv__ENA) begin
    end; // if (_ZN4Echo7respond8respond26updateEv__ENA) 


//processing _ZN4Echo7respond8respond25guardEv
    _ZN4Echo7respond8respond25guardEv = 1;


//processing _ZN4Echo7respond8respond16updateEv
    if (_ZN4Echo7respond8respond16updateEv__ENA) begin
        echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_deq__ENA = 1;
        _ZN4Echo7respond8respond16updateEv_call = echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_first;
        _ZN14EchoIndication4echoEi(_ZN4Echo7respond8respond16updateEv_call);
    end; // if (_ZN4Echo7respond8respond16updateEv__ENA) 


//processing _ZN4Echo7respond8respond15guardEv
    _ZN4Echo7respond8respond15guardEv_tmp__1 = echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_deq__RDY;
    _ZN4Echo7respond8respond15guardEv_tmp__2 = echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_first__RDY;
    _ZN4Echo7respond8respond15guardEv = (_ZN4Echo7respond8respond15guardEv_tmp__1 & _ZN4Echo7respond8respond15guardEv_tmp__2);


//processing _ZN8EchoTest5drive6updateEv
    if (_ZN8EchoTest5drive6updateEv__ENA) begin
        echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_enq__ENA = 1;
            echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_enq_v = 22;
    end; // if (_ZN8EchoTest5drive6updateEv__ENA) 


//processing _ZN8EchoTest5drive5guardEv
    _ZN8EchoTest5drive5guardEv_tmp__1 = echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_enq__RDY;
    _ZN8EchoTest5drive5guardEv = _ZN8EchoTest5drive5guardEv_tmp__1;


//processing _ZN14EchoIndication4echoEi
        printf((("Heard an echo: %d\n")), _ZN14EchoIndication4echoEi_v);
        stop_main_program <= 1;


//processing printf

    end; // nRST
  end; // always @ (posedge CLK)
endmodule 

