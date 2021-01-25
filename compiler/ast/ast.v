// (C) 2020-2021 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module ast

import compiler.token
import compiler.errors

// Esto representa un archivo de script ZubatScript
pub struct File {
pub:
	path string
	mod  Module
pub mut:
	reports []errors.Report
	imports []Import
}

pub struct Module {
pub:
	name         string
	stmts        []Stmt
	global_scope &Scope
pub mut:
	scope &Scope
}

pub struct Const {
pub:
	name   string
	expr   Expr
	pos    token.Position
	is_pub bool
pub mut:
	typ Type
}

pub struct Var {
pub:
	name   string
	expr   Expr
	is_pub bool
pub mut:
	typ     Type
	pos     token.Position
	is_used bool
	offset  string // para 'var mivar at 0x800D;'
}

pub type ScopeObject = Const | Var

// Statements
pub type Stmt = AssignStmt | Block | BranchStmt | CallCmdStmt | CallStmt | CheckgenderStmt |
	CmdDecl | Const | DynamicStmt | ExprStmt | ForInStmt | ForStmt | FreeStmt | GotoLabel |
	GotoStmt | IfStmt | Import | MatchStmt | QuestionStmt | RawStmt | ScriptDecl

pub struct RawStmt {
pub:
	text string
	pos  token.Position
}

pub struct Block {
pub:
	stmts []Stmt
	pos   token.Position
}

pub struct DynamicStmt {
pub:
	pos        token.Position
	dyn_offset string
}

pub struct Import {
pub:
	pos  token.Position
	file string
}

pub struct ExprStmt {
pub:
	expr    Expr
	pos     token.Position
	is_expr bool
pub mut:
	typ Type
}

pub struct ScriptDecl {
pub:
	name          string
	is_extern     bool // for: extern script Karmelico at 0x8000232F;
	extern_offset string
	pos           token.Position
	body_pos      token.Position
	is_pub        bool
pub mut:
	stmts []Stmt
}

pub struct Param {
pub:
	name string
	typ  Type
	pos  token.Position
}

// para: extern cmd msgbox(msg: string, type: byte = 6);
pub struct CmdDecl {
pub:
	name   string
	params []Param
	pos    token.Position
}

pub struct FreeStmt {
pub:
	pos   token.Position
	ident string
}

pub struct AssignStmt {
pub:
	right     Expr
	op        token.Kind
	pos       token.Position
	offset    string
	is_native bool
	is_decl   bool
	is_global bool
pub mut:
	left       Expr
	left_type  Type
	right_type Type
}

pub struct QuestionAnswer {
pub:
	pos    token.Position
	is_yes bool // false for 'no'
pub mut:
	stmts []Stmt
}

pub struct QuestionStmt {
pub:
	pos      token.Position
	question StringLiteral
	yes      QuestionAnswer
	no       QuestionAnswer
}

pub struct CheckgenderStmt {
pub:
	pos        token.Position
	boy_pos    token.Position
	girl_pos   token.Position
	boy_stmts  []Stmt
	girl_stmts []Stmt
}

// para: call my_script;
pub struct CallStmt {
pub:
	pos    token.Position // posición de 'my_script' en 'call my_script;
	script string // script a llamar
}

// para: msgbox("hola", type: 6);
pub struct CallCmdStmt {
pub:
	pos token.Position
pub mut:
	name               string
	args               []CallArg
	expected_arg_types []Type
}

pub struct CallArg {
pub:
	name string // para args. opcionales.
	expr Expr
pub mut:
	typ    Type
	pos    token.Position
	is_opt bool // es argumento opcional
}

pub struct ForStmt {
pub:
	cond   Expr
	stmts  []Stmt
	is_inf bool // for {}
	pos    token.Position
pub mut:
	label string // label: for {
}

pub struct ForInStmt {
pub:
	key_var  string
	val_var  string
	cond     Expr
	is_range bool
	high     Expr // 10 in for i in 0..10
	stmts    []Stmt
	pos      token.Position
}

pub struct GotoLabel {
pub:
	name string
	pos  token.Position
}

pub struct GotoStmt {
pub:
	name string
	pos  token.Position
}

pub struct IfStmt {
pub:
	pos      token.Position
	body_pos token.Position
pub mut:
	branches []IfBranch // includes all `else if` branches
	scope    &Scope = 0
}

pub struct IfBranch {
pub:
	cond     Expr
	is_else  bool
	pos      token.Position
	body_pos token.Position
pub mut:
	stmts []Stmt
	scope &Scope = 0
}

pub struct MatchStmt {
pub:
	cond     Expr
	branches []MatchBranch
	pos      token.Position
pub mut:
	cond_type     Type
	expected_type Type
}

pub struct MatchBranch {
pub:
	exprs   []Expr
	stmts   []Stmt
	pos     token.Position
	is_else bool
}

// Expressions
pub type Expr = BoolLiteral | FmtStringLiteral | Ident | InfixExpr | IntegerLiteral |
	MovementExpr | ParExpr | PostfixExpr | PrefixExpr | StringLiteral

pub struct IntegerLiteral {
pub:
	pos    token.Position
	lit    string
	is_hex bool // para evitar la conversión a hex
}

pub struct StringLiteral {
pub:
	pos token.Position
	lit string
}

pub struct FmtStringLiteral {
pub:
	pos   token.Position
	width int // si 'width' es igual a 0, entonces se usa el valor por defecto
	expr  Expr
}

pub struct BoolLiteral {
pub:
	pos token.Position
	lit string
}

// break, continue
pub struct BranchStmt {
pub:
	kind  token.Kind
	label string
	pos   token.Position
}

pub enum IdentKind {
	unresolved
	blank_ident
	variable
	constant
}

pub fn (ik IdentKind) str() string {
	return match ik {
		.unresolved { 'no resolvido' }
		.blank_ident { 'identificador blanco' }
		.variable { 'variable' }
		.constant { 'constante' }
	}
}

// A single identifier
pub struct Ident {
pub:
	tok_kind token.Kind
	pos      token.Position
pub mut:
	obj   ScopeObject
	name  string
	kind  IdentKind
	scope &Scope = 0
}

// left op right
pub struct InfixExpr {
pub:
	op  token.Kind
	pos token.Position
pub mut:
	left       Expr
	right      Expr
	left_type  Type
	right_type Type
}

// ++, --
pub struct PostfixExpr {
pub:
	op   token.Kind
	expr Expr
	pos  token.Position
}

pub struct PrefixExpr {
pub:
	op    token.Kind
	right Expr
	pos   token.Position
pub mut:
	right_type Type
}

pub struct ParExpr {
pub:
	expr Expr
	pos  token.Position
}

pub enum MovKind {
	walk_up
	walk_down
	walk_left
	walk_right
}

pub struct MovItem {
pub:
	kind  MovKind
	count int // repeat
	pos   token.Position
}

pub struct MovementExpr {
pub:
	name    string
	pos     token.Position
	is_anon bool // for applymovement(movement{});
	movs    []MovItem
}

[inline]
pub fn (expr Expr) is_blank_ident() bool {
	match expr {
		Ident { return expr.kind == .blank_ident }
		else { return false }
	}
}

pub fn (expr Expr) position() token.Position {
	match expr { // /*ConcatExpr, */  /*RangeExpr, */ 
		BoolLiteral, Ident, IntegerLiteral, ParExpr, PostfixExpr, PrefixExpr, StringLiteral, FmtStringLiteral,
		MovementExpr {
			return expr.pos
		}
		InfixExpr {
			left_pos := expr.left.position()
			right_pos := expr.right.position()
			return token.Position{
				line_nr: expr.pos.line_nr
				pos: left_pos.pos
				len: right_pos.pos - left_pos.pos + right_pos.len
				filepath: left_pos.filepath
			}
		}
	}
}

pub fn (expr Expr) is_lvalue() bool {
	match expr {
		Ident { return true }
		else {}
	}
	return false
}

pub fn (expr Expr) is_lit() bool {
	return match expr {
		BoolLiteral, StringLiteral, IntegerLiteral { true }
		else { false }
	}
}

pub fn (stmt Stmt) position() token.Position {
	match stmt {
		AssignStmt, Block, BranchStmt, CallStmt, CallCmdStmt, Const, ExprStmt, ForStmt, ForInStmt,
		GotoLabel, GotoStmt, IfStmt, CmdDecl, DynamicStmt, FreeStmt, Import, QuestionStmt, ScriptDecl,
		CheckgenderStmt, MatchStmt, RawStmt { return stmt.pos }
	}
}
