import {mkdir,writeFile,cp,readFile} from 'node:fs/promises';
import {loadLessons,validateLessons} from './validate.mjs';
const lessons=await loadLessons();const counts=validateLessons(lessons);
const pad=n=>String(n).padStart(2,'0');
const list=items=>items.map(x=>'- '+x).join('\n');
const ordered=items=>items.map((x,i)=>`${i+1}. ${x}`).join('\n');
const fence=(code,language='swift')=>'```'+language+'\n'+code+'\n```';
await Promise.all(['lessons','examples','exercises','solutions','dist'].map(d=>mkdir(d,{recursive:true})));
for(const l of lessons){
  const day='day-'+pad(l.day);
  let md=`# Day ${pad(l.day)}: ${l.title}\n\n${l.subtitle}\n\n**Time:** ${l.duration} · **Target:** Swift 6 / iOS 17+\n\n[Interactive lesson](http://hafizr283.me/uikit-path/#/day/${l.day}/lesson) · [Course overview](../README.md)\n\n## Outcomes\n\n${list(l.objectives)}\n\n## Before you begin\n\n${list(l.prerequisites)}\n\n`;
  md+=l.sections.map(s=>`## ${s.title}\n\n${s.body.join('\n\n')}\n\n${s.code?fence(s.code)+'\n\n':''}`).join('');
  md+=`## Worked example: ${l.example.title}\n\n**File:** ${l.example.filename}\n\n${fence(l.example.code,l.example.filename.endsWith('.sh')?'bash':'swift')}\n\n### Walkthrough and setup\n\n${ordered(l.example.walkthrough)}\n\n**Expected behavior:** ${l.example.expectedOutput}\n\n`;
  md+=l.exercises.map((x,i)=>`## Challenge ${i+1}: ${x.title}\n\n**Level:** ${x.difficulty}\n\n${x.prompt}\n\n### Requirements\n\n${list(x.requirements)}\n\n### Starter\n\n${fence(x.starterCode)}\n\n<details>\n<summary>Hints</summary>\n\n${list(x.hints)}\n\n</details>\n\n### Acceptance checks\n\n${list(x.checks)}\n\n<details>\n<summary>Worked solution</summary>\n\n${fence(x.solution)}\n\n${x.explanation}\n\n</details>\n\n`).join('');
  md+='## Knowledge check\n\n'+l.quiz.map((q,i)=>`### ${i+1}. ${q.question}\n\n${q.options.map((o,j)=>`${String.fromCharCode(65+j)}. ${o}`).join('\n\n')}\n\n<details>\n<summary>Answer and explanation</summary>\n\n**${String.fromCharCode(65+q.answer)}. ${q.options[q.answer]}**\n\n${q.explanation}\n\n</details>\n\n`).join('');
  md+=`## Common pitfalls\n\n${list(l.pitfalls)}\n\n## PocketTasks milestone: ${l.capstone.title}\n\n${ordered(l.capstone.steps)}\n\n## Before you move on\n\n${list(l.checkpoint)}\n\n## Official references\n\n${l.references.map(r=>`- [${r.title}](${r.url})`).join('\n')}\n\n## Reflection\n\n- What can I now explain without the example?\n- What did I build and test in Xcode?\n- Which bug or design tradeoff do I want to revisit?\n`;
  await writeFile(`lessons/${day}.md`,md);
  await Promise.all(['examples','exercises','solutions'].map(d=>mkdir(`${d}/${day}`,{recursive:true})));
  const setup=l.example.walkthrough.map(s=>'// '+s).join('\n');
  await writeFile(`examples/${day}/${l.example.filename}`,l.example.filename.endsWith('.swift')?`// Day ${pad(l.day)}: ${l.title}\n// Independent educational example. Read lessons/${day}.md for setup.\n${setup}\n\n${l.example.code}\n`:l.example.code+'\n');
  for(const [i,x]of l.exercises.entries()){
    const filename=`Challenge${i+1}.swift`;
    await writeFile(`exercises/${day}/${filename}`,`// ${x.title}\n// ${x.prompt}\n// See lessons/${day}.md for requirements, hints, and acceptance checks.\n// Independent exercise; do not add all course files to one Xcode target.\n\n${x.starterCode}\n`);
    await writeFile(`solutions/${day}/${filename}`,`// Worked solution: ${x.title}\n// ${x.explanation}\n// Read lessons/${day}.md for any surrounding types or setup.\n\n${x.solution}\n`);
  }
}
await cp('index.html','dist/index.html');
await cp('src','dist/src',{recursive:true});
await cp('content','dist/content',{recursive:true});
await writeFile('dist/.nojekyll','');
await writeFile('dist/build-info.json',JSON.stringify({version:JSON.parse(await readFile('package.json','utf8')).version,...counts},null,2)+'\n');
console.log(`Built course: ${counts.days} days, ${counts.sections} sections, ${counts.exercises} exercises, ${counts.questions} questions. Static output: dist/`);
