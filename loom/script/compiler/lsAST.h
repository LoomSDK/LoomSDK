/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#ifndef _ls_ast_h
#define _ls_ast_h

extern "C" {
#ifdef LOOM_ENABLE_JIT
#include "lj_obj.h"
#else
#include "lua.h"
#include "lfunc.h"
#endif
}

#include "jansson.h"

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/script/compiler/lsToken.h"
#include "loom/script/compiler/lsVisitor.h"

#include "loom/script/reflection/lsReflection.h"

namespace LS {
/*
** Expression descriptor
*/

#ifndef LOOM_ENABLE_JIT
enum ExpKind
{
    VVOID,                   /* no value */
    VNIL, VTRUE, VFALSE, VK, /* info = index of constant in `k' */
    VKNUM,                   /* nval = numerical value */
    VLOCAL,                  /* info = local register */
    VUPVAL,                  /* info = index of upvalue in `upvalues' */
    VGLOBAL,                 /* info = index of table; aux = index of global name in `k' */
    VINDEXED,                /* info = table register; aux = index register (or `k') */
    VJMP,                    /* info = instruction pc */
    VRELOCABLE,              /* info = instruction pc */
    VNONRELOC,               /* info = result register */
    VCALL,                   /* info = instruction pc */
    VVARARG
};

struct ExpDesc
{
    ExpKind k;
    union
    {
        struct
        {
            int info, aux;
        }
                   s;
        lua_Number nval;
    }
            u;
    int     t; /* patch list of `exit when true' */
    int     f; /* patch list of `exit when false' */

    ExpDesc()
    {
        k        = VVOID;
        u.s.info = 0;
        u.nval   = 0.0;
        t        = 0;
        f        = 0;
    }
};

#else
/* Expression kinds. */
typedef enum
{
    /* Constant expressions must be first and in this order: */
    VKNIL,
    VKFALSE,
    VKTRUE,
    VKSTR,      /* sval = string value */
    VKNUM,      /* nval = number value */
    VKLAST = VKNUM,
    VKCDATA,    /* nval = cdata value, not treated as a constant expression */
    /* Non-constant expressions follow: */
    VLOCAL,     /* info = local register */
    VUPVAL,     /* info = upvalue index */
    VGLOBAL,    /* sval = string value */
    VINDEXED,   /* info = table register, aux = index reg/byte/string const */
    VJMP,       /* info = instruction PC */
    VRELOCABLE, /* info = instruction PC */
    VNONRELOC,  /* info = result register */
    VCALL,      /* info = instruction PC, aux = base */
    VVOID
} ExpKind;

/* Expression descriptor. */
typedef struct ExpDesc
{
    union
    {
        struct
        {
            uint32_t info; /* Primary info. */
            uint32_t aux;  /* Secondary info. */
        }      s;
        TValue nval;       /* Number value. */
        GCstr  *sval;      /* String value. */
    }       u;
    ExpKind k;
    BCPos   t;  /* True condition jump list. */
    BCPos   f;  /* False condition jump list. */
} ExpDesc;
#endif

typedef enum ASTType
{
    AST_UNDEFINED,

    AST_COMPILEUNIT,

    /* statements*/
    AST_STATEMENT, /*abstract*/
    AST_FUNCTIONDECL,
    AST_PROPERTYDECL,
    AST_EMPTYSTATEMENT,
    AST_BLOCKSTATEMENT,
    AST_BREAKSTATEMENT,
    AST_CONTINUESTATEMENT,
    AST_DOSTATEMENT,
    AST_FORSTATEMENT,
    AST_FORINSTATEMENT,
    AST_IFSTATEMENT,
    AST_RETURNSTATEMENT,
    AST_THROWSTATEMENT,
    AST_TRYSTATEMENT,
    AST_CASESTATEMENT,
    AST_SWITCHSTATEMENT,
    AST_VARSTATEMENT,
    AST_WHILESTATEMENT,
    AST_WITHSTATEMENT,
    AST_LABELSTATEMENT,
    AST_EXPRESSIONSTATEMENT,
    AST_IMPORTSTATEMENT,

    /* expressions */
    AST_IDENTIFIER,
    AST_BINARYEXPRESSION,
    AST_ASSIGNMENTEXPRESSION,
    AST_MULTIPLEASSIGNMENTEXPRESSION,
    AST_ASSIGNMENTOPERATOREXPRESSION,
    AST_LOGICALOREXPRESSION,
    AST_LOGICALANDEXPRESSION,
    AST_NEWEXPRESSION,
    AST_BINARYOPERATOREXPRESSION,
    AST_CONDITIONALEXPRESSION,
    AST_UNARYEXPRESSION,
    AST_UNARYOPERATOREXPRESSION,
    AST_INCREMENTEXPRESSION,
    AST_DELETEEXPRESSION,
    AST_CALLEXPRESSION,
    AST_YIELDEXPRESSION,
    AST_PROPERTYEXPRESSION,
    AST_VARDECL,
    AST_VAREXPRESSION,

    AST_CONCATOPERATOREXPRESSION,
    AST_SUPEREXPRESSION,

    /* literals (also expressions)*/
    AST_THISLITERAL,
    AST_NULLLITERAL,
    AST_BOOLEANLITERAL,
    AST_STRINGLITERAL,
    AST_NUMBERLITERAL,
    AST_ARRAYLITERAL,
    AST_OBJECTLITERAL,
    AST_OBJECTLITERALPROPERTY,
    AST_FUNCTIONLITERAL,
    AST_SUPERLITERAL,
    AST_MODIFIERLITERAL,
    AST_PROPERTYLITERAL,
    AST_VECTORLITERAL,
    AST_DICTIONARYLITERAL,
    AST_DICTIONARYLITERALPAIR,

    AST_INTERFACEDECL,
    AST_PACKAGEDECL,
    AST_CLASSDECL,
} ASTType;

class ASTNode;

class Scope;
class TemplateInfo;

class MetaTag {
public:
    utString name;
    utHashTable<utHashedString, utString> keys;
};

class ASTTemplateTypeInfo {
public:

    utString typeString;
    utArray<ASTTemplateTypeInfo *> templateTypes;
    ASTTemplateTypeInfo            *parent;

    ASTTemplateTypeInfo() : parent(NULL)
    {

    }

    static ASTTemplateTypeInfo* createDictionaryInfo(const utString& typeKey, const utString& typeValue)
    {

        ASTTemplateTypeInfo *templateInfo = new ASTTemplateTypeInfo;
        templateInfo->typeString = "Dictionary";
        templateInfo->templateTypes.push_back(new ASTTemplateTypeInfo);
        templateInfo->templateTypes[0]->typeString = typeKey;
        templateInfo->templateTypes.push_back(new ASTTemplateTypeInfo);
        templateInfo->templateTypes[1]->typeString = typeValue;

        return templateInfo;
    }

    static ASTTemplateTypeInfo* createVectorInfo(const utString& type)
    {
        ASTTemplateTypeInfo *templateInfo = new ASTTemplateTypeInfo;
        templateInfo->typeString = "Vector";
        templateInfo->templateTypes.push_back(new ASTTemplateTypeInfo);
        templateInfo->templateTypes[0]->typeString = type;
        return templateInfo;        
    }
};

class ASTNode {
public:

    ASTType astType;

    int lineNumber;

    ExpDesc e;

    bool                assignment;
    MemberInfo          *memberInfo;
    TemplateInfo        *templateInfo;
    ASTTemplateTypeInfo *astTemplateInfo;

    utArray<MetaTag *> metaTags;

    utString docString;

    ASTNode()
    {
        memset(&e, 0, sizeof(ExpDesc));
        lineNumber      = 0;
        astType         = AST_UNDEFINED;
        assignment      = false;
        memberInfo      = NULL;
        templateInfo    = NULL;
        astTemplateInfo = NULL;
    }

    virtual ~ASTNode()
    {
    }

    MetaTag *findMetaTag(const utString& name)
    {
        for (UTsize i = 0; i < metaTags.size(); i++)
        {
            MetaTag *tag = metaTags.at(i);
            if (!strcasecmp(tag->name.c_str(), name.c_str()))
            {
                return tag;
            }
        }

        return NULL;
    }

    bool hasMetaKey(const utString& name, const utString& key)
    {
        MetaTag *tag = findMetaTag(name);

        if (tag)
        {
            if (tag->keys.find(key) != UT_NPOS)
            {
                return true;
            }
        }

        return false;
    }
};

class Statement : public ASTNode {
public:
    virtual Statement *visitStatement(Visitor *visitor) = 0;
};

class EmptyStatement : public Statement {
public:

    EmptyStatement()
    {
        astType = AST_EMPTYSTATEMENT;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class BlockStatement : public Statement {
public:
    utArray<Statement *> *statements;

    BlockStatement() :
        statements(NULL)
    {
        astType = AST_BLOCKSTATEMENT;
    }

    BlockStatement(utArray<Statement *> *_statements)
    {
        statements = _statements;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class Expression : public ASTNode {
public:
    virtual Expression *visitExpression(Visitor *visitor) = 0;

    Type *type;

    // Whether or not this is a primary expression (instead of a subexpression)
    bool primaryExpression;

    Expression() :
        type(NULL), primaryExpression(false)
    {
    }
};

class UnaryExpression : public Expression {
public:
    Expression *subExpression;

    UnaryExpression(Expression *expression)
    {
        astType             = AST_UNARYEXPRESSION;
        this->subExpression = expression;
    }
};

class DeleteExpression : public UnaryExpression {
public:

    DeleteExpression(Expression *expression) :
        UnaryExpression(expression)
    {
        astType = AST_DELETEEXPRESSION;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class UnaryOperatorExpression : public UnaryExpression {
public:

    Token *op;

    UnaryOperatorExpression(Expression *expression, Token *op) :
        UnaryExpression(expression)
    {
        this->op = op;
        astType  = AST_UNARYOPERATOREXPRESSION;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class IncrementExpression : public UnaryExpression {
public:
    int  value;
    bool post;

    IncrementExpression(Expression *expression, int value, bool post) :
        UnaryExpression(expression)
    {
        astType     = AST_INCREMENTEXPRESSION;
        this->value = value;
        this->post  = post;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class BinaryExpression : public Expression {
public:
    Expression *leftExpression;
    Expression *rightExpression;

    BinaryExpression(Expression *left, Expression *right)
    {
        assert(left);
        assert(right);

        this->leftExpression  = left;
        this->rightExpression = right;
    }
};

class MultipleAssignmentExpression : public Expression {
public:

    utArray<Expression *> left;
    utArray<Expression *> right;

    MultipleAssignmentExpression()
    {
        astType = AST_MULTIPLEASSIGNMENTEXPRESSION;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class AssignmentExpression : public BinaryExpression {
public:

    AssignmentExpression(Expression *left, Expression *right) :
        BinaryExpression(left, right)
    {
        left->assignment = true;
        astType          = AST_ASSIGNMENTEXPRESSION;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class BinaryOperatorExpression : public BinaryExpression {
public:

    Token *op;

    BinaryOperatorExpression(Expression *left, Expression *right, Token *op) :
        BinaryExpression(left, right)
    {
        astType = AST_BINARYOPERATOREXPRESSION;

        this->op = op;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class LogicalOrExpression : public BinaryOperatorExpression {
public:

    LogicalOrExpression(Expression *left, Expression *right, Token *op) :
        BinaryOperatorExpression(left, right, op)
    {
        astType = AST_LOGICALOREXPRESSION;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class LogicalAndExpression : public BinaryOperatorExpression {
public:

    LogicalAndExpression(Expression *left, Expression *right, Token *op) :
        BinaryOperatorExpression(left, right, op)
    {
        astType = AST_LOGICALANDEXPRESSION;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class PropertyExpression : public BinaryExpression {
public:

    bool arrayAccess;

    // in the case of a static access of a member this will be true
    // for example: MyClass.myMemberVariable
    bool staticAccess;

    VariableDeclaration *varDecl;

    PropertyExpression(Expression *left, Expression *right, bool arrayAccess = false) :
        BinaryExpression(left, right)
    {
        astType = AST_PROPERTYEXPRESSION;

        // if we're accessing a member, make
        // sure binary op children aren't marked
        // primary
        if (!arrayAccess)
        {
            left->primaryExpression  = false;
            right->primaryExpression = false;
        }

        varDecl            = NULL;
        this->arrayAccess  = arrayAccess;
        this->staticAccess = false;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class AssignmentOperatorExpression : public BinaryExpression {
public:

    Token *type;

    AssignmentOperatorExpression(Expression *left, Expression *right,
                                 Token *type) :
        BinaryExpression(left, right)
    {
        left->assignment = true;
        astType          = AST_ASSIGNMENTOPERATOREXPRESSION;
        this->type       = type;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class NewExpression : public Expression {
public:

    Expression            *function;
    utArray<Expression *> *arguments;

    NewExpression()
    {
        function  = NULL;
        arguments = NULL;

        astType = AST_NEWEXPRESSION;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class CallExpression : public Expression {
public:

    Expression            *function;
    utArray<Expression *> *arguments;
    MethodBase            *methodBase;

    CallExpression()
    {
        function   = NULL;
        arguments  = NULL;
        methodBase = NULL;

        astType = AST_CALLEXPRESSION;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class YieldExpression : public Expression {
public:

    utArray<Expression *> *arguments;

    YieldExpression()
    {
        arguments = NULL;
        astType   = AST_YIELDEXPRESSION;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class ConditionalExpression : public Expression {
public:
    Expression *expression;
    Expression *trueExpression;
    Expression *falseExpression;

    ConditionalExpression(Expression *expression, Expression *trueExpression,
                          Expression *falseExpression)
    {
        astType = AST_CONDITIONALEXPRESSION;

        this->expression      = expression;
        this->trueExpression  = trueExpression;
        this->falseExpression = falseExpression;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class Identifier : public Expression {
public:

    utString string;

    // in the case of a aliased identifier, we may want to
    // know what the identifier was pre-aliasing, for instance
    // we want to treat int as Number in most cases, however
    // if we are casting we need to know that we are casting specifically
    // to int
    utString preAliasString;

    VariableDeclaration *localVarDecl;

    // whether this is a super access in the form of
    // super.identifier, will only be true for
    // property accessors as function calls
    // are handled by SuperExpression AST Node
    bool superAccess;

    // true if this is an inferred type expression
    // such as var t:Type = String;
    // the String identifier on the right hand
    // of the assignment is a type expression
    // which gets transformed to a system.reflection.Type instance
    // representing the type
    bool typeExpression;

    Identifier(const utString& value) 
    {
        astType = AST_IDENTIFIER;
        string = value;
        localVarDecl = NULL;
        typeExpression = false;
        superAccess    = false;
    }

    UT_INLINE bool operator==(const Identifier& v) const
    {
        return this->string == v.string;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class SuperExpression : public Expression {
public:

    utArray<Expression *> arguments;
    Identifier            *method;

    utString resolvedTypeName;

    SuperExpression() :
        Expression(), method(NULL)
    {
        astType = AST_SUPEREXPRESSION;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class StringLiteral : public Expression {
public:

    utString string;

    StringLiteral(utString value)
    {
        astType = AST_STRINGLITERAL;

        this->string = value;
    }

    UT_INLINE bool operator==(const Identifier& v) const
    {
        return this->string == v.string;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class ThisLiteral : public Expression {
public:

    ThisLiteral()
    {
        astType = AST_THISLITERAL;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class NullLiteral : public Expression {
public:

    NullLiteral()
    {
        astType = AST_NULLLITERAL;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class BooleanLiteral : public Expression {
public:

    bool value;

    BooleanLiteral(bool value)
    {
        astType     = AST_BOOLEANLITERAL;
        this->value = value;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class NumberLiteral : public Expression {
public:
    double value;

    // the source string value, which can be decimal, oct, hex, etc
    utString svalue;

    NumberLiteral(double value)
    {
        astType     = AST_NUMBERLITERAL;
        this->value = value;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class ArrayLiteral : public Expression {
public:

    utArray<Expression *> *elements;

    ArrayLiteral() :
        elements(NULL)
    {
        astType = AST_ARRAYLITERAL;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class ObjectLiteralProperty : public Expression {
public:

    Expression *name;
    Expression *value;

    ObjectLiteralProperty()
    {
        astType = AST_OBJECTLITERALPROPERTY;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class VectorLiteral : public Expression {
public:

    utString              typeString;
    utArray<Expression *> elements;

    VectorLiteral()
    {
        astType = AST_VECTORLITERAL;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class DictionaryLiteralPair : public Expression {
public:

    Expression *key;
    Expression *value;

    DictionaryLiteralPair()
    {
        astType = AST_DICTIONARYLITERALPAIR;
        key     = NULL;
        value   = NULL;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class DictionaryLiteral : public Expression {
public:

    utString typeKeyString;
    utString typeValueString;

    utArray<DictionaryLiteralPair *> pairs;

    DictionaryLiteral()
    {
        astType = AST_DICTIONARYLITERAL;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};


class ObjectLiteral : public Expression {
public:

    utArray<ObjectLiteralProperty *> *properties;
    ObjectLiteral()
    {
        astType    = AST_OBJECTLITERAL;
        properties = NULL;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class VariableDeclaration : public Expression {
public:

    Identifier *identifier;
    Expression *initializer;
    bool       defaultInitializer;

    FunctionLiteral  *function;
    ClassDeclaration *classDecl;

    utString typeString;

    bool isPublic;
    bool isProtected;
    bool isStatic;
    bool isNative;
    bool isVarArg;
    bool isParameter;
    bool isTemplate;
    bool isConst;

    // this variable will be implicitly typed based on assignment
    bool assignType;

    // when implicitly typing in a for..in or for..each we
    // must delay type assignment until the expression being iterated
    // has been visited (as we need to know whether we are assigning type
    // to key type or value type)
    bool assignForIn;

    // if the type is rewritten by the compiler, for instance to NativeDelegate
    // this will contain the original type before the rewrite
    Type *originalType;

    VariableDeclaration(Identifier *identifier, Expression *initializer,
                        bool _isPublic, bool _isProtected, bool _isStatic, bool _isNative) :
        defaultInitializer(false), function(NULL), classDecl(NULL),
        isPublic(_isPublic), isProtected(_isProtected), isStatic(_isStatic), isNative(_isNative),
        isVarArg(false), isParameter(false), isTemplate(false), isConst(false)
    {
        astType           = AST_VARDECL;
        this->identifier  = identifier;
        this->initializer = initializer;
        assignType        = false;
        assignForIn       = false;
        originalType      = NULL;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class VariableExpression : public Expression {
public:
    utArray<VariableDeclaration *> *declarations;

    VariableExpression()
    {
        astType      = AST_VAREXPRESSION;
        declarations = NULL;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class BreakStatement : public Statement {
public:
    Identifier *identifier;

    BreakStatement(Identifier *ident)
    {
        astType    = AST_BREAKSTATEMENT;
        identifier = ident;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class ContinueStatement : public Statement {
public:
    Identifier *identifier;

    ContinueStatement(Identifier *ident)
    {
        astType = AST_CONTINUESTATEMENT;

        identifier = ident;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class DoStatement : public Statement {
public:
    Statement  *statement;
    Expression *expression;

    DoStatement(Statement *statement, Expression *expression)
    {
        astType = AST_DOSTATEMENT;

        this->statement  = statement;
        this->expression = expression;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class ForInStatement : public Statement {
public:
    Expression *variable;
    Expression *expression;
    Statement  *statement;

    bool foreach;

    ForInStatement(Expression *variable, Expression *expression,
                   Statement *statement, bool foreach)
    {
        astType = AST_FORINSTATEMENT;

        this->variable   = variable;
        this->expression = expression;
        this->statement  = statement;
        this->foreach    = foreach;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class ForStatement : public Statement {
public:
    Expression *initial;
    Expression *condition;
    Expression *increment;
    Statement  *statement;

    ForStatement(Expression *initial, Expression *condition,
                 Expression *increment, Statement *statement)
    {
        astType = AST_FORSTATEMENT;

        if (!initial)
        {
            initial = new BooleanLiteral(true);
        }

        if (!condition)
        {
            condition = new BooleanLiteral(true);
        }

        if (!increment)
        {
            increment = new BooleanLiteral(true);
        }

        this->initial   = initial;
        this->condition = condition;
        this->increment = increment;
        this->statement = statement;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class IfStatement : public Statement {
public:
    Expression *expression;
    Statement  *trueStatement;
    Statement  *falseStatement;

    IfStatement(Expression *expression, Statement *trueStatement,
                Statement *falseStatement)
    {
        astType = AST_IFSTATEMENT;

        this->expression     = expression;
        this->trueStatement  = trueStatement;
        this->falseStatement = falseStatement;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class ReturnStatement : public Statement {
public:

    utArray<Expression *> *result;

    ReturnStatement(utArray<Expression *> *result)
    {
        astType = AST_RETURNSTATEMENT;

        this->result = result;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class ThrowStatement : public Statement {
public:
    Expression *expression;

    ThrowStatement(Expression *expression)
    {
        astType = AST_THROWSTATEMENT;

        this->expression = expression;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class WhileStatement : public Statement {
public:
    Expression *expression;
    Statement  *statement;

    WhileStatement(Expression *expression, Statement *statement)
    {
        astType = AST_WHILESTATEMENT;

        this->expression = expression;
        this->statement  = statement;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class WithStatement : public Statement {
public:
    Expression *expression;
    Statement  *statement;

    WithStatement(Expression *expression, Statement *statement)
    {
        astType = AST_WITHSTATEMENT;

        this->expression = expression;
        this->statement  = statement;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class TryStatement : public Statement {
public:

    Statement  *tryBlock;
    Expression *catchIdentifier;
    Statement  *catchBlock;
    Statement  *finallyBlock;

    TryStatement(Statement *tryBlock, Expression *catchIdentifier,
                 Statement *catchBlock, Statement *finallyBlock)
    {
        astType = AST_TRYSTATEMENT;

        this->tryBlock        = tryBlock;
        this->catchIdentifier = catchIdentifier;
        this->catchBlock      = catchBlock;
        this->finallyBlock    = finallyBlock;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class CaseStatement : public Statement {
public:
    Expression           *expression;
    utArray<Statement *> *statements;

    CaseStatement()
    {
        astType = AST_CASESTATEMENT;

        statements = NULL;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class VariableStatement : public Statement {
public:
    utArray<VariableDeclaration *> *declarations;

    VariableStatement(utArray<VariableDeclaration *> *declarations)
    {
        astType = AST_VARSTATEMENT;

        this->declarations = declarations;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class ExpressionStatement : public Statement {
public:
    Expression *expression;

    ExpressionStatement(Expression *expression)
    {
        astType = AST_EXPRESSIONSTATEMENT;

        this->expression = expression;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class LabelledStatement : public Statement {
public:
    Identifier *identifier;
    Statement  *statement;

    LabelledStatement(Identifier *identifier, Statement *statement)
    {
        astType = AST_LABELSTATEMENT;

        this->identifier = identifier;
        this->statement  = statement;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class SwitchStatement : public Statement {
public:
    Expression               *expression;
    utArray<CaseStatement *> *clauses;

    SwitchStatement()
    {
        astType = AST_SWITCHSTATEMENT;

        clauses = NULL;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class PropertyLiteral;
class FunctionLiteral : public Expression {
public:

    bool isPublic;
    bool isProtected;
    bool isStatic;
    bool isConstructor;
    bool isNative;
    bool isOperator;
    bool isCoroutine;

    bool isGetter;
    bool isSetter;

    bool hasSuperCall;

    bool isDefaultConstructor;

    // While generating bytecode, variable args
    // locals must be unique for scope.
    // This is due to the fact that they may be nested
    // in functions calls
    // we track the current var arg being generated here
    int curVarArgCalls;
    // The total number of calls in the function
    // which contain variable args
    int numVarArgCalls;

    Identifier *retType;
    utArray<VariableDeclaration *> *parameters;

    // for local functions
    utArray<Type *> templateTypes;

    Identifier       *name;
    ClassDeclaration *classDecl;

    // including parameters
    utArray<VariableDeclaration *> localVariables;

    utArray<Expression *> defaultArguments;

    utArray<Statement *> *functions;
    utArray<Statement *> *statements;

    MethodBase *methodBase;

    // operator token
    Token *toperator;

    PropertyLiteral *property;

    // parent (enclosing) function if any
    FunctionLiteral *parentFunction;
    // array of child functions
    utArray<FunctionLiteral *> childFunctions;
    // the index we're at in the child functions of parent
    int childIndex;

    FunctionLiteral() :
        isPublic(false), isProtected(false), isStatic(false),
        isConstructor(false), isNative(false),
        isOperator(false), isCoroutine(false), isGetter(false), isSetter(false),
        hasSuperCall(false), isDefaultConstructor(false), curVarArgCalls(0), numVarArgCalls(0),
        retType(NULL), parameters(NULL), name(NULL), classDecl(NULL),
        functions(NULL), statements(NULL), methodBase(NULL),
        toperator(NULL), property(NULL), parentFunction(NULL), childIndex(-1)
    {
        astType = AST_FUNCTIONLITERAL;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }

    UTsize getFirstDefaultArg()
    {
        for (UTsize i = 0; i < defaultArguments.size(); i++)
        {
            if (defaultArguments[i])
            {
                return i;
            }
        }
        return UT_NPOS;
    }
};

class PropertyLiteral : public Expression {
public:

    utString         name;
    ClassDeclaration *classDecl;
    FunctionLiteral  *getter;
    FunctionLiteral  *setter;
    bool             isStatic;
    bool             isTemplate;

    utString typeString;

    PropertyLiteral() :
            name(),
            classDecl(NULL), getter(NULL), setter(NULL), 
            isStatic(false), isTemplate(false) 
    {
        astType = AST_PROPERTYLITERAL;
    }

    Expression *visitExpression(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class FunctionDeclaration : public Statement {
public:

    FunctionLiteral *literal;

    FunctionDeclaration(FunctionLiteral *literal)
    {
        astType = AST_FUNCTIONDECL;

        this->literal = literal;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class PropertyLiteral;
class PropertyDeclaration : public Statement {
public:

    PropertyLiteral *literal;

    PropertyDeclaration(PropertyLiteral *literal)
    {
        astType = AST_PROPERTYDECL;

        this->literal = literal;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class InterfaceDeclaration : public Statement {
public:

    Identifier *name;

    InterfaceDeclaration()
    {
        astType = AST_INTERFACEDECL;

        name = NULL;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class ClassDeclaration : public Statement {
public:

    Scope *scope;

    PackageDeclaration *pkgDecl;
    ClassDeclaration   *extendsDecl;

    FunctionLiteral *constructor;

    utArray<VariableDeclaration *> varDecls;
    utArray<FunctionLiteral *>     functionDecls;

    utArray<Statement *> *statements;

    utHashTable<utHashedString, PropertyLiteral *> properties;

    utArray<VariableDeclaration *> delegateParameters;
    Identifier *delegateReturnType;

    bool isPublic;
    bool isInterface;
    bool isStruct;
    bool isDelegate;
    bool isEnum;
    bool isStatic;
    bool isFinal;

    Identifier *name;
    utString   fullPath;
    Identifier *extends;

    Type *type;
    Type *baseType;

    utArray<Identifier *> implements;

    ClassDeclaration() :
        scope(NULL), pkgDecl(NULL), extendsDecl(NULL)
    {
        constructor = NULL;

        astType = AST_CLASSDECL;

        type     = NULL;
        baseType = NULL;

        isPublic    = false;
        isInterface = false;
        isStruct    = false;
        isDelegate  = false;
        isEnum      = false;
        isStatic    = false;
        isFinal     = false;
        statements  = NULL;
        name        = extends = NULL;
    }

    FunctionLiteral *getConstructor()
    {
        for (unsigned int i = 0; i < functionDecls.size(); i++)
        {
            if (functionDecls[i]->isConstructor)
            {
                return functionDecls[i];
            }
        }

        return NULL;
    }

    // checks whether a property getter/setter exists
    // for this declation and returns true if one does
    bool checkPropertyExists(FunctionLiteral *f)
    {
        PropertyLiteral **p = properties.get(utHashedString(f->name->string));

        if (!p)
        {
            return false;
        }

        if (f->isGetter)
        {
            return (*p)->getter != NULL && (*p)->getter->isStatic == f->isStatic;
        }

        return (*p)->setter != NULL && (*p)->setter->isStatic == f->isStatic;
    }

    PropertyLiteral *addProperty(FunctionLiteral *f, bool& newProperty)
    {
        // this the best place for renaming?
        utString name = f->name->string;
        utString ps   = f->isGetter ? "__pget_" : "__pset_";

        f->name->string = ps + f->name->string;

        newProperty = false;
        utHashedString  hs = name;
        PropertyLiteral *prop;
        PropertyLiteral **p = properties.get(hs);
        if (!p)
        {
            newProperty     = true;
            prop            = new PropertyLiteral();
            prop->name      = name; // use original name
            prop->classDecl = this;
            prop->isStatic  = f->isStatic;

            if (f->isGetter)
            {
                prop->typeString = f->retType->string;
            }
            else
            {
                assert(f->parameters && f->parameters->size());
                prop->typeString = f->parameters->at(0)->typeString;
            }

            hs = prop->name;
            properties.insert(hs, prop);
        }
        else
        {
            //TODO: ensure that get/set are same type
            prop = *p;
        }

        if (f->isGetter)
        {
            prop->getter = f;
        }
        else
        {
            prop->setter = f;
        }

        f->property = prop;

        return prop;
    }

    bool isSuperClass(ClassDeclaration *cls2)
    {
        ClassDeclaration *_extends = cls2->extendsDecl;

        while (_extends)
        {
            if (_extends == this)
            {
                return true;
            }
            _extends = _extends->extendsDecl;
        }

        return false;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }

    bool isNative()
    {
        return findMetaTag("native") != NULL;
    }

    bool isManagedNative()
    {
        return hasMetaKey("native", "managed");
    }
};

class PackageDeclaration : public Statement {
public:

    utArray<utString>    path;
    utArray<Statement *> *statements;
    utString             spath;

    // multiple classes per file, version 2
    utArray<ClassDeclaration *> clsDecls;

    utArray<ImportStatement *> imports;

    CompilationUnit *compilationUnit;

    PackageDeclaration()
    {
        astType = AST_PACKAGEDECL;

        compilationUnit = NULL;

        statements = NULL;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class ImportStatement : public Statement {
public:

    utArray<utString> path;

    utString spath;
    utString classname;
    utString fullPath;

    // allow to bring the import in as a simple identifier to solve conflicts
    // and/or to save typing
    Identifier *asIdentifier;

    Type *type;

    ImportStatement()
    {
        astType = AST_IMPORTSTATEMENT;

        asIdentifier = NULL;
        type         = NULL;
    }

    Statement *visitStatement(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};

class BuildInfo;

class CompilationUnit : public ASTNode {
public:

    BuildInfo *buildInfo;

    utString filename;

    utArray<Statement *>       *statements;
    utArray<CompilationUnit *> imports;

    utArray<utString> dependencies;

    // one class per file (version 1)
    ClassDeclaration *classDecl;

    PackageDeclaration *pkgDecl;

    utArray<ClassDeclaration *> classDecls;

    json_t *reflectionJSON;

#ifdef LOOM_ENABLE_JIT
    GCproto *proto;
#else
    Proto *proto;
#endif

    CompilationUnit()
    {
        astType        = AST_COMPILEUNIT;
        statements     = NULL;
        proto          = NULL;
        classDecl      = NULL;
        pkgDecl        = NULL;
        reflectionJSON = NULL;
        buildInfo      = NULL;
    }

    CompilationUnit *visitCompilationUnit(Visitor *visitor)
    {
        return visitor->visit(this);
    }
};
}
#endif
