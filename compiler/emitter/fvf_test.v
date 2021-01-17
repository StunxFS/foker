// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module emitter

fn test_fvf() {
	mut fvf := new_fvf('
80AB
801B
')
	_ := fvf.get() or {panic(err)}
	_ := fvf.get() or {panic(err)}
}
