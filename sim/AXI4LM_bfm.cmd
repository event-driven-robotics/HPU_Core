## ##########################
PRT Spin2Neu VERSION TEST 
## ##########################
WAT 30
## ##########################

WAT 1000

##  Abilitazione DMA
WAT 2000
WRD CTRL    00001002
WAT 100
RDV CTRL    

##  Settaggio parametri RX
WAT 2000
WRD RXPAERCF 02020203
WAT 100 
RDV RXPAERCF

##  Abilitazione PAER 
WAT 2000
WRD RX_CTRL 00000002
WAT 100
RDV RX_CTRL   




## ##  Disabilitazione PAER 
## WAT 12000
## WRD RX_CTRL 00000000
## WAT 100
## RDV RX_CTRL  

## ##  Disabilitazione DMA
## WAT 100000
## WRD CTRL    00000000
## WAT 100
## RDV CTRL  

##  Ignora FIFO Full
WAT 250000
WRD RXPAERCF 04040213
WAT 100 
RDV RXPAERCF








## ##  Abilitazione TX PAER
## WAT 2000
## WRD TX_CTRL 00000002
## WAT 100
## RDV TX_CTRL   
##     
## ##  Abilitazione DMA
## WAT 2000
## WRD CTRL    00001002
## WAT 100
## RDV CTRL    
## 
## ##  Settaggio parametri TX
## WAT 4000
## WRD TXPAERCF 00000003
## WAT 100 
## RDV TXPAERCF
## 
## 
## WAT 4000
## DMW 8 1 00000001 00000002 00000003 00000004 00000005 00000006 00000007 00000008
## WAT 100 
## SDM 0

## 
## ##  Settaggio parametri TX
## WAT 4000
## WRD TXPAERCF 00000003
## WAT 100 
## RDV TXPAERCF
## 
## ##  DisAbilitazione TX PAER
## WAT 2000
## WRD TX_CTRL 00000002
## WAT 100
## RDV TX_CTRL   
## 
## WAT 4000
## DMW 8 1 00000001 00000002 00000003 00000004 00000005 00000006 00000007 00000008
## WAT 100 
## SDM 0
## 

PRT End test
## ##########################

##        
##      
##      
##      
##      

##      ##  Settaggio parametri RX
##      WAT 2000
##      WRD RXPAERCF 04040203
##      WAT 100 
##      RDV RXPAERCF
     
##      ##  Abilitazione PAER 
##      WAT 2000
##      WRD RX_CTRL 00000002
##      WAT 100
##      RDV RX_CTRL   
##      
##      ## ##  Disabilitazione PAER 
##      ## WAT 12000
##      ## WRD RX_CTRL 00000000
##      ## WAT 100
##      ## RDV RX_CTRL  
##      
##      ## ##  Disabilitazione DMA
##      ## WAT 100000
##      ## WRD CTRL    00000000
##      ## WAT 100
##      ## RDV CTRL  
##      
##      ##  Ignora FIFO Full
##      WAT 250000
##      WRD RXPAERCF 04040213
##      WAT 100 
##      RDV RXPAERCF
