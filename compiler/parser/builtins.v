// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module parser

import os
import compiler.prefs

const (
	exepath       = os.dir(os.real_path(prefs.zsexe_path()))
	builtins_file = os.join_path(exepath, 'compiler', 'builtins.zs')
)
