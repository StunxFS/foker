import os
import compiler.gen.binary as bin

fn test_simple_gen() {
	mut script := bin.new_fscript('main')
	script.add_string('StunxFS', 'Me llaman kalawus')
	mut block := bin.new_fblock('main')
	block.add_cmd('msgbox', ['@StunxFS', '0x6'])
	block.add_label(script.new_label())
	block.add_cmd('msgbox', ['@' + script.add_tmp_string('Corriendo!'), '0x6'])
	block.add_end()
	script.add_block(block)
	block = bin.new_fblock('movement_player')
	block.add_cmd('#raw', ['0x6'])
	script.add_movement('movement_player', block)
	os.write_file('${script.name}.rbh', script.generate_script()) or { println(err) }
}
