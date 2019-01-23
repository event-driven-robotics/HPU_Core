# HPU_Core
The **Head Processor Unit Core (HPU Core)** is an AXI peripheral used to manage different input AER or SpiNNlink streaming and transfer the acquired data into memory through DMA interface or by reading registers with Host CPU.
It is also Transmission capable, and permits to send AER or SpiNNlink streaming to external devices.
![alt text](https://github.com/event-driven-robotics/HPU_Core/blob/master/doc/HPU_module.PNG)

## HPU_Core Linux driver
Please, note that the HPU Linx driver needs the following kernel: https://github.com/andreamerello/linux-zynq-stable/tree/P2018_17_SPINNAKER
