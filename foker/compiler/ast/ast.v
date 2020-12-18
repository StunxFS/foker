// Copyright (c) 2020 StunxFS. All rights reserved. Use of this source code is
// governed by an MIT license that can be found in the LICENSE file.
module ast

import compiler.token

// Esto representa un archivo de script FokerScript
pub struct File {
pub:
	path	string
	// el módulo, recordar que cada archivo es un módulo es decir que al 
	// momento de crear un archivo este tendrá un módulo automático.
	mod		Module
}

pub struct Module {
pub:
	name	string
	pos		token.Position
	stmts	[]Stmt
pub mut:
	scope	Scope
}

pub struct ConstField {
pub:
	mod		string
	name	string
	expr	Expr
	is_pub	bool
	pos		token.Position
	typ		Type
}

pub struct ConstDecl {
pub:
	is_pub	bool
	pos		token.Position
pub mut:
	fields	[]ConstField
}

pub struct Var {
pub:
	name	string
	expr	Expr
	is_mut	bool
pub mut:
	typ		Type
	pos		token.Position
	is_used	bool
	is_changed	bool // to detect mutable vars that are never changed
}

pub type ScopeObject = ConstField | Var

// Statements
pub type Stmt = ExprStmt | EnumDecl | ConstDecl | AssignStmt | QuestionStmt
				| Import | ForStmt | ForInStmt | GotoStmt | ScriptDecl

pub struct ImportField {
pub:
	pos		token.Position
	mod		string
	alias	string
}

pub struct Import {
	pos		token.Position
	fields	[]ImportField
}

pub struct ExprStmt {
pub:
	expr     Expr
	pos      token.Position
	is_expr  bool
}

pub struct EnumField {
pub:
	name		string
	pos			token.Position
	expr		Expr
	has_expr	bool
}

pub struct EnumDecl {
pub:
	name		string
	is_pub		bool
	fields		[]EnumField
	pos			token.Position
	typ			Type
}

pub fn (_enum &EnumDecl) exists_field(name string) bool {
	for field in _enum.fields {
		if field.name == name { return true }
	}
	return false
}

pub struct ScriptDecl {
pub:
	name			string
	mod				string
	is_pub			bool
	is_extern		bool // for: extern script Karmelico at 0x8000232F;
	extern_offset 	string
	pos				token.Position
	body_pos		token.Position
	//file			string
pub mut:
	stmts			[]Stmt
}

pub struct Param {
pub:
	name		string
	typ			Type
	pos			token.Position
	def_value	Expr // para valores por defecto
}

// para: extern cmd msgbox(msg: string, type: byte = 5);
pub struct CmdDecl {
pub:
	name	string
	params	[]Param
	is_pub	bool
	pos		token.Position
}

pub struct AssignStmt {
pub:
	right		Expr
	op			token.Kind
	pos			token.Position
pub mut:
	left		Expr
	left_type	Type
	right_type	Type	
}

pub struct QuestionAnswer {
pub:
	pos		token.Position
	is_yes	bool // false for 'no'
pub mut:
	stmts	[]Stmt
}

pub struct QuestionStmt {
pub:
	pos			token.Position
	question	StringLiteral
	yes			QuestionAnswer
	no			QuestionAnswer
}

pub struct ForStmt {
pub:
	cond		Expr
	stmts		[]Stmt
	is_inf		bool // for {}
	pos			token.Position
pub mut:
	label		string // label: for {
}

pub struct ForInStmt {
pub:
	key_var		string
	val_var		string
	cond		Expr
	is_range	bool
	high		Expr // 10 in for i in 0..10
	stmts		[]Stmt
	pos			token.Position
}

pub struct GotoLabel {
pub:
	name	string
	pos		token.Position
}

pub struct GotoStmt {
pub:
	name	string
	pos		token.Position
}

// Expressions
pub type Expr = IntegerLiteral | StringLiteral | BoolLiteral | MatchExpr | InfixExpr | PrefixExpr | PostfixExpr | Ident |
				ParExpr | SelectorExpr | BinaryExpr

pub struct SelectorExpr {
pub:
	pos			token.Position
	expr		Expr // expr.field_name
	field_name	string
pub mut:
	expr_type	Type
	typ			Type
}

pub struct IntegerLiteral {
pub:
	pos		token.Position
	lit		string
	is_hex	bool // para evitar la conversión a hex
}

pub struct StringLiteral {
pub:
	pos		token.Position
	lit		string
	autofmt	bool // para checar si aplicamos formato o no
}

pub struct BoolLiteral {
pub:
	pos		token.Position
	lit		string
}

// break, continue
pub struct BranchStmt {
pub:
	kind	token.Kind
	label	string
	pos		token.Position
}

pub struct CallExpr {
pub:
	pos					token.Position
	left				Expr
	mod					string
pub mut:
	name				string
	args				[]CallArg
	expected_arg_types 	[]Type
}

pub struct CallArg {
pub:
	expr		Expr
pub mut:
	typ			Type
	pos			token.Position
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
	tok_kind	token.Kind
	pos			token.Position
	mut_pos		token.Position
pub mut:
	obj			ScopeObject
	mod			string
	name		string
	kind		IdentKind
	is_mut		bool
}

// left op right
pub struct InfixExpr {
pub:
	op			token.Kind
	pos			token.Position
pub mut:
	left		Expr
	right		Expr
	left_type	Type
	right_type 	Type
}

// ++, --
pub struct PostfixExpr {
pub:
	op			token.Kind
	expr		Expr
	pos			token.Position
}

pub struct PrefixExpr {
pub:
	op			token.Kind
	right		Expr
	pos			token.Position
pub mut:
	right_type	Type
}

pub struct ParExpr {
pub:
	expr	Expr
	pos		token.Position
}

pub struct BinaryExpr {
pub:
	left	Expr
	op		token.Kind
	right 	Expr
	pos		token.Position
}

pub struct IfBranch {
pub:
	cond		Expr
	pos			token.Position
	body_pos	token.Position
pub mut:
	stmts		[]Stmt
}

pub struct MatchExpr {
pub:
	tok_kind		token.Kind
	cond			Expr
	branches		[]MatchBranch
	pos				token.Position
pub mut:
	cond_type		Type
	expected_type	Type
}

pub struct MatchBranch {
pub:
	exprs			[]Expr
	stmts			[]Stmt
	pos				token.Position
	is_else			bool
}
