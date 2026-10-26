#!/usr/bin/env node
'use strict';

// Fact source: aura-web-develop. Review ships an identical standalone copy.
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const args = process.argv.slice(2);
const report = { scope: [], files: [], errors: [], semanticReview: 'required', status: 'incomplete' };
let project;
let output;
let fileArgs = [];
let ts;

function fail(message) { report.errors.push(message); }
function main() {
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--project' || arg === '--output') {
      if (!args[i + 1] || args[i + 1].startsWith('--')) { fail(`Missing value: ${arg}`); continue; }
      if (arg === '--project') project = path.resolve(args[++i]);
      else output = path.resolve(args[++i]);
    } else if (arg === '--files') {
      const start = ++i;
      while (i < args.length && !args[i].startsWith('--')) fileArgs.push(args[i++]);
      if (i === start) fail('--files requires explicit TS/TSX paths');
      i--;
    } else fail(`Unknown argument: ${arg}`);
  }
  if (!project) fail('--project is required');
  if (!fileArgs.length) fail('--files is required; no discovery is performed');
  report.project = project;
  report.scope = fileArgs.map(file => path.resolve(project || process.cwd(), file));
  // realpath also prevents overwriting an input through symlinks or case aliases.
  const identity = file => {
    let resolved = path.resolve(file);
    try { resolved = fs.realpathSync(resolved); } catch { /* Missing path is reported below. */ }
    return process.platform === 'win32' ? resolved.toLowerCase() : resolved;
  };
  if (output && report.scope.some(file => identity(file) === identity(output))) {
    fail('--output must not overwrite any input source');
    output = undefined;
  }
  if (project) {
    try {
      const packagePath = path.join(project, 'package.json');
      if (!fs.existsSync(packagePath)) throw new Error('project package.json not found');
      ts = createRequire(packagePath)('typescript');
      report.typescriptVersion = ts.version;
    } catch (error) { fail(`Cannot load project-installed TypeScript: ${error.message}`); }
  }
  for (const file of report.scope) {
    const result = { path: file, status: 'incomplete', fields: 0, methods: 0, parameters: 0, issues: [], incomplete: [], externalTypes: [] };
    report.files.push(result);
    if (!/\.(?:ts|tsx)$/i.test(file)) { result.incomplete.push('Only explicit .ts/.tsx files are supported'); continue; }
    let source;
    try { source = fs.readFileSync(file, 'utf8'); }
    catch (error) { result.incomplete.push(error.message); continue; }
    if (!ts) { result.incomplete.push('TypeScript unavailable'); continue; }
    const sf = ts.createSourceFile(file, source, ts.ScriptTarget.Latest, true, /\.tsx$/i.test(file) ? ts.ScriptKind.TSX : ts.ScriptKind.TS);
    const location = node => ({ line: sf.getLineAndCharacterOfPosition(node.getStart(sf)).line + 1, column: sf.getLineAndCharacterOfPosition(node.getStart(sf)).character + 1 });
    const issue = (node, code, name, message) => result.issues.push({ path: file, ...location(node), code, name, message });
    if (sf.parseDiagnostics.length) {
      for (const diagnostic of sf.parseDiagnostics) result.incomplete.push({ line: sf.getLineAndCharacterOfPosition(diagnostic.start || 0).line + 1, message: ts.flattenDiagnosticMessageText(diagnostic.messageText, '\n') });
      continue;
    }
    function comments(node, trailing = true) {
      const start = node.getStart(sf);
      const leading = (ts.getLeadingCommentRanges(source, node.getFullStart()) || []).filter(range => {
        const lineStart = source.lastIndexOf('\n', range.pos - 1) + 1;
        return /^\s*$/.test(source.slice(lineStart, range.pos)) && /^\s*$/.test(source.slice(range.end, start).replace(/\/\*[\s\S]*?\*\/|\/\/[^\n]*/g, ''));
      });
      // EnumMember.end excludes its comma. Advance only over that member's
      // same-line separator; the comment scanner still stops at another token.
      const separator = ts.isEnumMember(node) ? source.slice(node.end).match(/^[ \t]*,/) : null;
      const tailStart = separator ? node.end + separator[0].length : node.end;
      const tail = trailing ? (ts.getTrailingCommentRanges(source, tailStart) || []).filter(range => !/[\r\n]/.test(source.slice(node.end, range.pos))) : [];
      return [...leading, ...tail].map(range => source.slice(range.pos, range.end)).join('\n');
    }
    function chinese(text) {
      // Machine metadata cannot stand in for a business description.
      return /[\u3400-\u9fff]/.test(text.replace(/@(?:dictKey|type|see|link|default|example|deprecated)\b[^\r\n]*/g, ''));
    }
    const nameOf = node => node.name ? node.name.getText(sf) : '[index]';
    function method(node, owner) {
      const methodName = node.name ? nameOf(node) : node.parent && node.parent.name ? nameOf(node.parent) : nameOf(owner);
      result.methods++;
      result.parameters += node.parameters.length;
      const doc = comments(owner, false);
      const jsdoc = /\/\*\*[\s\S]*?\*\//g;
      const blocks = doc.match(jsdoc) || [];
      const contract = blocks.join('\n');
      const description = contract.split(/@\w+/)[0];
      const tagText = contract.replace(/\r?\n[ \t]*\*[ \t]?/g, '\n');
      if (!chinese(description)) issue(owner, 'method-description', methodName, 'Missing Chinese JSDoc purpose');
      for (const parameter of node.parameters) {
        if (!ts.isIdentifier(parameter.name)) {
          result.incomplete.push({ ...location(parameter), message: 'Destructured method parameters require manual contract review' });
          continue;
        }
        const escaped = parameter.name.text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        const match = tagText.match(new RegExp('@param\\s+(?:\\{[^}]*\\}\\s*)?(?:\\[' + escaped + '(?:=[^\\]]*)?\\]|' + escaped + ')(?=\\s|$)[ \\t]*([^@]*)'));
        if (!match || !chinese(match[1])) issue(parameter, 'parameter-description', parameter.name.text, 'Missing own Chinese @param description');
      }
      const returns = tagText.match(/@returns?\s+([^@]*)/);
      if (!returns || !chinese(returns[1])) issue(owner, 'return-description', methodName, 'Missing Chinese @returns description (including void completion semantics)');
      if (/@(?:param|returns?|throws)\b[^\r\n]*@(?:param|returns?|throws)\b/.test(contract) || /\/\*\*[^\r\n]*@(?:param|returns?|throws)\b/.test(contract) || !/\r?\n[ \t]*\*[ \t]*\r?\n[ \t]*\*[ \t]*@/.test(contract)) issue(owner, 'jsdoc-layout', methodName, 'Separate purpose and contract tags with a blank JSDoc line; each tag must occupy its own line');
    }
    function visit(node) {
      const parameterProperty = ts.isParameter(node) && node.modifiers && node.modifiers.some(modifier => [ts.SyntaxKind.PublicKeyword, ts.SyntaxKind.PrivateKeyword, ts.SyntaxKind.ProtectedKeyword, ts.SyntaxKind.ReadonlyKeyword].includes(modifier.kind));
      if (ts.isPropertySignature(node) || ts.isPropertyDeclaration(node) || ts.isMethodSignature(node) || ts.isIndexSignatureDeclaration(node) || ts.isEnumMember(node) || parameterProperty) {
        result.fields++;
        if (!chinese(comments(node))) issue(node, 'field-description', nameOf(node), 'Missing own adjacent Chinese field description');
        if (node.name && ts.isComputedPropertyName(node.name) && !ts.isStringLiteral(node.name.expression) && !ts.isNumericLiteral(node.name.expression)) result.incomplete.push({ ...location(node), message: 'Dynamic computed field identity requires manual review' });
      }
      if (node.members && (ts.isInterfaceDeclaration(node) || ts.isTypeLiteralNode(node) || ts.isClassDeclaration(node) || ts.isClassExpression(node) || ts.isEnumDeclaration(node))) {
        const names = new Set();
        for (const member of node.members) {
          if (!ts.isPropertySignature(member) && !ts.isPropertyDeclaration(member) && !ts.isEnumMember(member)) continue;
          let name = nameOf(member);
          if (member.name && (ts.isStringLiteral(member.name) || ts.isNumericLiteral(member.name))) name = member.name.text;
          if (member.name && ts.isComputedPropertyName(member.name) && (ts.isStringLiteral(member.name.expression) || ts.isNumericLiteral(member.name.expression))) name = member.name.expression.text;
          const key = `${member.modifiers && member.modifiers.some(modifier => modifier.kind === ts.SyntaxKind.StaticKeyword) ? 'static:' : ''}${name}`;
          if (names.has(key)) issue(member, 'duplicate-property', name, 'Duplicate property in the same declaration container');
          names.add(key);
        }
      }
      if (ts.isMappedTypeNode(node)) result.incomplete.push({ ...location(node), message: 'Mapped type fields cannot be enumerated by this structural checker' });
      if (ts.isHeritageClause(node) || ts.isImportDeclaration(node)) result.externalTypes.push({ ...location(node), declaration: node.getText(sf), review: 'Resolve actual inherited/imported declarations manually; not followed by this checker' });
      if ((ts.isFunctionDeclaration(node) && node.name && node.body) || (ts.isMethodDeclaration(node) && node.body) || ts.isGetAccessorDeclaration(node) || ts.isSetAccessorDeclaration(node)) method(node, node);
      if ((ts.isVariableDeclaration(node) || ts.isPropertyDeclaration(node)) && node.initializer && (ts.isArrowFunction(node.initializer) || ts.isFunctionExpression(node.initializer))) {
        // Variable JSDoc belongs to the statement, property JSDoc to the property.
        const owner = ts.isVariableDeclaration(node) && ts.isVariableDeclarationList(node.parent) ? node.parent.parent : node;
        method(node.initializer, owner);
      }
      ts.forEachChild(node, visit);
    }
    visit(sf);
    result.status = result.incomplete.length ? 'incomplete' : result.issues.length ? 'missing' : 'structure-complete';
  }
  report.status = report.errors.length || report.files.some(file => file.status === 'incomplete') ? 'incomplete' : report.files.some(file => file.issues.length) ? 'missing' : 'structure-complete';
}
try { main(); } catch (error) { fail(error.message); report.status = 'incomplete'; }
let rendered = JSON.stringify(report, null, 2) + '\n';
if (output) {
  try { fs.writeFileSync(output, rendered, { flag: 'wx' }); }
  catch (error) {
    fail(`Cannot create --output (existing files are never overwritten): ${error.message}`);
    report.status = 'incomplete';
    rendered = JSON.stringify(report, null, 2) + '\n';
  }
}
process.stdout.write(rendered);
process.exitCode = report.status === 'incomplete' ? 2 : report.status === 'missing' ? 1 : 0;
