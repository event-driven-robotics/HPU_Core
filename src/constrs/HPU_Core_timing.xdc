# False paths
set_false_path -through [get_pins -hier *rx_align_req_meta_gckrx_cdc*/D]
set_false_path -to [get_pins -hier -regexp .*TIME_MACHINE_GCKRX.*rst_n.*/CLR]
set_false_path -to [get_pins -hier -regexp .*TIME_MACHINE_GCKRX.*rst.*/PRE]



