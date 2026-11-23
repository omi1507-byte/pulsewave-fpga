# ==============================================================================
# Synopsys Design Constraints (SDC) for PulseWave-FPGA
# ==============================================================================

# Master Clocks
create_clock -name clk_25m -period 40.000 [get_ports clk_25m]
create_clock -name ft_clk60 -period 16.666 [get_ports ft_clk60]

# Generated Sampling Clocks from PLL
create_generated_clock -name clk_sample -source [get_ports clk_25m] -multiply_by 8 [get_pins pll_inst/CLKOP]

# Asynchronous Clock Domain Crossings (CDC)
set_clock_groups -asynchronous \
    -group [get_clocks clk_sample] \
    -group [get_clocks ft_clk60] \
    -group [get_clocks clk_25m]

# High-Speed Input Delay on Probe Inputs
set_input_delay -clock clk_sample -max 2.000 [get_ports {probe_pins[*]}]
set_input_delay -clock clk_sample -min 0.500 [get_ports {probe_pins[*]}]

# FT232H Synchronous FIFO I/O Delays
set_output_delay -clock ft_clk60 -max 7.500 [get_ports {ft_wr_n ft_data[*]}]
set_output_delay -clock ft_clk60 -min 1.000 [get_ports {ft_wr_n ft_data[*]}]
set_input_delay  -clock ft_clk60 -max 7.000 [get_ports {ft_txe_n ft_rxf_n}]
set_input_delay  -clock ft_clk60 -min 1.000 [get_ports {ft_txe_n ft_rxf_n}]
