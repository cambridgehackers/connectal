
import AxiEthBvi::*;

interface EthPins;
   interface AxiethbviMdio mdio;
   interface AxiethbviMgt mgt;
endinterface

interface AxiEthPins;
   interface EthPins eth;
endinterface