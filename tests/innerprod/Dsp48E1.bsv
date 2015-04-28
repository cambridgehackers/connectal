

interface Dsp48E1;
   method Bit#(48) p();
// Control: 4-bit (each) input: Control Inputs/Status Bits
   method Action alumode(Bit#(4) v);		// 4-bit input: ALU control input
   method Action carryinsel(Bit#(3) v);		// 3-bit input: Carry select input
   method Action inmode(Bit#(5) v);		// 5-bit input: INMODE control input
   method Action opmode(Bit#(7) v);		// 7-bit input: Operation mode input
   method Action a(Bit#(30) v);
   method Action b(Bit#(18) v);
   method Action c(Bit#(48) v);
   method Action d(Bit#(25) v);
endinterface

(* always_ready, always_enabled *)
interface PRIM_DSP48E1;
   method Bit#(48) p();
// Control: 4-bit (each) input: Control Inputs/Status Bits
   method Action alumode(Bit#(4) v);		// 4-bit input: ALU control input
   method Action carryinsel(Bit#(3) v);		// 3-bit input: Carry select input
   method Action inmode(Bit#(5) v);		// 5-bit input: INMODE control input
   method Action opmode(Bit#(7) v);		// 7-bit input: Operation mode input
   method Action a(Bit#(30) v);
   method Action b(Bit#(18) v);
   method Action c(Bit#(48) v);
   method Action d(Bit#(25) v);
   method Action cea1(Bit#(1) en);		// 1-bit input: Clock enable input for 1st stage AREG
   method Action cea2(Bit#(1) en);		// 1-bit input: Clock enable input for 2nd stage AREG
   method Action cead(Bit#(1) en);		// 1-bit input: Clock enable input for ADREG
   method Action ceb1(Bit#(1) en);		// 1-bit input: Clock enable input for 1st stage BREG
   method Action ceb2(Bit#(1) en);		// 1-bit input: Clock enable input for 2nd stage BREG
   method Action cealumode(Bit#(1) en);		// 1-bit input: Clock enable input for ALUMODE
   method Action cec(Bit#(1) en);		// 1-bit input: Clock enable input for CREG
   method Action cecarryin(Bit#(1) en);		// 1-bit input: Clock enable input for CARRYINREG
   method Action cectrl(Bit#(1) en);		// 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
   method Action ced(Bit#(1) en);		// 1-bit input: Clock enable input for DREG
   method Action ceinmode(Bit#(1) en);		// 1-bit input: Clock enable input for INMODEREG
   method Action cem(Bit#(1) en);		// 1-bit input: Clock enable input for MREG
   method Action cep(Bit#(1) en);		// 1-bit input: Clock enable input for PREG
   method Action rsta(Bit#(1) rst);		// 1-bit input: Reset input for AREG
   method Action rstallcarryin(Bit#(1) rst);		// 1-bit input: Reset input for CARRYINREG
   method Action rstalumode(Bit#(1) rst);		// 1-bit input: Reset input for ALUMODEREG
   method Action rstb(Bit#(1) rst);		// 1-bit input: Reset input for BREG
   method Action rstc(Bit#(1) rst);		// 1-bit input: Reset input for CREG
   method Action rstctrl(Bit#(1) rst);		// 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
   method Action rstd(Bit#(1) rst);		// 1-bit input: Reset input for DREG and ADREG
   method Action rstinmode(Bit#(1) rst);		// 1-bit input: Reset input for INMODEREG
   method Action rstm(Bit#(1) rst);		// 1-bit input: Reset input for MREG
   method Action rstp(Bit#(1) rst);		// 1-bit input: Reset input for PREG
endinterface

import "BVI" DSP48E1 =
module vmkDSP48E1(PRIM_DSP48E1);
   default_clock clk(CLK);
   no_reset;

   method P p();
   method alumode(ALUMODE) enable ((*inhigh*)EN_alumode);
   method carryinsel(CARRYINSEL) enable ((*inhigh*)EN_carryinsel);
   method inmode(INMODE) enable ((*inhigh*)EN_inmode);
   method opmode(OPMODE) enable ((*inhigh*)EN_opmode);
   method a(A) enable ((*inhigh*)EN_a);
   method b(B) enable ((*inhigh*)EN_b);
   method c(C) enable ((*inhigh*)EN_c);
   method d(D) enable ((*inhigh*)EN_d);

   method cea1(CEA1) enable ((*inhigh*)EN_cea1);
   method cea2(CEA2) enable ((*inhigh*)EN_cea2);
   method cead(CEAD) enable ((*inhigh*)EN_cead);
   method ceb1(CEB1) enable ((*inhigh*)EN_ceb1);
   method ceb2(CEB2) enable ((*inhigh*)EN_ceb2);
   method cealumode(CEALUMODE) enable ((*inhigh*)EN_cealumode);
   method cec(CEC) enable ((*inhigh*)EN_cec);
   method cecarryin(CECARRYIN) enable ((*inhigh*)EN_cecarryin);
   method cectrl(CECTRL) enable ((*inhigh*)EN_cectrl);
   method ced(CED) enable ((*inhigh*)EN_ced);
   method ceinmode(CEINMODE) enable ((*inhigh*)EN_ceinmode);
   method cem(CEM) enable ((*inhigh*)EN_cem);
   method cep(CEP) enable ((*inhigh*)EN_cep);
   method rsta(RSTA) enable ((*inhigh*)EN_rsta);
   method rstallcarryin(RSTALLCARRYIN) enable ((*inhigh*)EN_rstallcarryin);
   method rstalumode(RSTALUMODE) enable ((*inhigh*)EN_rstalumode);
   method rstb(RSTB) enable ((*inhigh*)EN_rstb);
   method rstc(RSTC) enable ((*inhigh*)EN_rstc);
   method rstctrl(RSTCTRL) enable ((*inhigh*)EN_rstctrl);
   method rstd(RSTD) enable ((*inhigh*)EN_rstd);
   method rstinmode(RSTINMODE) enable ((*inhigh*)EN_rstinmode);
   method rstm(RSTM) enable ((*inhigh*)EN_rstm);
   method rstp(RSTP) enable ((*inhigh*)EN_rstp);
   schedule (alumode,carryinsel,inmode,opmode,a,b,c,d,cea1,cea2,cead,ceb1,ceb2,cealumode,cec,cecarryin,cectrl,ced,ceinmode,cem,cep,rsta,rstallcarryin,rstalumode,rstb,rstc,rstctrl,rstd,rstinmode,rstm,rstp,p)
      CF (alumode,carryinsel,inmode,opmode,a,b,c,d,cea1,cea2,cead,ceb1,ceb2,cealumode,cec,cecarryin,cectrl,ced,ceinmode,cem,cep,rsta,rstallcarryin,rstalumode,rstb,rstc,rstctrl,rstd,rstinmode,rstm,rstp,p);
endmodule

module mkDsp48E1(Dsp48E1);
   let dsp <- vmkDSP48E1();
   Wire#(Bit#(4)) alumodeWire <- mkDWire(0);
   Wire#(Bit#(3)) carryinselWire <- mkDWire(0);
   Wire#(Bit#(5)) inmodeWire <- mkDWire(0);
   Wire#(Bit#(7)) opmodeWire <- mkDWire(0);
   Wire#(Bit#(30)) aWire <- mkDWire(0);
   Wire#(Bit#(18)) bWire <- mkDWire(0);
   Wire#(Bit#(48)) cWire <- mkDWire(0);
   Wire#(Bit#(25)) dWire <- mkDWire(0);

   Wire#(Bit#(1)) ce1Wire <- mkDWire(0);
   Reg#(Bit#(1)) ce2Reg <- mkReg(0);
   Reg#(Bit#(1)) cepReg <- mkReg(0);

   rule clock_enable_and_reset;
      ce2Reg <= ce1Wire;
      cepReg <= ce2Reg;

      dsp.cea1(ce1Wire);
      dsp.cea2(ce2Reg);
      dsp.cead(1);
      dsp.ceb1(ce1Wire);
      dsp.ceb2(ce2Reg);
      dsp.cealumode(ce1Wire);
      dsp.cec(1);
      dsp.cecarryin(1);
      dsp.cectrl(1);
      dsp.ced(1);
      dsp.ceinmode(1);
      dsp.cem(1);
      dsp.cep(cepReg);

      dsp.rsta(0);
      dsp.rstallcarryin(0);
      dsp.rstalumode(0);
      dsp.rstb(0);
      dsp.rstc(0);
      dsp.rstctrl(0);
      dsp.rstd(0);
      dsp.rstinmode(0);
      dsp.rstm(0);
      dsp.rstp(0);
   endrule

   rule driveInputs;
      dsp.alumode(alumodeWire);
      dsp.carryinsel(carryinselWire);
      dsp.inmode(inmodeWire);
      dsp.opmode(opmodeWire);
      dsp.a(aWire);
      dsp.b(bWire);
      dsp.c(cWire);
      dsp.d(dWire);
   endrule

   method Action alumode(Bit#(4) v);
      alumodeWire <= v;
   endmethod
   method Action carryinsel(Bit#(3) v);
      carryinselWire <= v;
   endmethod
   method Action inmode(Bit#(5) v);
      inmodeWire <= v;
   endmethod
   method Action opmode(Bit#(7) v);
      opmodeWire <= v;
   endmethod
   method Action a(Bit#(30) v);
      ce1Wire <= 1;
      aWire <= v;
   endmethod
   method Action b(Bit#(18) v);
      bWire <= v;
   endmethod
   method Action c(Bit#(48) v);
      cWire <= v;
   endmethod
   method Action d(Bit#(25) v);
      dWire <= v;
   endmethod
   method Bit#(48) p();
      return dsp.p();
   endmethod
endmodule
