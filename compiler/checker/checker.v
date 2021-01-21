// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module checker

// import os
// import strings
// import compiler.util
// import compiler.token
import compiler.ast
import compiler.prefs
import compiler.errors

const (
	max_nr_errors                 = 300
	match_exhaustive_cutoff_limit = 10
	int_min                       = int(0x80000000)
	int_max                       = 0x7FFFFFFF
)

pub struct Checker {
	pref &prefs.Preferences
pub mut:
	table         &ast.Table
	file          &ast.File = 0
	nr_errors     int
	nr_warnings   int
	errors        []errors.Report
	warnings      []errors.Report
	error_lines   []int // para evitar imprimir multiple errores para la misma linea :)
	expected_type ast.Type
	cur_script    &ast.ScriptDecl
	const_decl    string
	const_names   []string
	in_for_count  int // si checker está actualmente en un bucle for
mut:
	expr_level     int // para evitar una recursion infinita que implique bugs del compilador
	errors_details []string
	loop_label     string // obtiene valor cuando se está dentro de un bucle for etiquetado
}

pub fn new_checker(table &ast.Table, pref &prefs.Preferences) Checker {
	return Checker{
		table: table
		pref: pref
		cur_script: 0
	}
}

pub fn (mut c Checker) check(ast_file &ast.File) {
	c.file = ast_file
	for stmt in ast_file.prog.stmts {
		c.expr_level = 0
		c.stmt(stmt)
	}
	c.check_scope_vars(c.file.prog.scope)
}

pub fn (mut c Checker) check_scope_vars(sc &ast.Scope) {
	for _, obj in sc.objects {
		match obj {
			ast.Var {
				if !obj.is_used && obj.name[0] != `_` {
					c.warn("variable '$obj.name' no usada", obj.pos)
				}
			}
			else {}
		}
	}
	for _, child in sc.children {
		c.check_scope_vars(child)
	}
}

/*
[inline]
fn (mut c Checker) check_loop_label(label string, pos token.Position) {
	if label.len == 0 {
		return
	}
	if c.loop_label.len != 0 {
		c.error("nesting of labelled 'for' loops is not supported", pos)
		return
	}
	c.loop_label = label
}
*/
fn (mut c Checker) stmt(node ast.Stmt) {
	match mut node {
		ast.AssignStmt {
			c.assign_stmt(mut node)
		}
		ast.ScriptDecl {
			for stmt in node.stmts {
				c.stmt(stmt)
			}
		}
		ast.Block {
			for stmt in node.stmts {
				c.stmt(stmt)
			}
		}
		ast.ExprStmt {
			node.typ = c.expr(node.expr)
			c.expected_type = .unknown
		}
		ast.CallStmt { // call my_script;
			if !c.table.exists_script(node.script) {
				c.error('no existe un script con este nombre', node.pos)
			}
		}
		ast.IfStmt {
			for branch in node.branches {
				typ := c.expr(branch.cond)
				println(typ)
				if !branch.is_else && typ != .bool {
					c.error('se espera una expresión condicional', branch.cond.position())
				}
			}
		}
		else {} // TODO: implementar el resto de las declaraciones
	}
}

/*
pub fn (mut c Checker) assign_stmt(mut assign_stmt ast.AssignStmt) {
	c.expected_type = table.none_type // TODO a hack to make `x := if ... work`
	defer {
		c.expected_type = table.void_type
	}
	right_first := assign_stmt.right[0]
	mut right_len := assign_stmt.right.len
	mut right_type0 := table.void_type
	if right_first is ast.CallExpr || right_first is ast.IfExpr || right_first is ast.MatchExpr {
		right_type0 = c.expr(right_first)
		assign_stmt.right_types = [
			c.check_expr_opt_call(right_first, right_type0),
		]
		right_type_sym0 := c.table.get_type_symbol(right_type0)
		if right_type_sym0.kind == .multi_return {
			assign_stmt.right_types = right_type_sym0.mr_info().types
			right_len = assign_stmt.right_types.len
		} else if right_type0 == table.void_type {
			right_len = 0
		}
	}
	if assign_stmt.left.len != right_len {
		if right_first is ast.CallExpr {
			c.error('assignment mismatch: $assign_stmt.left.len variable(s) but `${right_first.name}()` returns $right_len value(s)',
				assign_stmt.pos)
		} else {
			c.error('assignment mismatch: $assign_stmt.left.len variable(s) $right_len value(s)',
				assign_stmt.pos)
		}
		return
	}
	//
	is_decl := assign_stmt.op == .decl_assign
	for i, left in assign_stmt.left {
		if left is ast.CallExpr {
			c.error('cannot call function `${left.name}()` on the left side of an assignment',
				left.pos)
		}
		is_blank_ident := left.is_blank_ident()
		mut left_type := table.void_type
		if !is_decl && !is_blank_ident {
			if left is ast.Ident || left is ast.SelectorExpr {
				c.prevent_sum_type_unwrapping_once = true
			}
			left_type = c.expr(left)
			c.expected_type = c.unwrap_generic(left_type)
		}
		if assign_stmt.right_types.len < assign_stmt.left.len { // first type or multi return types added above
			right_type := c.expr(assign_stmt.right[i])
			if assign_stmt.right_types.len == i {
				assign_stmt.right_types << c.check_expr_opt_call(assign_stmt.right[i], right_type)
			}
		}
		right := if i < assign_stmt.right.len { assign_stmt.right[i] } else { assign_stmt.right[0] }
		mut right_type := assign_stmt.right_types[i]
		if is_decl {
			left_type = c.table.mktyp(right_type)
			if left_type == table.int_type {
				mut expr := right
				mut negative := false
				if right is ast.PrefixExpr {
					expr = right.right
					if right.op == .minus {
						negative = true
					}
				}
				if mut expr is ast.IntegerLiteral {
					mut is_large := false
					if expr.val.len > 8 {
						val := expr.val.i64()
						if (!negative && val > int_max) || (negative && -val < int_min) {
							is_large = true
						}
					}
					if is_large {
						c.error('overflow in implicit type `int`, use explicit type casting instead',
							expr.pos)
					}
				}
			}
			// we are unwrapping here instead if check_expr_opt_call currently
			if left_type.has_flag(.optional) {
				left_type = left_type.clear_flag(.optional)
			}
		} else {
			// Make sure the variable is mutable
			c.fail_if_immutable(left)
			// left_type = c.expr(left)
		}
		assign_stmt.left_types << left_type
		match mut left {
			ast.Ident {
				if left.kind == .blank_ident {
					left_type = right_type
					assign_stmt.left_types[i] = right_type
					if assign_stmt.op !in [.assign, .decl_assign] {
						c.error('cannot modify blank `_` identifier', left.pos)
					}
				} else if left.info !is ast.IdentVar {
					c.error('cannot assign to $left.kind `$left.name`', left.pos)
				} else {
					if is_decl {
						c.check_valid_snake_case(left.name, 'variable name', left.pos)
					}
					mut ident_var_info := left.info as ast.IdentVar
					if ident_var_info.share == .shared_t {
						left_type = left_type.set_flag(.shared_f)
					}
					if ident_var_info.share == .atomic_t {
						left_type = left_type.set_flag(.atomic_f)
					}
					assign_stmt.left_types[i] = left_type
					ident_var_info.typ = left_type
					left.info = ident_var_info
					if left_type != 0 {
						match mut left.obj {
							ast.Var { left.obj.typ = left_type }
							ast.GlobalField { left.obj.typ = left_type }
							else {}
						}
						/*
						if left.obj is ast.Var as v {
							v.typ = left_type
						} else if left.obj is ast.GlobalDecl as v {
							v.typ = left_type
						}
						*/
					}
					if is_decl {
						full_name := '${left.mod}.$left.name'
						if full_name in c.const_names {
							c.error('duplicate of a const name `$left.name`', left.pos)
						}
					}
				}
			}
			ast.PrefixExpr {
				// Do now allow `*x = y` outside `unsafe`
				if left.op == .mul && !c.inside_unsafe {
					c.error('modifying variables via dereferencing can only be done in `unsafe` blocks',
						assign_stmt.pos)
				}
				if is_decl {
					c.error('non-name on the left side of `:=`', left.pos)
				}
			}
			else {
				if is_decl {
					c.error('non-name `$left` on left side of `:=`', left.position())
				}
			}
		}
		left_type_unwrapped := c.unwrap_generic(left_type)
		right_type_unwrapped := c.unwrap_generic(right_type)
		if right_type_unwrapped == 0 {
			// right type was a generic `T`
			continue
		}
		left_sym := c.table.get_type_symbol(left_type_unwrapped)
		right_sym := c.table.get_type_symbol(right_type_unwrapped)
		if c.pref.translated {
			// TODO fix this in C2V instead, for example cast enums to int before using `|` on them.
			// TODO replace all c.pref.translated checks with `$if !translated` for performance
			continue
		}
		if left_sym.kind == .array && !c.inside_unsafe && assign_stmt.op in [.assign, .decl_assign] &&
			right_sym.kind == .array &&
			(left is ast.Ident && !left.is_blank_ident()) && right is ast.Ident
		{
			// Do not allow `a = b`, only `a = b.clone()`
			c.error('use `array2 = array1.clone()` instead of `array2 = array1` (or use `unsafe`)',
				assign_stmt.pos)
		}
		left_is_ptr := left_type.is_ptr() || left_sym.is_pointer()
		if left_is_ptr && c.for_in_mut_val_name != left.str() {
			if !c.inside_unsafe && assign_stmt.op !in [.assign, .decl_assign] {
				// ptr op=
				c.warn('pointer arithmetic is only allowed in `unsafe` blocks', assign_stmt.pos)
			}
			right_is_ptr := right_type.is_ptr() || right_sym.is_pointer()
			if !right_is_ptr && assign_stmt.op == .assign && right_type_unwrapped.is_number() {
				c.error('cannot assign to `$left`: ' +
					c.expected_msg(right_type_unwrapped, left_type_unwrapped), right.position())
			}
			if (right is ast.StructInit || !right_is_ptr) && !right_sym.is_number() {
				left_name := c.table.type_to_str(left_type_unwrapped)
				mut rtype := right_type_unwrapped
				if rtype.is_ptr() {
					rtype = rtype.deref()
				}
				right_name := c.table.type_to_str(rtype)
				c.error('mismatched types `$left_name` and `$right_name`', assign_stmt.pos)
			}
		}
		// Single side check
		match assign_stmt.op {
			.assign {} // No need to do single side check for =. But here put it first for speed.
			.plus_assign, .minus_assign {
				if left_type == table.string_type {
					if assign_stmt.op != .plus_assign {
						c.error('operator `$assign_stmt.op` not defined on left operand type `$left_sym.name`',
							left.position())
					}
					if right_type != table.string_type {
						c.error('invalid right operand: $left_sym.name $assign_stmt.op $right_sym.name',
							right.position())
					}
				} else if !left_sym.is_number() && left_sym.kind !in [.byteptr, .charptr, .struct_, .alias] {
					c.error('operator `$assign_stmt.op` not defined on left operand type `$left_sym.name`',
						left.position())
				} else if !right_sym.is_number() && left_sym.kind !in [.byteptr, .charptr, .struct_, .alias] {
					c.error('invalid right operand: $left_sym.name $assign_stmt.op $right_sym.name',
						right.position())
				} else if right is ast.IntegerLiteral {
					if right.val == '1' {
						op := if assign_stmt.op == .plus_assign {
							token.Kind.inc
						} else {
							token.Kind.dec
						}
						c.error('use `$op` instead of `$assign_stmt.op 1`', assign_stmt.pos)
					}
				}
			}
			.mult_assign, .div_assign {
				if !left_sym.is_number() &&
					!c.table.get_final_type_symbol(left_type_unwrapped).is_int() && left_sym.kind !in
					[.struct_, .alias]
				{
					c.error('operator $assign_stmt.op.str() not defined on left operand type `$left_sym.name`',
						left.position())
				} else if !right_sym.is_number() &&
					!c.table.get_final_type_symbol(left_type_unwrapped).is_int() && left_sym.kind !in
					[.struct_, .alias]
				{
					c.error('operator $assign_stmt.op.str() not defined on right operand type `$right_sym.name`',
						right.position())
				}
			}
			.and_assign, .or_assign, .xor_assign, .mod_assign, .left_shift_assign, .right_shift_assign
			 {
				if !left_sym.is_int() &&
					!c.table.get_final_type_symbol(left_type_unwrapped).is_int()
				{
					c.error('operator $assign_stmt.op.str() not defined on left operand type `$left_sym.name`',
						left.position())
				} else if !right_sym.is_int() &&
					!c.table.get_final_type_symbol(right_type_unwrapped).is_int()
				{
					c.error('operator $assign_stmt.op.str() not defined on right operand type `$right_sym.name`',
						right.position())
				}
			}
			else {}
		}
		if assign_stmt.op in
			[.plus_assign, .minus_assign, .mod_assign, .mult_assign, .div_assign] &&
			((left_sym.kind == .struct_ && right_sym.kind == .struct_) || left_sym.kind == .alias)
		{
			left_name := c.table.type_to_str(left_type)
			right_name := c.table.type_to_str(right_type)
			parent_sym := c.table.get_final_type_symbol(left_type)
			if left_sym.kind == .alias && right_sym.kind != .alias {
				c.error('mismatched types `$left_name` and `$right_name`', assign_stmt.pos)
			}
			extracted_op := match assign_stmt.op {
				.plus_assign { '+' }
				.minus_assign { '-' }
				.div_assign { '/' }
				.mod_assign { '%' }
				.mult_assign { '*' }
				else { 'unknown op' }
			}
			if method := left_sym.find_method(extracted_op) {
				if method.return_type != left_type {
					c.error('operator `$extracted_op` must return `$left_name` to be used as an assignment operator',
						assign_stmt.pos)
				}
			} else {
				if parent_sym.is_primitive() {
					c.error('cannot use operator methods on type alias for `$parent_sym.name`',
						assign_stmt.pos)
				}
				if left_name == right_name {
					c.error('undefined operation `$left_name` $extracted_op `$right_name`',
						assign_stmt.pos)
				} else {
					c.error('mismatched types `$left_name` and `$right_name`', assign_stmt.pos)
				}
			}
		}
		if !is_blank_ident && right_sym.kind != .placeholder && left_sym.kind != .interface_ {
			// Dual sides check (compatibility check)
			c.check_expected(right_type_unwrapped, left_type_unwrapped) or {
				c.error('cannot assign to `$left`: $err', right.position())
			}
		}
		if left_sym.kind == .interface_ {
			c.type_implements(right_type, left_type, right.position())
		}
	}
	// this needs to run after the assign stmt left exprs have been run through checker so that ident.obj is set
	// Check `x := &y` and `mut x := <-ch`
	if right_first is ast.PrefixExpr {
		node := right_first
		left_first := assign_stmt.left[0]
		if left_first is ast.Ident {
			assigned_var := left_first
			c.expr(node.right)
			if node.right is ast.Ident {
				if node.right.obj is ast.Var {
					v := node.right.obj
					right_type0 = v.typ
					if node.op == .amp {
						if !v.is_mut && assigned_var.is_mut && !c.inside_unsafe {
							c.error('`$node.right.name` is immutable, cannot have a mutable reference to it',
								node.pos)
						}
					}
				}
			}
			if node.op == .arrow {
				if assigned_var.is_mut {
					right_sym := c.table.get_type_symbol(right_type0)
					if right_sym.kind == .chan {
						chan_info := right_sym.chan_info()
						if chan_info.elem_type.is_ptr() && !chan_info.is_mut {
							c.error('cannot have a mutable reference to object from `$right_sym.name`',
								node.pos)
						}
					}
				}
			}
		}
	}
	// right_sym := c.table.get_type_symbol(right_type_unwrapped)
}
*/
