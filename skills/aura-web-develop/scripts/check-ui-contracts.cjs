#!/usr/bin/env node
'use strict';

// Only compiler APIs are loaded. Locale modules and project configuration code are never executed.
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const report = { errors: [], incomplete: [] };
try {
  const input = JSON.parse(fs.readFileSync(process.argv[2], 'utf8').replace(/^\uFEFF/, ''));
  const projectRequire = createRequire(path.join(input.project, 'package.json'));
  const ts = projectRequire('typescript');
  const normalize = (file) => path.resolve(file).replace(/\\/g, '/');
  const sources = new Map(input.sources.map((source) => [normalize(source.path), source.content]));
  const selected = new Set(input.selected.map(normalize));
  const relative = (file) => path.relative(input.project, file).replace(/\\/g, '/');
  const asts = new Map();
  const parse = (file, text) => ts.createSourceFile(file, text, ts.ScriptTarget.Latest, true, ts.ScriptKind.TS);
  const walk = (node, visit) => { visit(node); ts.forEachChild(node, (child) => walk(child, visit)); };
  const unwrap = (node) => {
    while (node && (ts.isParenthesizedExpression(node) || ts.isAsExpression(node) || ts.isSatisfiesExpression(node) || ts.isTypeAssertionExpression(node))) node = node.expression;
    return node;
  };
  const propertyName = (node) => {
    if (node && ts.isComputedPropertyName(node)) {
      node = unwrap(node.expression);
      return node && (ts.isStringLiteralLike(node) || ts.isNumericLiteral(node)) ? node.text : undefined;
    }
    return node && (ts.isIdentifier(node) || ts.isStringLiteralLike(node) || ts.isNumericLiteral(node)) ? node.text : undefined;
  };
  const unknown = () => ({ properties: new Map(), uncertain: true, leaf: false });
  const object = () => ({ properties: new Map(), uncertain: false, leaf: false });
  const clone = (value) => ({ ...value, properties: new Map([...value.properties].map(([key, child]) => [key, clone(child)])) });

  // Resolve local static declarations, including namespace members, without following imports.
  function localeIndex(ast) {
    const declarations = new Map();
    function collect(statements, prefix = '') {
      for (const statement of statements) {
        if (prefix && !statement.modifiers?.some((modifier) => modifier.kind === ts.SyntaxKind.ExportKeyword)) continue;
        if (ts.isVariableStatement(statement)) {
          for (const declaration of statement.declarationList.declarations) {
            if (ts.isIdentifier(declaration.name) && declaration.initializer) declarations.set(prefix + declaration.name.text, declaration.initializer);
          }
        } else if (ts.isModuleDeclaration(statement) && statement.body && ts.isModuleBlock(statement.body)) {
          collect(statement.body.statements, prefix + statement.name.text + '.');
        }
      }
    }
    collect(ast.statements);
    const mutated = new Set();
    const rootName = (node) => {
      node = unwrap(node);
      while (node && (ts.isPropertyAccessExpression(node) || ts.isElementAccessExpression(node))) node = unwrap(node.expression);
      return node && ts.isIdentifier(node) ? node.text : undefined;
    };
    walk(ast, (node) => {
      if (ts.isBinaryExpression(node) && node.operatorToken.kind >= ts.SyntaxKind.FirstAssignment && node.operatorToken.kind <= ts.SyntaxKind.LastAssignment) mutated.add(rootName(node.left));
      if (ts.isDeleteExpression(node) || ((ts.isPrefixUnaryExpression(node) || ts.isPostfixUnaryExpression(node)) && [ts.SyntaxKind.PlusPlusToken, ts.SyntaxKind.MinusMinusToken].includes(node.operator))) mutated.add(rootName(node.expression || node.operand));
      if (ts.isCallExpression(node)) for (const argument of node.arguments) mutated.add(rootName(argument));
    });
    function evaluate(expression, seen = new Set()) {
      expression = unwrap(expression);
      if (!expression) return unknown();
      if (ts.isIdentifier(expression) || ts.isPropertyAccessExpression(expression)) {
        const name = expression.getText(ast);
        if (mutated.has(name.split('.')[0])) return unknown();
        if (declarations.has(name) && !seen.has(name)) return evaluate(declarations.get(name), new Set([...seen, name]));
        if (ts.isPropertyAccessExpression(expression)) {
          const parent = evaluate(expression.expression, seen);
          return parent.properties.get(expression.name.text) || unknown();
        }
        // A namespace can itself be the default export.
        const members = [...declarations].filter(([key]) => key.startsWith(name + '.') && !key.slice(name.length + 1).includes('.'));
        if (members.length && !seen.has(name)) {
          const result = object();
          for (const [key, value] of members) result.properties.set(key.slice(name.length + 1), evaluate(value, new Set([...seen, name])));
          return result;
        }
        return unknown();
      }
      if (ts.isObjectLiteralExpression(expression)) {
        const result = object();
        for (const property of expression.properties) {
          if (ts.isSpreadAssignment(property)) {
            const spread = evaluate(property.expression, seen);
            // An unknown spread may overwrite every preceding property.
            if (spread.uncertain) { result.properties.clear(); result.uncertain = true; }
            for (const [key, value] of spread.properties) result.properties.set(key, clone(value));
          } else {
            const key = propertyName(property.name);
            if (key === undefined) { result.properties.clear(); result.uncertain = true; continue; }
            result.properties.set(key, ts.isPropertyAssignment(property) ? evaluate(property.initializer, seen) : ts.isShorthandPropertyAssignment(property) ? evaluate(property.name, seen) : unknown());
          }
        }
        return result;
      }
      if (ts.isStringLiteralLike(expression) || ts.isNumericLiteral(expression) || [ts.SyntaxKind.TrueKeyword, ts.SyntaxKind.FalseKeyword, ts.SyntaxKind.NullKeyword].includes(expression.kind)) return { ...object(), leaf: true };
      return unknown();
    }
    const exported = ast.statements.find((statement) => ts.isExportAssignment(statement) && !statement.isExportEquals);
    return exported && !ast.parseDiagnostics.length ? evaluate(exported.expression) : unknown();
  }
  const locales = { 'zh-cn': [], en: [] };
  for (const [file, text] of sources) {
    if (!file.endsWith('.vue')) asts.set(file, parse(file, text));
    const language = path.basename(file, '.ts');
    if (Object.hasOwn(locales, language)) locales[language].push(localeIndex(asts.get(file)));
  }
  function TestI18nKeyExists(index, key) {
    if (index.properties.has(key)) {
      const value = index.properties.get(key);
      return value.uncertain ? 'unknown' : 'exists';
    }
    let current = index;
    for (const segment of key.split('.')) {
      if (!current.properties.has(segment)) return current.uncertain ? 'unknown' : 'missing';
      current = current.properties.get(segment);
    }
    return current.uncertain ? 'unknown' : 'exists';
  }
  const keyCache = new Map();
  function checkKey(file, call) {
    const argument = call.arguments[0];
    if (!argument || !ts.isStringLiteralLike(argument)) {
      report.incomplete.push(`${relative(file)}：动态 i18n key 无法静态核实，待人工核对`);
      return;
    }
    const key = argument.text;
    if (!keyCache.has(key)) {
      const states = Object.entries(locales).map(([language, indexes]) => {
        const candidates = indexes.map((index) => TestI18nKeyExists(index, key));
        return [language, candidates.includes('exists') ? 'exists' : !indexes.length || candidates.includes('unknown') ? 'unknown' : 'missing'];
      });
      keyCache.set(key, states);
    }
    for (const [language, state] of keyCache.get(key)) {
      if (state === 'missing') report.errors.push(`${relative(file)}：i18n key ${key} 未在 ${language}.ts 中存在`);
      if (state === 'unknown') report.incomplete.push(`${relative(file)}：i18n key ${key} 在 ${language}.ts 中无法静态确认（缺失语言包、动态表达式或导入），待人工核对`);
    }
  }

  // API declarations are context, never additional rule-scan targets.
  const dictFields = new Map();
  function dictTags(member) {
    return ts.getJSDocTags(member).filter((tag) => tag.tagName.text === 'dictKey').map((tag) => typeof tag.comment === 'string' ? tag.comment.trim().split(/\s+/)[0] : '').filter(Boolean);
  }
  for (const [file, ast] of asts) {
    if (!relative(file).startsWith('src/api/')) continue;
    walk(ast, (node) => {
      if (!ts.isPropertySignature(node) && !ts.isPropertyDeclaration(node)) return;
      const name = propertyName(node.name);
      for (const key of dictTags(node)) {
        if (!dictFields.has(name + 'Name')) dictFields.set(name + 'Name', new Set());
        dictFields.get(name + 'Name').add(key);
      }
    });
  }
  let sfc;
  const templates = new Map();
  for (const file of selected) {
    if (!sources.has(file)) continue;
    if (!file.endsWith('.vue')) continue;
    try {
      sfc ||= projectRequire('@vue/compiler-sfc');
      const parsed = sfc.parse(sources.get(file), { filename: file });
      if (parsed.errors.length) throw new Error('Vue SFC 解析失败');
      const descriptor = parsed.descriptor;
      asts.set(file + '.ts', parse(file + '.ts', [descriptor.script?.content, descriptor.scriptSetup?.content].filter(Boolean).join('\n')));
      templates.set(file, descriptor.template?.ast);
    } catch (error) {
      report.incomplete.push(`${relative(file)}：Vue 静态解析不可用：${error.message}`);
    }
  }
  let checker;
  function getChecker() {
    if (checker) return checker;
    // Bound the graph to the supplied API/selected ASTs; never traverse npm or request/runtime imports.
    const roots = [...asts.keys()].filter((file) => relative(file).startsWith('src/api/') || selected.has(file) || selected.has(file.slice(0, -3)));
    const allowed = new Set(roots);
    const options = { noLib: true, noResolve: true, module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.Latest, skipLibCheck: true };
    const host = ts.createCompilerHost(options);
    host.getSourceFile = (file) => allowed.has(normalize(file)) ? asts.get(normalize(file)) : undefined;
    host.fileExists = (file) => allowed.has(normalize(file));
    host.readFile = (file) => host.getSourceFile(file)?.text;
    host.resolveModuleNames = (names, containingFile) => names.map((name) => {
      const base = name.startsWith('/@/') ? path.join(input.project, 'src', name.slice(3)) : name.startsWith('.') ? path.resolve(path.dirname(containingFile), name) : undefined;
      if (!base) return undefined;
      const resolved = [base, base + '.ts', path.join(base, 'index.ts')].map(normalize).find((file) => allowed.has(file));
      return resolved ? { resolvedFileName: resolved, extension: ts.Extension.Ts } : undefined;
    });
    checker = ts.createProgram(roots, options, host).getTypeChecker();
    return checker;
  }

  function inspect(file, ast, bindings, allowDict, template = false, display = false) {
    function expressionType(expression) {
      if (ts.isIdentifier(expression)) {
        const binding = bindings.get(template ? expression.text : checker.getSymbolAtLocation(expression));
        if (binding) return binding.type;
      }
      if (ts.isPropertyAccessExpression(expression)) {
        if (expression.name.text === 'value' && ts.isIdentifier(expression.expression)) {
          const binding = bindings.get(template ? expression.expression.text : checker.getSymbolAtLocation(expression.expression));
          if (binding?.ref) return binding.type;
        }
        const parent = expressionType(expression.expression);
        const symbol = parent && checker.getPropertyOfType(parent, expression.name.text);
        if (symbol) return checker.getTypeOfSymbolAtLocation(symbol, symbol.valueDeclaration || symbol.declarations?.[0] || expression);
      }
      if (ast === asts.get(file) || ast === asts.get(file + '.ts')) return checker.getTypeAtLocation(expression);
      return undefined;
    }
    walk(ast, (node) => {
      if (ts.isCallExpression(node) && ts.isIdentifier(node.expression) && ['t', '$t'].includes(node.expression.text)) checkKey(file, node);
      if (!allowDict || !ts.isPropertyAccessExpression(node) || !dictFields.has(node.name.text)) return;
      const field = node.name.text.slice(0, -4);
      const type = expressionType(node.expression);
      const symbol = type && checker.getPropertyOfType(type, field);
      const keys = (symbol?.declarations || []).flatMap(dictTags);
      if (keys.length && display) report.errors.push(`${relative(file)}：已绑定类型的 @dictKey ${keys.join('/')} 字段 ${field} 直接展示 ${node.name.text}；请使用字典组件`);
      else if (keys.length) report.incomplete.push(`${relative(file)}：@dictKey ${keys.join('/')} 的 ${node.name.text} 读取未确认用于展示，待人工核对展示/非展示边界`);
      else if (!type || (type.flags & (ts.TypeFlags.Any | ts.TypeFlags.Unknown)) || !checker.getPropertiesOfType(type).length) report.incomplete.push(`${relative(file)}：${node.name.text} 与 @dictKey 字段同名，但未绑定到声明类型；候选待人工核对`);
    });
  }
  for (const file of selected) {
    const ast = asts.get(file + '.ts') || asts.get(file);
    if (!ast) continue;
    if (ast.parseDiagnostics.length) report.incomplete.push(`${relative(file)}：源码语法无法完整静态解析`);
    const bindings = new Map();
    const allowDict = file.endsWith('.vue') && relative(file).startsWith('src/views/') && [...dictFields.keys()].some((name) => sources.get(file).includes(name));
    if (allowDict) getChecker();
    // Explicit types and ref<T>/reactive<T> arguments are compiler Type objects, not name matches.
    walk(ast, (node) => {
      if (!allowDict || !(ts.isVariableDeclaration(node) || ts.isParameter(node)) || !ts.isIdentifier(node.name)) return;
      let typeNode = node.type;
      if (!typeNode && node.initializer && ts.isCallExpression(node.initializer) && ts.isIdentifier(node.initializer.expression) && ['ref', 'shallowRef', 'reactive', 'shallowReactive'].includes(node.initializer.expression.text)) typeNode = node.initializer.typeArguments?.[0];
      if (typeNode) {
        const binding = { type: checker.getTypeFromTypeNode(typeNode), ref: !node.type && ['ref', 'shallowRef'].includes(node.initializer?.expression?.text) };
        bindings.set(checker.getSymbolAtLocation(node.name), binding);
        if (ts.isVariableDeclaration(node) && ts.isVariableDeclarationList(node.parent) && ts.isVariableStatement(node.parent.parent) && ts.isSourceFile(node.parent.parent.parent)) bindings.set(node.name.text, binding);
      }
    });
    inspect(file, ast, bindings, allowDict);
    function templateWalk(node, inheritedBindings = bindings) {
      if (!node) return;
      const localBindings = new Map(inheritedBindings);
      // v-for/slot aliases shadow setup variables. Unbound aliases stay candidates instead of borrowing a type by name.
      for (const prop of node.props || []) {
        if (prop.type !== 7 || !['for', 'slot'].includes(prop.name) || !prop.exp?.content) continue;
        const aliases = prop.name === 'for' ? prop.exp.content.split(/\s+(?:in|of)\s+/)[0] : prop.exp.content;
        for (const name of aliases.match(/[A-Za-z_$][\w$]*/g) || []) localBindings.delete(name);
      }
      if (node.type === 5 && node.content?.content) inspect(file, parse('template.ts', node.content.content), localBindings, allowDict, true, true);
      for (const prop of node.props || []) {
        if (prop.type === 7 && prop.exp?.content) inspect(file, parse('template.ts', prop.exp.content), localBindings, allowDict, true, prop.name === 'bind' && ['label', 'title', 'content', 'description', 'placeholder'].includes(prop.arg?.content));
        if (allowDict && prop.type === 6 && prop.name === 'prop' && dictFields.has(prop.value?.content)) report.incomplete.push(`${relative(file)}：表格 prop=${prop.value.content} 与 @dictKey 字段同名，行类型未静态绑定；候选待人工核对`);
      }
      for (const child of node.children || []) templateWalk(child, localBindings);
    }
    templateWalk(templates.get(file));
  }
} catch (error) {
  report.incomplete.push(`静态 UI 分析不可用：${error.message}`);
}
report.errors = [...new Set(report.errors)];
report.incomplete = [...new Set(report.incomplete)];
process.stdout.write(JSON.stringify(report));
