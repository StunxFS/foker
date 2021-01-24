// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module binary

const vars = '
# Comentario bonito :)
80AB # Comentario al lado de una variable
801B'

fn test_get() {
	mut fvf := new_fvf(binary.vars)
	v1 := fvf.get() or { panic(err) }
	v2 := fvf.get() or { panic(err) }
	assert v1 == '80AB'
	assert v2 == '801B'
}

fn test_free() {
	mut fvf := new_fvf(binary.vars)
	v1 := fvf.get() or { panic(err) }
	v2 := fvf.get() or { panic(err) }
	assert v1 == '80AB'
	assert v2 == '801B'
	fvf.free(v1)
	fvf.free(v2)
}
