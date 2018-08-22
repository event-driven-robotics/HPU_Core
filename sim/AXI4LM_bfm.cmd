## ##########################
PRT Spin2Neu VERSION TEST 
## ##########################
WAT 30
## ##########################

WAT 1000

##  Abilitazione DMA
WAT 2000
WRD CTRL    00001002

##  Abilitazione SpiNNlink AUX
WRD RX_CTRL 00000000
WAT 100
WRD AUX_CTRL 00000008

## Wait
WAT 10000

##  Abilitazione SpiNNlink TX
WRD TX_CTRL 00000068

##  Scrittura dati AXIStream
WAT 4000
DMW 8 1 00000001 00000002 00000003 00000004 00000005 00000006 00000007 00000008
WAT 100 
SDM 0
