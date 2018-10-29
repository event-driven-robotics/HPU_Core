##  ## ##########################
PRT Tlast features TEST 
##  ## ##########################
##  WAT 30
##  ## ##########################
##  
WAT 1000
##  Abilitazione DMA
WAT 2000
RDD RXPAERCF 02000100
WRD RXPAERCF 02000103
WRD TLASTTO  00000912
WRD CTRL     00009202
##  Abilitazione PAER AUX
WRD AUX_CTRL 00000002
WAT 100
## Wait
WAT 40000
PRT Disable DMA
WRD CTRL    00008200
PRT Wait a little that the trasfer finished
RDM CTRL    00000000 00000001 200
PRT DMA transfer finished
PRT Disable the AUX PAER Channel
WRD AUX_CTRL 00000000
WAT 4000
PRT Set DMA test bit
WRD DMA_B    00010100
PRT Set TLAST TO to a "limit" value to have some DUMMY during TLAST
WRD TLASTTO  000002AC
WRD CTRL     00009202
WAT 40000
PRT Disable DMA
WRD CTRL    00008200
PRT Wait a little that the trasfer finished
RDM CTRL    00000000 00000001 200
PRT DMA transfer finished
PRT Flush the Fifo RX
WRD CTRL    00009020
WAT 1000
