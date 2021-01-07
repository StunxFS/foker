// Copyright (c) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.

import gen.binary

struct TestFormatText {
pub:
	max_width int
	input_text string
	expected string
}

fn test_format_text() {
	tests := [
		TestFormatText{40, "", ""}, 
		TestFormatText{40, "Hello", "Hello"},
		TestFormatText{100, "Foo bar", "Foo bar"},
		TestFormatText{140, "Foo {MUS} baz", "Foo {MUS}\\n\nbaz"},
		TestFormatText{139, "Foo {MUS} baz", "Foo\\n\n{MUS}\\l\nbaz"},
		TestFormatText{40, "ßŒœ ♂Üあ   ", "ßŒœ\\n\n♂Üあ"},
		TestFormatText{40, "   Foo    bar          baz  baz2", "Foo\\n\nbar\\l\nbaz\\l\nbaz2"},
		TestFormatText{100, 'Hello.\pI am writing a test.', "Hello.\\p\nI am\\n\nwriting a\\l\ntest."},
		TestFormatText{100, 'Hello.\nI am writing a longer \l“test.”', "Hello.\\n\nI am\\l\nwriting a\\l\nlonger\\l\n“test.”"}
	]

	fw := binary.FontsWidthsConfig{}

	for _, tt in tests {
		result := fw.format_text(tt.input_text, tt.max_width, binary.test_fontid) or {
			panic(err)
		}
		assert result == tt.expected
	}
}
