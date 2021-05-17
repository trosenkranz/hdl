# ltc2387

create_bd_port -dir I ref_clk
create_bd_port -dir O sampling_clk
create_bd_port -dir I dco_p
create_bd_port -dir I dco_n
create_bd_port -dir O cnv
create_bd_port -dir I da_p
create_bd_port -dir I da_n
create_bd_port -dir I db_p
create_bd_port -dir I db_n
create_bd_port -dir O clk_gate

if {$adc_resolution == 16} {
  set data_width 16
  if {$two_lanes == 0} {
    set gate_width 9
  } else {
    set gate_width 4
  }} elseif {$adc_resolution == 18} {
  set data_width 32
  if {$two_lanes == 0} {
    set gate_width 8
  } else {
    set gate_width 5
  }
};

# adc peripheral

ad_ip_instance util_ltc2387 util_ltc2387
ad_ip_parameter util_ltc2387 CONFIG.RESOLUTION $adc_resolution
ad_ip_parameter util_ltc2387 CONFIG.TWOLANES $two_lanes

# axi pwm gen

ad_ip_instance axi_pwm_gen axi_pwm_gen
ad_ip_parameter axi_pwm_gen CONFIG.N_PWMS 2
ad_ip_parameter axi_pwm_gen CONFIG.PULSE_0_WIDTH 1
ad_ip_parameter axi_pwm_gen CONFIG.PULSE_0_PERIOD 13
ad_ip_parameter axi_pwm_gen CONFIG.PULSE_1_WIDTH $gate_width
ad_ip_parameter axi_pwm_gen CONFIG.PULSE_1_PERIOD 13
ad_ip_parameter axi_pwm_gen CONFIG.PULSE_1_OFFSET 0

# dma

ad_ip_instance axi_dmac ltc2387_dma
ad_ip_parameter ltc2387_dma CONFIG.DMA_TYPE_SRC 2
ad_ip_parameter ltc2387_dma CONFIG.DMA_TYPE_DEST 0
ad_ip_parameter ltc2387_dma CONFIG.CYCLIC 0
ad_ip_parameter ltc2387_dma CONFIG.SYNC_TRANSFER_START 0
ad_ip_parameter ltc2387_dma CONFIG.AXI_SLICE_SRC 0
ad_ip_parameter ltc2387_dma CONFIG.AXI_SLICE_DEST 1
ad_ip_parameter ltc2387_dma CONFIG.DMA_2D_TRANSFER 0
ad_ip_parameter ltc2387_dma CONFIG.DMA_DATA_WIDTH_SRC $data_width
ad_ip_parameter ltc2387_dma CONFIG.DMA_DATA_WIDTH_DEST 64
ad_ip_parameter ltc2387_dma CONFIG.ASYNC_CLK_REQ_SRC.VALUE_SRC  USER
ad_ip_parameter ltc2387_dma CONFIG.ASYNC_CLK_SRC_DEST.VALUE_SRC  USER
ad_ip_parameter ltc2387_dma CONFIG.ASYNC_CLK_DEST_REQ.VALUE_SRC  USER
ad_ip_parameter ltc2387_dma CONFIG.ASYNC_CLK_DEST_REQ  true
ad_ip_parameter ltc2387_dma CONFIG.AXI_SLICE_SRC  true

ad_ip_instance axi_clkgen axi_clkgen
ad_ip_parameter axi_clkgen CONFIG.ID 1
ad_ip_parameter axi_clkgen CONFIG.CLKIN_PERIOD 10
ad_ip_parameter axi_clkgen CONFIG.VCO_DIV 1
ad_ip_parameter axi_clkgen CONFIG.VCO_MUL 2
ad_ip_parameter axi_clkgen CONFIG.CLK0_DIV 4
ad_ip_parameter axi_clkgen CONFIG.ENABLE_CLKOUT1 true
ad_ip_parameter axi_clkgen CONFIG.CLK1_DIV 1


# connections

ad_connect ref_clk                 axi_clkgen/clk
ad_connect axi_clkgen/clk_0        sampling_clk

ad_connect axi_clkgen/clk_0        util_ltc2387/ref_clk
ad_connect clk_gate                util_ltc2387/clk_gate
ad_connect dco_p                   util_ltc2387/dco_p
ad_connect dco_n                   util_ltc2387/dco_n
ad_connect da_n                    util_ltc2387/da_n
ad_connect da_p                    util_ltc2387/da_p
ad_connect db_n                    util_ltc2387/db_n
ad_connect db_p                    util_ltc2387/db_p

ad_connect clk_gate                axi_pwm_gen/pwm_1
ad_connect cnv                     axi_pwm_gen/pwm_0

ad_connect axi_clkgen/clk_0        axi_pwm_gen/ext_clk
ad_connect sys_cpu_resetn          axi_pwm_gen/s_axi_aresetn
ad_connect sys_cpu_clk             axi_pwm_gen/s_axi_aclk
ad_connect axi_clkgen/clk_0        ltc2387_dma/fifo_wr_clk

ad_connect util_ltc2387/adc_valid  ltc2387_dma/fifo_wr_en
ad_connect util_ltc2387/adc_data   ltc2387_dma/fifo_wr_din

# address mapping

ad_cpu_interconnect 0x44A30000 ltc2387_dma
ad_cpu_interconnect 0x44A60000 axi_pwm_gen
ad_cpu_interconnect 0x44A70000 axi_clkgen

# interconnect (adc)

ad_mem_hp2_interconnect $sys_cpu_clk sys_ps7/S_AXI_HP2
ad_mem_hp2_interconnect $sys_cpu_clk ltc2387_dma/m_dest_axi
ad_connect  $sys_cpu_resetn ltc2387_dma/m_dest_axi_aresetn

# interrupts

ad_cpu_interrupt ps-13 mb-13 ltc2387_dma/irq
