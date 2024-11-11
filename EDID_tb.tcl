if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vlib states

vmap work rtl_work
vmap states rtl_work

vcom -2008 -work states [pwd]/states.vhd
vcom -2008 -work states [pwd]/data.vhd
vcom -2008 -work work [pwd]/conv.vhd
vcom -2008 -work work [pwd]/EDIDI2C.vhd
vcom -2008 -work work [pwd]/EDID.vhd
vcom -2008 -work work [pwd]/EDID_tb.vhd

vsim edid_tb

add wave -recursive *

view structure
view signals

run 10 us

view -undock wave
wave zoomfull
