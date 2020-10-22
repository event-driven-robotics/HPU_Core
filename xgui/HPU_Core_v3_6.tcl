
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/HPUCore_v3_0.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {Interface Definitions}]
  #Adding Group
  set Interfaces [ipgui::add_group $IPINST -name "Interfaces" -parent ${Page_0}]
  #Adding Group
  set PAER [ipgui::add_group $IPINST -name "PAER" -parent ${Interfaces}]
  set C_PAER_DSIZE [ipgui::add_param $IPINST -name "C_PAER_DSIZE" -parent ${PAER}]
  set_property tooltip {Size of PAER address} ${C_PAER_DSIZE}
  #Adding Group
  set TX [ipgui::add_group $IPINST -name "TX" -parent ${PAER} -display_name {PAER TX}]
  set C_TX_HAS_PAER [ipgui::add_param $IPINST -name "C_TX_HAS_PAER" -parent ${TX}]
  set_property tooltip {If  checked, the TX PAER interface is exposed} ${C_TX_HAS_PAER}

  #Adding Group
  set RX [ipgui::add_group $IPINST -name "RX" -parent ${PAER} -display_name {PAER RX}]
  set C_RX_HAS_PAER [ipgui::add_param $IPINST -name "C_RX_HAS_PAER" -parent ${RX}]
  set_property tooltip {If checked, the RX PAER interface is exposed} ${C_RX_HAS_PAER}
  #Adding Group
  set Sensor_IDs [ipgui::add_group $IPINST -name "Sensor IDs" -parent ${RX} -display_name {Sensor type} -layout horizontal]
  set_property tooltip {Sensor type} ${Sensor_IDs}
  set C_RX_PAER_R_SENS_ID [ipgui::add_param $IPINST -name "C_RX_PAER_R_SENS_ID" -parent ${Sensor_IDs} -widget comboBox]
  set_property tooltip {Right Rx PAER Sensor Type} ${C_RX_PAER_R_SENS_ID}
  set C_RX_PAER_L_SENS_ID [ipgui::add_param $IPINST -name "C_RX_PAER_L_SENS_ID" -parent ${Sensor_IDs} -widget comboBox]
  set_property tooltip {Left Rx PAER Sensor Type} ${C_RX_PAER_L_SENS_ID}
  set C_RX_PAER_A_SENS_ID [ipgui::add_param $IPINST -name "C_RX_PAER_A_SENS_ID" -parent ${Sensor_IDs} -widget comboBox]
  set_property tooltip {Aux Rx PAER Sensor Type} ${C_RX_PAER_A_SENS_ID}



  #Adding Group
  set TX_Interfaces [ipgui::add_group $IPINST -name "TX Interfaces" -parent ${Interfaces} -display_name {HSSAER}]
  #Adding Group
  set HSSAER_TX [ipgui::add_group $IPINST -name "HSSAER TX" -parent ${TX_Interfaces}]
  set C_TX_HSSAER_N_CHAN [ipgui::add_param $IPINST -name "C_TX_HSSAER_N_CHAN" -parent ${HSSAER_TX}]
  set_property tooltip {The number of TX HSSAER channels} ${C_TX_HSSAER_N_CHAN}
  set C_TX_HAS_HSSAER [ipgui::add_param $IPINST -name "C_TX_HAS_HSSAER" -parent ${HSSAER_TX}]
  set_property tooltip {If checked, the TX HSSAER interface is exposed} ${C_TX_HAS_HSSAER}

  #Adding Group
  set HSSAER_RX [ipgui::add_group $IPINST -name "HSSAER RX" -parent ${TX_Interfaces}]
  set C_RX_HAS_HSSAER [ipgui::add_param $IPINST -name "C_RX_HAS_HSSAER" -parent ${HSSAER_RX}]
  set_property tooltip {If checked, the RX HSSAER interface is exposed} ${C_RX_HAS_HSSAER}
  set C_RX_HSSAER_N_CHAN [ipgui::add_param $IPINST -name "C_RX_HSSAER_N_CHAN" -parent ${HSSAER_RX}]
  set_property tooltip {The number of RX HSSAER channels} ${C_RX_HSSAER_N_CHAN}
  #Adding Group
  set Ch_0 [ipgui::add_group $IPINST -name "Ch 0" -parent ${HSSAER_RX} -display_name {Right port sensor type} -layout horizontal]
  set_property tooltip {Right port sensor type} ${Ch_0}
  ipgui::add_param $IPINST -name "C_RX_SAER0_R_SENS_ID" -parent ${Ch_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_RX_SAER1_R_SENS_ID" -parent ${Ch_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_RX_SAER2_R_SENS_ID" -parent ${Ch_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_RX_SAER3_R_SENS_ID" -parent ${Ch_0} -widget comboBox

  #Adding Group
  set Channel_1 [ipgui::add_group $IPINST -name "Channel 1" -parent ${HSSAER_RX} -display_name {Left port sensor type} -layout horizontal]
  set_property tooltip {Left port sensor type} ${Channel_1}
  ipgui::add_param $IPINST -name "C_RX_SAER0_L_SENS_ID" -parent ${Channel_1} -widget comboBox
  ipgui::add_param $IPINST -name "C_RX_SAER1_L_SENS_ID" -parent ${Channel_1} -widget comboBox
  ipgui::add_param $IPINST -name "C_RX_SAER2_L_SENS_ID" -parent ${Channel_1} -widget comboBox
  ipgui::add_param $IPINST -name "C_RX_SAER3_L_SENS_ID" -parent ${Channel_1} -widget comboBox

  #Adding Group
  set Channel_2 [ipgui::add_group $IPINST -name "Channel 2" -parent ${HSSAER_RX} -display_name {Aux port sensor type} -layout horizontal]
  set_property tooltip {Aux port sensor type} ${Channel_2}
  ipgui::add_param $IPINST -name "C_RX_SAER0_A_SENS_ID" -parent ${Channel_2} -widget comboBox
  ipgui::add_param $IPINST -name "C_RX_SAER1_A_SENS_ID" -parent ${Channel_2} -widget comboBox
  ipgui::add_param $IPINST -name "C_RX_SAER2_A_SENS_ID" -parent ${Channel_2} -widget comboBox
  ipgui::add_param $IPINST -name "C_RX_SAER3_A_SENS_ID" -parent ${Channel_2} -widget comboBox



  #Adding Group
  set GTP [ipgui::add_group $IPINST -name "GTP" -parent ${Interfaces} -display_name {GTP (To Be Developed)}]
  set C_RX_HAS_GTP [ipgui::add_param $IPINST -name "C_RX_HAS_GTP" -parent ${GTP}]
  set_property tooltip {If checked, the RX GTP interface is exposed} ${C_RX_HAS_GTP}
  set C_TX_HAS_GTP [ipgui::add_param $IPINST -name "C_TX_HAS_GTP" -parent ${GTP}]
  set_property tooltip {If checked, the TX GTP interface is exposed} ${C_TX_HAS_GTP}

  #Adding Group
  set SpiNNlink [ipgui::add_group $IPINST -name "SpiNNlink" -parent ${Interfaces}]
  set C_RX_HAS_SPNNLNK [ipgui::add_param $IPINST -name "C_RX_HAS_SPNNLNK" -parent ${SpiNNlink}]
  set_property tooltip {If checked, the RX SpiNNlink interface is exposed} ${C_RX_HAS_SPNNLNK}
  set C_TX_HAS_SPNNLNK [ipgui::add_param $IPINST -name "C_TX_HAS_SPNNLNK" -parent ${SpiNNlink}]
  set_property tooltip {If checked, the TX SpiNNlink interface is exposed} ${C_TX_HAS_SPNNLNK}
  set C_PSPNNLNK_WIDTH [ipgui::add_param $IPINST -name "C_PSPNNLNK_WIDTH" -parent ${SpiNNlink}]
  set_property tooltip {Size of SpiNNaker parallel data interface} ${C_PSPNNLNK_WIDTH}

  #Adding Group
  set Debug [ipgui::add_group $IPINST -name "Debug" -parent ${Interfaces}]
  ipgui::add_param $IPINST -name "C_DEBUG" -parent ${Debug}



  #Adding Page
  set AXI_Parameters [ipgui::add_page $IPINST -name "AXI Parameters" -display_name {Microprocessor Side}]
  #Adding Group
  set AXI4_Lite_Parameters [ipgui::add_group $IPINST -name "AXI4 Lite Parameters" -parent ${AXI_Parameters} -display_name {AXI4 Lite Parameters (should not be edited)}]
  set_property tooltip {AXI4 Lite Parameters (should not be edited)} ${AXI4_Lite_Parameters}
  ipgui::add_param $IPINST -name "C_S_AXI_ADDR_WIDTH" -parent ${AXI4_Lite_Parameters}
  ipgui::add_param $IPINST -name "C_S_AXI_DATA_WIDTH" -parent ${AXI4_Lite_Parameters}



}

proc update_PARAM_VALUE.C_PAER_DSIZE { PARAM_VALUE.C_PAER_DSIZE PARAM_VALUE.C_TX_HAS_PAER PARAM_VALUE.C_RX_HAS_PAER } {
	# Procedure called to update C_PAER_DSIZE when any of the dependent parameters in the arguments change
	
	set C_PAER_DSIZE ${PARAM_VALUE.C_PAER_DSIZE}
	set C_TX_HAS_PAER ${PARAM_VALUE.C_TX_HAS_PAER}
	set C_RX_HAS_PAER ${PARAM_VALUE.C_RX_HAS_PAER}
	set values(C_TX_HAS_PAER) [get_property value $C_TX_HAS_PAER]
	set values(C_RX_HAS_PAER) [get_property value $C_RX_HAS_PAER]
	if { [gen_USERPARAMETER_C_PAER_DSIZE_ENABLEMENT $values(C_TX_HAS_PAER) $values(C_RX_HAS_PAER)] } {
		set_property enabled true $C_PAER_DSIZE
	} else {
		set_property enabled false $C_PAER_DSIZE
	}
}

proc validate_PARAM_VALUE.C_PAER_DSIZE { PARAM_VALUE.C_PAER_DSIZE } {
	# Procedure called to validate C_PAER_DSIZE
	return true
}

proc update_PARAM_VALUE.C_RX_HSSAER_N_CHAN { PARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_HSSAER_N_CHAN when any of the dependent parameters in the arguments change
	
	set C_RX_HSSAER_N_CHAN ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}
	set C_RX_HAS_HSSAER ${PARAM_VALUE.C_RX_HAS_HSSAER}
	set values(C_RX_HAS_HSSAER) [get_property value $C_RX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_RX_HSSAER_N_CHAN_ENABLEMENT $values(C_RX_HAS_HSSAER)] } {
		set_property enabled true $C_RX_HSSAER_N_CHAN
	} else {
		set_property enabled false $C_RX_HSSAER_N_CHAN
	}
}

proc validate_PARAM_VALUE.C_RX_HSSAER_N_CHAN { PARAM_VALUE.C_RX_HSSAER_N_CHAN } {
	# Procedure called to validate C_RX_HSSAER_N_CHAN
	return true
}

proc update_PARAM_VALUE.C_RX_PAER_A_SENS_ID { PARAM_VALUE.C_RX_PAER_A_SENS_ID PARAM_VALUE.C_RX_HAS_PAER } {
	# Procedure called to update C_RX_PAER_A_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_PAER_A_SENS_ID ${PARAM_VALUE.C_RX_PAER_A_SENS_ID}
	set C_RX_HAS_PAER ${PARAM_VALUE.C_RX_HAS_PAER}
	set values(C_RX_HAS_PAER) [get_property value $C_RX_HAS_PAER]
	if { [gen_USERPARAMETER_C_RX_PAER_A_SENS_ID_ENABLEMENT $values(C_RX_HAS_PAER)] } {
		set_property enabled true $C_RX_PAER_A_SENS_ID
	} else {
		set_property enabled false $C_RX_PAER_A_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_PAER_A_SENS_ID { PARAM_VALUE.C_RX_PAER_A_SENS_ID } {
	# Procedure called to validate C_RX_PAER_A_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_PAER_L_SENS_ID { PARAM_VALUE.C_RX_PAER_L_SENS_ID PARAM_VALUE.C_RX_HAS_PAER } {
	# Procedure called to update C_RX_PAER_L_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_PAER_L_SENS_ID ${PARAM_VALUE.C_RX_PAER_L_SENS_ID}
	set C_RX_HAS_PAER ${PARAM_VALUE.C_RX_HAS_PAER}
	set values(C_RX_HAS_PAER) [get_property value $C_RX_HAS_PAER]
	if { [gen_USERPARAMETER_C_RX_PAER_L_SENS_ID_ENABLEMENT $values(C_RX_HAS_PAER)] } {
		set_property enabled true $C_RX_PAER_L_SENS_ID
	} else {
		set_property enabled false $C_RX_PAER_L_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_PAER_L_SENS_ID { PARAM_VALUE.C_RX_PAER_L_SENS_ID } {
	# Procedure called to validate C_RX_PAER_L_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_PAER_R_SENS_ID { PARAM_VALUE.C_RX_PAER_R_SENS_ID PARAM_VALUE.C_RX_HAS_PAER } {
	# Procedure called to update C_RX_PAER_R_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_PAER_R_SENS_ID ${PARAM_VALUE.C_RX_PAER_R_SENS_ID}
	set C_RX_HAS_PAER ${PARAM_VALUE.C_RX_HAS_PAER}
	set values(C_RX_HAS_PAER) [get_property value $C_RX_HAS_PAER]
	if { [gen_USERPARAMETER_C_RX_PAER_R_SENS_ID_ENABLEMENT $values(C_RX_HAS_PAER)] } {
		set_property enabled true $C_RX_PAER_R_SENS_ID
	} else {
		set_property enabled false $C_RX_PAER_R_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_PAER_R_SENS_ID { PARAM_VALUE.C_RX_PAER_R_SENS_ID } {
	# Procedure called to validate C_RX_PAER_R_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_SAER0_A_SENS_ID { PARAM_VALUE.C_RX_SAER0_A_SENS_ID PARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_SAER0_A_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_SAER0_A_SENS_ID ${PARAM_VALUE.C_RX_SAER0_A_SENS_ID}
	set C_RX_HSSAER_N_CHAN ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}
	set C_RX_HAS_HSSAER ${PARAM_VALUE.C_RX_HAS_HSSAER}
	set values(C_RX_HSSAER_N_CHAN) [get_property value $C_RX_HSSAER_N_CHAN]
	set values(C_RX_HAS_HSSAER) [get_property value $C_RX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_RX_SAER0_A_SENS_ID_ENABLEMENT $values(C_RX_HSSAER_N_CHAN) $values(C_RX_HAS_HSSAER)] } {
		set_property enabled true $C_RX_SAER0_A_SENS_ID
	} else {
		set_property enabled false $C_RX_SAER0_A_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_SAER0_A_SENS_ID { PARAM_VALUE.C_RX_SAER0_A_SENS_ID } {
	# Procedure called to validate C_RX_SAER0_A_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_SAER0_L_SENS_ID { PARAM_VALUE.C_RX_SAER0_L_SENS_ID PARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_SAER0_L_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_SAER0_L_SENS_ID ${PARAM_VALUE.C_RX_SAER0_L_SENS_ID}
	set C_RX_HSSAER_N_CHAN ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}
	set C_RX_HAS_HSSAER ${PARAM_VALUE.C_RX_HAS_HSSAER}
	set values(C_RX_HSSAER_N_CHAN) [get_property value $C_RX_HSSAER_N_CHAN]
	set values(C_RX_HAS_HSSAER) [get_property value $C_RX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_RX_SAER0_L_SENS_ID_ENABLEMENT $values(C_RX_HSSAER_N_CHAN) $values(C_RX_HAS_HSSAER)] } {
		set_property enabled true $C_RX_SAER0_L_SENS_ID
	} else {
		set_property enabled false $C_RX_SAER0_L_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_SAER0_L_SENS_ID { PARAM_VALUE.C_RX_SAER0_L_SENS_ID } {
	# Procedure called to validate C_RX_SAER0_L_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_SAER0_R_SENS_ID { PARAM_VALUE.C_RX_SAER0_R_SENS_ID PARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_SAER0_R_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_SAER0_R_SENS_ID ${PARAM_VALUE.C_RX_SAER0_R_SENS_ID}
	set C_RX_HSSAER_N_CHAN ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}
	set C_RX_HAS_HSSAER ${PARAM_VALUE.C_RX_HAS_HSSAER}
	set values(C_RX_HSSAER_N_CHAN) [get_property value $C_RX_HSSAER_N_CHAN]
	set values(C_RX_HAS_HSSAER) [get_property value $C_RX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_RX_SAER0_R_SENS_ID_ENABLEMENT $values(C_RX_HSSAER_N_CHAN) $values(C_RX_HAS_HSSAER)] } {
		set_property enabled true $C_RX_SAER0_R_SENS_ID
	} else {
		set_property enabled false $C_RX_SAER0_R_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_SAER0_R_SENS_ID { PARAM_VALUE.C_RX_SAER0_R_SENS_ID } {
	# Procedure called to validate C_RX_SAER0_R_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_SAER1_A_SENS_ID { PARAM_VALUE.C_RX_SAER1_A_SENS_ID PARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_SAER1_A_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_SAER1_A_SENS_ID ${PARAM_VALUE.C_RX_SAER1_A_SENS_ID}
	set C_RX_HSSAER_N_CHAN ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}
	set C_RX_HAS_HSSAER ${PARAM_VALUE.C_RX_HAS_HSSAER}
	set values(C_RX_HSSAER_N_CHAN) [get_property value $C_RX_HSSAER_N_CHAN]
	set values(C_RX_HAS_HSSAER) [get_property value $C_RX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_RX_SAER1_A_SENS_ID_ENABLEMENT $values(C_RX_HSSAER_N_CHAN) $values(C_RX_HAS_HSSAER)] } {
		set_property enabled true $C_RX_SAER1_A_SENS_ID
	} else {
		set_property enabled false $C_RX_SAER1_A_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_SAER1_A_SENS_ID { PARAM_VALUE.C_RX_SAER1_A_SENS_ID } {
	# Procedure called to validate C_RX_SAER1_A_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_SAER1_L_SENS_ID { PARAM_VALUE.C_RX_SAER1_L_SENS_ID PARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_SAER1_L_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_SAER1_L_SENS_ID ${PARAM_VALUE.C_RX_SAER1_L_SENS_ID}
	set C_RX_HSSAER_N_CHAN ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}
	set C_RX_HAS_HSSAER ${PARAM_VALUE.C_RX_HAS_HSSAER}
	set values(C_RX_HSSAER_N_CHAN) [get_property value $C_RX_HSSAER_N_CHAN]
	set values(C_RX_HAS_HSSAER) [get_property value $C_RX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_RX_SAER1_L_SENS_ID_ENABLEMENT $values(C_RX_HSSAER_N_CHAN) $values(C_RX_HAS_HSSAER)] } {
		set_property enabled true $C_RX_SAER1_L_SENS_ID
	} else {
		set_property enabled false $C_RX_SAER1_L_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_SAER1_L_SENS_ID { PARAM_VALUE.C_RX_SAER1_L_SENS_ID } {
	# Procedure called to validate C_RX_SAER1_L_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_SAER1_R_SENS_ID { PARAM_VALUE.C_RX_SAER1_R_SENS_ID PARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_SAER1_R_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_SAER1_R_SENS_ID ${PARAM_VALUE.C_RX_SAER1_R_SENS_ID}
	set C_RX_HSSAER_N_CHAN ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}
	set C_RX_HAS_HSSAER ${PARAM_VALUE.C_RX_HAS_HSSAER}
	set values(C_RX_HSSAER_N_CHAN) [get_property value $C_RX_HSSAER_N_CHAN]
	set values(C_RX_HAS_HSSAER) [get_property value $C_RX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_RX_SAER1_R_SENS_ID_ENABLEMENT $values(C_RX_HSSAER_N_CHAN) $values(C_RX_HAS_HSSAER)] } {
		set_property enabled true $C_RX_SAER1_R_SENS_ID
	} else {
		set_property enabled false $C_RX_SAER1_R_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_SAER1_R_SENS_ID { PARAM_VALUE.C_RX_SAER1_R_SENS_ID } {
	# Procedure called to validate C_RX_SAER1_R_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_SAER2_A_SENS_ID { PARAM_VALUE.C_RX_SAER2_A_SENS_ID PARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_SAER2_A_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_SAER2_A_SENS_ID ${PARAM_VALUE.C_RX_SAER2_A_SENS_ID}
	set C_RX_HSSAER_N_CHAN ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}
	set C_RX_HAS_HSSAER ${PARAM_VALUE.C_RX_HAS_HSSAER}
	set values(C_RX_HSSAER_N_CHAN) [get_property value $C_RX_HSSAER_N_CHAN]
	set values(C_RX_HAS_HSSAER) [get_property value $C_RX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_RX_SAER2_A_SENS_ID_ENABLEMENT $values(C_RX_HSSAER_N_CHAN) $values(C_RX_HAS_HSSAER)] } {
		set_property enabled true $C_RX_SAER2_A_SENS_ID
	} else {
		set_property enabled false $C_RX_SAER2_A_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_SAER2_A_SENS_ID { PARAM_VALUE.C_RX_SAER2_A_SENS_ID } {
	# Procedure called to validate C_RX_SAER2_A_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_SAER2_L_SENS_ID { PARAM_VALUE.C_RX_SAER2_L_SENS_ID PARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_SAER2_L_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_SAER2_L_SENS_ID ${PARAM_VALUE.C_RX_SAER2_L_SENS_ID}
	set C_RX_HSSAER_N_CHAN ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}
	set C_RX_HAS_HSSAER ${PARAM_VALUE.C_RX_HAS_HSSAER}
	set values(C_RX_HSSAER_N_CHAN) [get_property value $C_RX_HSSAER_N_CHAN]
	set values(C_RX_HAS_HSSAER) [get_property value $C_RX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_RX_SAER2_L_SENS_ID_ENABLEMENT $values(C_RX_HSSAER_N_CHAN) $values(C_RX_HAS_HSSAER)] } {
		set_property enabled true $C_RX_SAER2_L_SENS_ID
	} else {
		set_property enabled false $C_RX_SAER2_L_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_SAER2_L_SENS_ID { PARAM_VALUE.C_RX_SAER2_L_SENS_ID } {
	# Procedure called to validate C_RX_SAER2_L_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_SAER2_R_SENS_ID { PARAM_VALUE.C_RX_SAER2_R_SENS_ID PARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_SAER2_R_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_SAER2_R_SENS_ID ${PARAM_VALUE.C_RX_SAER2_R_SENS_ID}
	set C_RX_HSSAER_N_CHAN ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}
	set C_RX_HAS_HSSAER ${PARAM_VALUE.C_RX_HAS_HSSAER}
	set values(C_RX_HSSAER_N_CHAN) [get_property value $C_RX_HSSAER_N_CHAN]
	set values(C_RX_HAS_HSSAER) [get_property value $C_RX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_RX_SAER2_R_SENS_ID_ENABLEMENT $values(C_RX_HSSAER_N_CHAN) $values(C_RX_HAS_HSSAER)] } {
		set_property enabled true $C_RX_SAER2_R_SENS_ID
	} else {
		set_property enabled false $C_RX_SAER2_R_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_SAER2_R_SENS_ID { PARAM_VALUE.C_RX_SAER2_R_SENS_ID } {
	# Procedure called to validate C_RX_SAER2_R_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_SAER3_A_SENS_ID { PARAM_VALUE.C_RX_SAER3_A_SENS_ID PARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_SAER3_A_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_SAER3_A_SENS_ID ${PARAM_VALUE.C_RX_SAER3_A_SENS_ID}
	set C_RX_HSSAER_N_CHAN ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}
	set C_RX_HAS_HSSAER ${PARAM_VALUE.C_RX_HAS_HSSAER}
	set values(C_RX_HSSAER_N_CHAN) [get_property value $C_RX_HSSAER_N_CHAN]
	set values(C_RX_HAS_HSSAER) [get_property value $C_RX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_RX_SAER3_A_SENS_ID_ENABLEMENT $values(C_RX_HSSAER_N_CHAN) $values(C_RX_HAS_HSSAER)] } {
		set_property enabled true $C_RX_SAER3_A_SENS_ID
	} else {
		set_property enabled false $C_RX_SAER3_A_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_SAER3_A_SENS_ID { PARAM_VALUE.C_RX_SAER3_A_SENS_ID } {
	# Procedure called to validate C_RX_SAER3_A_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_SAER3_L_SENS_ID { PARAM_VALUE.C_RX_SAER3_L_SENS_ID PARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_SAER3_L_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_SAER3_L_SENS_ID ${PARAM_VALUE.C_RX_SAER3_L_SENS_ID}
	set C_RX_HSSAER_N_CHAN ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}
	set C_RX_HAS_HSSAER ${PARAM_VALUE.C_RX_HAS_HSSAER}
	set values(C_RX_HSSAER_N_CHAN) [get_property value $C_RX_HSSAER_N_CHAN]
	set values(C_RX_HAS_HSSAER) [get_property value $C_RX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_RX_SAER3_L_SENS_ID_ENABLEMENT $values(C_RX_HSSAER_N_CHAN) $values(C_RX_HAS_HSSAER)] } {
		set_property enabled true $C_RX_SAER3_L_SENS_ID
	} else {
		set_property enabled false $C_RX_SAER3_L_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_SAER3_L_SENS_ID { PARAM_VALUE.C_RX_SAER3_L_SENS_ID } {
	# Procedure called to validate C_RX_SAER3_L_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_RX_SAER3_R_SENS_ID { PARAM_VALUE.C_RX_SAER3_R_SENS_ID PARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_SAER3_R_SENS_ID when any of the dependent parameters in the arguments change
	
	set C_RX_SAER3_R_SENS_ID ${PARAM_VALUE.C_RX_SAER3_R_SENS_ID}
	set C_RX_HSSAER_N_CHAN ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}
	set C_RX_HAS_HSSAER ${PARAM_VALUE.C_RX_HAS_HSSAER}
	set values(C_RX_HSSAER_N_CHAN) [get_property value $C_RX_HSSAER_N_CHAN]
	set values(C_RX_HAS_HSSAER) [get_property value $C_RX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_RX_SAER3_R_SENS_ID_ENABLEMENT $values(C_RX_HSSAER_N_CHAN) $values(C_RX_HAS_HSSAER)] } {
		set_property enabled true $C_RX_SAER3_R_SENS_ID
	} else {
		set_property enabled false $C_RX_SAER3_R_SENS_ID
	}
}

proc validate_PARAM_VALUE.C_RX_SAER3_R_SENS_ID { PARAM_VALUE.C_RX_SAER3_R_SENS_ID } {
	# Procedure called to validate C_RX_SAER3_R_SENS_ID
	return true
}

proc update_PARAM_VALUE.C_TX_HSSAER_N_CHAN { PARAM_VALUE.C_TX_HSSAER_N_CHAN PARAM_VALUE.C_TX_HAS_HSSAER } {
	# Procedure called to update C_TX_HSSAER_N_CHAN when any of the dependent parameters in the arguments change
	
	set C_TX_HSSAER_N_CHAN ${PARAM_VALUE.C_TX_HSSAER_N_CHAN}
	set C_TX_HAS_HSSAER ${PARAM_VALUE.C_TX_HAS_HSSAER}
	set values(C_TX_HAS_HSSAER) [get_property value $C_TX_HAS_HSSAER]
	if { [gen_USERPARAMETER_C_TX_HSSAER_N_CHAN_ENABLEMENT $values(C_TX_HAS_HSSAER)] } {
		set_property enabled true $C_TX_HSSAER_N_CHAN
	} else {
		set_property enabled false $C_TX_HSSAER_N_CHAN
	}
}

proc validate_PARAM_VALUE.C_TX_HSSAER_N_CHAN { PARAM_VALUE.C_TX_HSSAER_N_CHAN } {
	# Procedure called to validate C_TX_HSSAER_N_CHAN
	return true
}

proc update_PARAM_VALUE.C_DEBUG { PARAM_VALUE.C_DEBUG } {
	# Procedure called to update C_DEBUG when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_DEBUG { PARAM_VALUE.C_DEBUG } {
	# Procedure called to validate C_DEBUG
	return true
}

proc update_PARAM_VALUE.C_PSPNNLNK_WIDTH { PARAM_VALUE.C_PSPNNLNK_WIDTH } {
	# Procedure called to update C_PSPNNLNK_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_PSPNNLNK_WIDTH { PARAM_VALUE.C_PSPNNLNK_WIDTH } {
	# Procedure called to validate C_PSPNNLNK_WIDTH
	return true
}

proc update_PARAM_VALUE.C_RX_HAS_GTP { PARAM_VALUE.C_RX_HAS_GTP } {
	# Procedure called to update C_RX_HAS_GTP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_RX_HAS_GTP { PARAM_VALUE.C_RX_HAS_GTP } {
	# Procedure called to validate C_RX_HAS_GTP
	return true
}

proc update_PARAM_VALUE.C_RX_HAS_HSSAER { PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to update C_RX_HAS_HSSAER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_RX_HAS_HSSAER { PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to validate C_RX_HAS_HSSAER
	return true
}

proc update_PARAM_VALUE.C_RX_HAS_PAER { PARAM_VALUE.C_RX_HAS_PAER } {
	# Procedure called to update C_RX_HAS_PAER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_RX_HAS_PAER { PARAM_VALUE.C_RX_HAS_PAER } {
	# Procedure called to validate C_RX_HAS_PAER
	return true
}

proc update_PARAM_VALUE.C_RX_HAS_SPNNLNK { PARAM_VALUE.C_RX_HAS_SPNNLNK } {
	# Procedure called to update C_RX_HAS_SPNNLNK when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_RX_HAS_SPNNLNK { PARAM_VALUE.C_RX_HAS_SPNNLNK } {
	# Procedure called to validate C_RX_HAS_SPNNLNK
	return true
}

proc update_PARAM_VALUE.C_SLV_DWIDTH { PARAM_VALUE.C_SLV_DWIDTH } {
	# Procedure called to update C_SLV_DWIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_SLV_DWIDTH { PARAM_VALUE.C_SLV_DWIDTH } {
	# Procedure called to validate C_SLV_DWIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_TX_HAS_GTP { PARAM_VALUE.C_TX_HAS_GTP } {
	# Procedure called to update C_TX_HAS_GTP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_TX_HAS_GTP { PARAM_VALUE.C_TX_HAS_GTP } {
	# Procedure called to validate C_TX_HAS_GTP
	return true
}

proc update_PARAM_VALUE.C_TX_HAS_HSSAER { PARAM_VALUE.C_TX_HAS_HSSAER } {
	# Procedure called to update C_TX_HAS_HSSAER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_TX_HAS_HSSAER { PARAM_VALUE.C_TX_HAS_HSSAER } {
	# Procedure called to validate C_TX_HAS_HSSAER
	return true
}

proc update_PARAM_VALUE.C_TX_HAS_PAER { PARAM_VALUE.C_TX_HAS_PAER } {
	# Procedure called to update C_TX_HAS_PAER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_TX_HAS_PAER { PARAM_VALUE.C_TX_HAS_PAER } {
	# Procedure called to validate C_TX_HAS_PAER
	return true
}

proc update_PARAM_VALUE.C_TX_HAS_SPNNLNK { PARAM_VALUE.C_TX_HAS_SPNNLNK } {
	# Procedure called to update C_TX_HAS_SPNNLNK when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_TX_HAS_SPNNLNK { PARAM_VALUE.C_TX_HAS_SPNNLNK } {
	# Procedure called to validate C_TX_HAS_SPNNLNK
	return true
}


proc update_MODELPARAM_VALUE.C_PAER_DSIZE { MODELPARAM_VALUE.C_PAER_DSIZE PARAM_VALUE.C_PAER_DSIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_PAER_DSIZE}] ${MODELPARAM_VALUE.C_PAER_DSIZE}
}

proc update_MODELPARAM_VALUE.C_RX_HAS_PAER { MODELPARAM_VALUE.C_RX_HAS_PAER PARAM_VALUE.C_RX_HAS_PAER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_HAS_PAER}] ${MODELPARAM_VALUE.C_RX_HAS_PAER}
}

proc update_MODELPARAM_VALUE.C_RX_HAS_HSSAER { MODELPARAM_VALUE.C_RX_HAS_HSSAER PARAM_VALUE.C_RX_HAS_HSSAER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_HAS_HSSAER}] ${MODELPARAM_VALUE.C_RX_HAS_HSSAER}
}

proc update_MODELPARAM_VALUE.C_RX_HSSAER_N_CHAN { MODELPARAM_VALUE.C_RX_HSSAER_N_CHAN PARAM_VALUE.C_RX_HSSAER_N_CHAN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_HSSAER_N_CHAN}] ${MODELPARAM_VALUE.C_RX_HSSAER_N_CHAN}
}

proc update_MODELPARAM_VALUE.C_RX_HAS_GTP { MODELPARAM_VALUE.C_RX_HAS_GTP PARAM_VALUE.C_RX_HAS_GTP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_HAS_GTP}] ${MODELPARAM_VALUE.C_RX_HAS_GTP}
}

proc update_MODELPARAM_VALUE.C_RX_HAS_SPNNLNK { MODELPARAM_VALUE.C_RX_HAS_SPNNLNK PARAM_VALUE.C_RX_HAS_SPNNLNK } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_HAS_SPNNLNK}] ${MODELPARAM_VALUE.C_RX_HAS_SPNNLNK}
}

proc update_MODELPARAM_VALUE.C_TX_HAS_PAER { MODELPARAM_VALUE.C_TX_HAS_PAER PARAM_VALUE.C_TX_HAS_PAER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_TX_HAS_PAER}] ${MODELPARAM_VALUE.C_TX_HAS_PAER}
}

proc update_MODELPARAM_VALUE.C_TX_HAS_HSSAER { MODELPARAM_VALUE.C_TX_HAS_HSSAER PARAM_VALUE.C_TX_HAS_HSSAER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_TX_HAS_HSSAER}] ${MODELPARAM_VALUE.C_TX_HAS_HSSAER}
}

proc update_MODELPARAM_VALUE.C_TX_HSSAER_N_CHAN { MODELPARAM_VALUE.C_TX_HSSAER_N_CHAN PARAM_VALUE.C_TX_HSSAER_N_CHAN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_TX_HSSAER_N_CHAN}] ${MODELPARAM_VALUE.C_TX_HSSAER_N_CHAN}
}

proc update_MODELPARAM_VALUE.C_TX_HAS_GTP { MODELPARAM_VALUE.C_TX_HAS_GTP PARAM_VALUE.C_TX_HAS_GTP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_TX_HAS_GTP}] ${MODELPARAM_VALUE.C_TX_HAS_GTP}
}

proc update_MODELPARAM_VALUE.C_TX_HAS_SPNNLNK { MODELPARAM_VALUE.C_TX_HAS_SPNNLNK PARAM_VALUE.C_TX_HAS_SPNNLNK } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_TX_HAS_SPNNLNK}] ${MODELPARAM_VALUE.C_TX_HAS_SPNNLNK}
}

proc update_MODELPARAM_VALUE.C_PSPNNLNK_WIDTH { MODELPARAM_VALUE.C_PSPNNLNK_WIDTH PARAM_VALUE.C_PSPNNLNK_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_PSPNNLNK_WIDTH}] ${MODELPARAM_VALUE.C_PSPNNLNK_WIDTH}
}

proc update_MODELPARAM_VALUE.C_DEBUG { MODELPARAM_VALUE.C_DEBUG PARAM_VALUE.C_DEBUG } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_DEBUG}] ${MODELPARAM_VALUE.C_DEBUG}
}

proc update_MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_SLV_DWIDTH { MODELPARAM_VALUE.C_SLV_DWIDTH PARAM_VALUE.C_SLV_DWIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_SLV_DWIDTH}] ${MODELPARAM_VALUE.C_SLV_DWIDTH}
}

proc update_MODELPARAM_VALUE.C_RX_PAER_L_SENS_ID { MODELPARAM_VALUE.C_RX_PAER_L_SENS_ID PARAM_VALUE.C_RX_PAER_L_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_PAER_L_SENS_ID}] ${MODELPARAM_VALUE.C_RX_PAER_L_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_SAER0_L_SENS_ID { MODELPARAM_VALUE.C_RX_SAER0_L_SENS_ID PARAM_VALUE.C_RX_SAER0_L_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_SAER0_L_SENS_ID}] ${MODELPARAM_VALUE.C_RX_SAER0_L_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_SAER1_L_SENS_ID { MODELPARAM_VALUE.C_RX_SAER1_L_SENS_ID PARAM_VALUE.C_RX_SAER1_L_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_SAER1_L_SENS_ID}] ${MODELPARAM_VALUE.C_RX_SAER1_L_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_SAER2_L_SENS_ID { MODELPARAM_VALUE.C_RX_SAER2_L_SENS_ID PARAM_VALUE.C_RX_SAER2_L_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_SAER2_L_SENS_ID}] ${MODELPARAM_VALUE.C_RX_SAER2_L_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_SAER3_L_SENS_ID { MODELPARAM_VALUE.C_RX_SAER3_L_SENS_ID PARAM_VALUE.C_RX_SAER3_L_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_SAER3_L_SENS_ID}] ${MODELPARAM_VALUE.C_RX_SAER3_L_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_PAER_R_SENS_ID { MODELPARAM_VALUE.C_RX_PAER_R_SENS_ID PARAM_VALUE.C_RX_PAER_R_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_PAER_R_SENS_ID}] ${MODELPARAM_VALUE.C_RX_PAER_R_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_SAER0_R_SENS_ID { MODELPARAM_VALUE.C_RX_SAER0_R_SENS_ID PARAM_VALUE.C_RX_SAER0_R_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_SAER0_R_SENS_ID}] ${MODELPARAM_VALUE.C_RX_SAER0_R_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_SAER1_R_SENS_ID { MODELPARAM_VALUE.C_RX_SAER1_R_SENS_ID PARAM_VALUE.C_RX_SAER1_R_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_SAER1_R_SENS_ID}] ${MODELPARAM_VALUE.C_RX_SAER1_R_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_SAER2_R_SENS_ID { MODELPARAM_VALUE.C_RX_SAER2_R_SENS_ID PARAM_VALUE.C_RX_SAER2_R_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_SAER2_R_SENS_ID}] ${MODELPARAM_VALUE.C_RX_SAER2_R_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_SAER3_R_SENS_ID { MODELPARAM_VALUE.C_RX_SAER3_R_SENS_ID PARAM_VALUE.C_RX_SAER3_R_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_SAER3_R_SENS_ID}] ${MODELPARAM_VALUE.C_RX_SAER3_R_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_PAER_A_SENS_ID { MODELPARAM_VALUE.C_RX_PAER_A_SENS_ID PARAM_VALUE.C_RX_PAER_A_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_PAER_A_SENS_ID}] ${MODELPARAM_VALUE.C_RX_PAER_A_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_SAER0_A_SENS_ID { MODELPARAM_VALUE.C_RX_SAER0_A_SENS_ID PARAM_VALUE.C_RX_SAER0_A_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_SAER0_A_SENS_ID}] ${MODELPARAM_VALUE.C_RX_SAER0_A_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_SAER1_A_SENS_ID { MODELPARAM_VALUE.C_RX_SAER1_A_SENS_ID PARAM_VALUE.C_RX_SAER1_A_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_SAER1_A_SENS_ID}] ${MODELPARAM_VALUE.C_RX_SAER1_A_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_SAER2_A_SENS_ID { MODELPARAM_VALUE.C_RX_SAER2_A_SENS_ID PARAM_VALUE.C_RX_SAER2_A_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_SAER2_A_SENS_ID}] ${MODELPARAM_VALUE.C_RX_SAER2_A_SENS_ID}
}

proc update_MODELPARAM_VALUE.C_RX_SAER3_A_SENS_ID { MODELPARAM_VALUE.C_RX_SAER3_A_SENS_ID PARAM_VALUE.C_RX_SAER3_A_SENS_ID } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RX_SAER3_A_SENS_ID}] ${MODELPARAM_VALUE.C_RX_SAER3_A_SENS_ID}
}

