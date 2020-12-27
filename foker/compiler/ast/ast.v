// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module ast

import compiler.token

// Esto representa un archivo de script FokerScript
pub struct File {
pub:
	path string
	// el módulo, recordar que cada archivo es un módulo es decir que al 
	// momento de crear un archivo este tendrá un módulo automático.
	mod  Module
}

pub struct Module {
pub:
	name    string
	pos     token.Position
	imports []Import
	stmts   []Stmt
	is_main bool // es esto el modulo principal?
pub mut:
	scope   Scope
}

pub struct Const {
pub:
	mod    string
	name   string
	expr   Expr
	is_pub bool
	pos    token.Position
pub mut:
	typ    Type
}

pub struct Var {
pub:
	name       string
	expr       Expr
pub mut:
	typ        Type
	pos        token.Position
	is_used    bool
	offset	   string // para 'var mivar at 0x800D;'
}

pub type ScopeObject = Const | Var

// Statements
pub type Stmt = AssignStmt | Const | DynamicStmt | ExprStmt | ForInStmt |
	ForStmt | GotoStmt | Include | QuestionStmt | ScriptDecl

pub struct DynamicStmt {
pub:
	pos        token.Position
	dyn_offset string
}

pub struct Include {
pub:
	pos		token.Position
	file	string
}

pub struct ExprStmt {
pub:
	expr    Expr
	pos     token.Position
	is_expr bool
}

pub struct ScriptDecl {
pub:
	name          string
	mod           string
	is_extern     bool // for: extern script Karmelico at 0x8000232F;
	extern_offset string
	pos           token.Position
	body_pos      token.Position
	// file			string
pub mut:
	stmts         []Stmt
}

pub struct Param {
pub:
	name      string
	typ       Type
	pos       token.Position
	def_value Expr // para valores por defecto
}

// para: extern cmd msgbox(msg: string, type: byte = 5);
pub struct CmdDecl {
pub:
	name   string
	params []Param
	pos    token.Position
}

pub struct AssignStmt {
pub:
	right      Expr
	op         token.Kind
	pos        token.Position
	offset     string
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
	stmts  []Stmt
}

pub struct QuestionStmt {
pub:
	pos      token.Position
	question StringLiteral
	yes      QuestionAnswer
	no       QuestionAnswer
}

pub struct ForStmt {
pub:
	cond   Expr
	stmts  []Stmt
	is_inf bool // for {}
	pos    token.Position
pub mut:
	label  string // label: for {
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

// Expressions
pub type Expr = BinaryExpr | BoolLiteral | FmtStringLiteral | Ident | InfixExpr | IntegerLiteral |
	MatchExpr | ParExpr | PostfixExpr | PrefixExpr | SelectorExpr | StringLiteral

pub struct SelectorExpr {
pub:
	pos        token.Position
	expr       Expr // expr.field_name
	field_name string
pub mut:
	expr_type  Type
	typ        Type
}

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

pub struct CallExpr {
pub:
	pos                token.Position
	left               Expr
	mod                string
pub mut:
	name               string
	args               []CallArg
	expected_arg_types []Type
}

pub struct CallArg {
pub:
	expr Expr
pub mut:
	typ  Type
	pos  token.Position
}

pub enum IdentKind {
	unresolved
	blank_ident
	variable
	constant
	global
	function
}

// A single identifier
pub struct Ident {
pub:
	tok_kind token.Kind
	pos      token.Position
pub mut:
	obj      ScopeObject
	mod      string
	name     string
	kind     IdentKind
}

// left op right
pub struct InfixExpr {
pub:
	op         token.Kind
	pos        token.Position
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
	op         token.Kind
	right      Expr
	pos        token.Position
pub mut:
	right_type Type
}

pub struct ParExpr {
pub:
	expr Expr
	pos  token.Position
}

pub struct BinaryExpr {
pub:
	left  Expr
	op    token.Kind
	right Expr
	pos   token.Position
}

pub struct IfBranch {
pub:
	cond     Expr
	pos      token.Position
	body_pos token.Position
pub mut:
	stmts    []Stmt
}

pub struct MatchExpr {
pub:
	tok_kind      token.Kind
	cond          Expr
	branches      []MatchBranch
	pos           token.Position
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
