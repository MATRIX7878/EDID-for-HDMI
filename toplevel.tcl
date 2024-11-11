if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vlib states

vmap work rtl_work
vmap states rtl_work

vcom -work states [pwd]/states.vhd
vcom -work work [pwd]/toplevel.vhd
vcom -work work [pwd]/conv.vhd
vcom -work work [pwd]/EDID.vhd
vcom -work work [pwd]/I2C.vhd
vcom -work work [pwd]/UART.vhd
vcom -work work [pwd]/i2c_mem_sim.vhd
vcom -work work [pwd]/uart_sim.vhd
vcom -work work [pwd]/toplevel_tb.vhd

vsim toplevel_tb

add wave -recursive *

view structure
view signals

transcript file transcript.log
transcript on

run 5000 us

view -undock wave
wave zoomfull
