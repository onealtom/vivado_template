#source apply_ps.tcl


set compile_order "sources_1"

set output_hdf "output.hdf"

# 默认配置文件名


set origin_dir "."

set configs_dir ${origin_dir}/configs

puts "argc="
puts ${argc}
set i 0
while {$i < $argc} {
	puts $i
#lindex 命令用于取出list中指定索引的参数
		set arg [lindex $argv $i]
		puts i
		#puts "$arg"
		set prj_defconfig_file ${arg}_defconfig.tcl
#incr 命令用于对变量进行加操作
		incr i 1
}
puts "out"

set soc_name "none"
set prj_name "none" 
set value1 "none"
set value2 "none"
set bd_name "none"

#如果没有传参数进来，查找项目根目录下是否有.config文件，有则source该配置
#如果没有.config出错返回
#如果有传参数进来，检查configs目录下是否有与传入配置名称相同的文件
#如果有则source该配置，没有出错返回

if {$argc == 0} {
	puts "no arg, use try .config"
	if { [file exists .config ] } { 
		source .config
	} else {
		return -code error "Can not found .config, Please make PRJ_CONFIG=xxx first. "
	}

} else {
	puts " arg, try use configs/xxx_defconfig "

	if { [file exists ${configs_dir}/${prj_defconfig_file} ] } { 
		file copy ${configs_dir}/${prj_defconfig_file} ${origin_dir}/.config
		source ${origin_dir}/.config
	} else {
		return -code error "Can not found configs/${prj_defconfig_file}"
	}



}

#source后检查参数完整性

if { ${soc_name} == "none"} {
	return -code error "ERROR: PROJECT CONFIG missing soc_name"
}

# 打印 配置参数

puts ${soc_name}
puts ${prj_name}
puts ${bd_name}

puts ${value1}
puts ${value2}




set output_dir ${origin_dir}/output
set build_dir ${origin_dir}/build
set bd_dir ${build_dir}/${prj_name}.srcs/${compile_order}/bd/${bd_name}
set hdl_dir ${bd_dir}/hdl
set sdk_dir ${build_dir}/${prj_name}.sdk
set ps7_dir ${bd_dir}/ip/${bd_name}_processing_system7_0_0




故意错误停止分割线-------------------------------------------------------------

# Create Vivado Project
create_project -force $prj_name $build_dir -part ${soc_name}
#create_project -force $prj_name $build_dir
# Create Block Design
create_bd_design $bd_name


# Add ZYNQ7 IP
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

# Apply ZYNQ7 IP from config file
source ${configs_dir}/${ps7_config_file}
set presets [apply_preset 0]

foreach {k v} $presets {
	if {![info exists preset_list]} {
		set preset_list [dict create $k $v]
	} else {
		dict set preset_list $k $v
	}
}
set_property -dict $preset_list [get_bd_cells processing_system7_0]

# Run Block Automation
#apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

# Manual Connect 
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 ddr
create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 fixed_io
connect_bd_intf_net [get_bd_intf_ports ddr] [get_bd_intf_pins processing_system7_0/DDR]
connect_bd_intf_net [get_bd_intf_ports fixed_io] [get_bd_intf_pins processing_system7_0/FIXED_IO]

# Connect FCLK_CLK0
#connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
#connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK]

#connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP1_ACLK]
#connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/S_AXI_HP1_ACLK]

connect_bd_net -quiet [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP*_ACLK]
connect_bd_net -quiet [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/S_AXI_HP*_ACLK]



# Create wrapper
#make_wrapper -files [get_files ${bd_dir}/${bd_name}.bd] -top
#add_files -norecurse ${hdl_dir}/${bd_name}_wrapper.v
#update_compile_order -fileset ${compile_order}

# Generate output product
generate_target all [get_files ${bd_dir}/${bd_name}.bd]

##
regenerate_bd_layout
save_bd_design
validate_bd_design
##

if { [file exists ${output_dir} ] } {	file delete -force ${output_dir}/ }
file mkdir ${output_dir}

file copy ${ps7_dir}/ps7_init.c ${output_dir}/
file copy ${ps7_dir}/ps7_init.h ${output_dir}/
file copy ${ps7_dir}/ps7_parameters.xml ${output_dir}/



#if { [file exists ${sdk_dir} ] } { file delete ${sdk_dir} }
#file mkdir ${sdk_dir}
#write_hwdef -force  -file ${sdk_dir}/output.hdf
#file copy ${sdk_dir}/output.hdf ${output_dir}/output.hdf
