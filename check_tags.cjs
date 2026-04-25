const fs = require('fs');
const content = fs.readFileSync('src/pages/RiskManagement.tsx', 'utf8');

let lineNum = 1;
let tags = [];
const regex = /<\/?([a-zA-Z0-9]+)[^>]*>/g;
let match;

while ((match = regex.exec(content)) !== null) {
  const tagStr = match[0];
  const tagName = match[1];
  
  // Count lines up to this match
  const linesBefore = content.substring(0, match.index).split('\n').length;
  
  // Ignore self-closing tags
  if (tagStr.endsWith('/>')) continue;
  
  // Ignore some components that might be self-closing but we missed it, or just focus on standard HTML tags
  if (['input', 'img', 'br', 'hr'].includes(tagName.toLowerCase())) continue;
  
  if (tagStr.startsWith('</')) {
    if (tags.length > 0 && tags[tags.length - 1].name === tagName) {
      tags.pop();
    } else {
      console.log(`Mismatch at line ${linesBefore}: found </${tagName}> but expected </${tags.length > 0 ? tags[tags.length - 1].name : 'nothing'}>`);
    }
  } else {
    tags.push({ name: tagName, line: linesBefore });
  }
}

console.log('Unclosed tags:');
tags.forEach(t => console.log(`${t.name} at line ${t.line}`));
