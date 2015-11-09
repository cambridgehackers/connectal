module top(input CLK, input nRST);
  always @( posedge CLK) begin
    if (!nRST) then begin
    end
    else begin
//processing _ZN4Echo7respond8respond23RDYEv
        _ZN4Echo7respond8respond23RDYEv = 1;

//processing _ZN4Echo7respond8respond23ENAEv
    if (_ZN4Echo7respond8respond23ENAEv__ENA) begin
    end; // if (_ZN4Echo7respond8respond23ENAEv__ENA) 

//processing _ZN4Echo7respond8respond13RDYEv
    _ZN4Echo7respond8respond13RDYEv_tmp__1 = echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_deq__RDY;
    _ZN4Echo7respond8respond13RDYEv_tmp__2 = echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_first__RDY;
        _ZN4Echo7respond8respond13RDYEv = (_ZN4Echo7respond8respond13RDYEv_tmp__1 & _ZN4Echo7respond8respond13RDYEv_tmp__2);

//processing _ZN4Echo7respond8respond13ENAEv
    if (_ZN4Echo7respond8respond13ENAEv__ENA) begin
        echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_deq__ENA = 1;
        _ZN4Echo7respond8respond13ENAEv_call = echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_first;
        _ZN14EchoIndication4echoEi(_ZN4Echo7respond8respond13ENAEv_call);
    end; // if (_ZN4Echo7respond8respond13ENAEv__ENA) 

//processing _ZN8EchoTest5drive3RDYEv
    _ZN8EchoTest5drive3RDYEv_tmp__1 = echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_enq__RDY;
        _ZN8EchoTest5drive3RDYEv = _ZN8EchoTest5drive3RDYEv_tmp__1;

//processing _ZN8EchoTest5drive3ENAEv
    if (_ZN8EchoTest5drive3ENAEv__ENA) begin
        echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_enq__ENA = 1;
            echoTest_ZZ_EchoTest_ZZ_echo_ZZ__ZZ_Echo_ZZ_fifo_ZZ__ZZ_Fifo1_int_enq_v = 22;
    end; // if (_ZN8EchoTest5drive3ENAEv__ENA) 

//processing _ZN14EchoIndication4echoEi
        printf((("Heard an echo: %d\n")), _ZN14EchoIndication4echoEi_v);
        stop_main_program <= 1;

//processing printf

    end; // nRST
  end; // always @ (posedge CLK)
endmodule 

