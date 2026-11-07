import {readFile,readdir} from 'node:fs/promises';
import assert from 'node:assert/strict';
export async function loadLessons(){
  const files=(await readdir(new URL('../content/',import.meta.url))).filter(f=>/^day-\d\d\.json$/.test(f)).sort();
  assert.equal(files.length,20,'Exactly 20 lesson files are required.');
  return Promise.all(files.map(f=>readFile(new URL('../content/'+f,import.meta.url),'utf8').then(JSON.parse)));
}
export function validateLessons(lessons){
  for(const [i,l]of lessons.entries()){
    const context=`Day ${i+1}`;
    assert.equal(l.day,i+1,context+' must be in order');
    for(const key of ['title','subtitle','phase','duration'])assert.equal(typeof l[key],'string',context+' '+key);
    for(const key of ['objectives','prerequisites','pitfalls','checkpoint']){assert.ok(Array.isArray(l[key])&&l[key].length>0,context+' '+key);assert.ok(l[key].every(v=>typeof v==='string'&&v.trim()),context+' '+key+' strings');}
    assert.ok(l.sections.length>=5,context+' teaching sections');
    for(const section of l.sections){assert.ok(section.title&&section.body?.length,context+' teaching section content');assert.ok(section.body.every(p=>typeof p==='string'&&p.length>30),context+' substantive paragraphs');}
    for(const key of ['title','filename','code','expectedOutput'])assert.ok(typeof l.example[key]==='string'&&l.example[key].trim(),context+' example '+key);
    assert.ok(l.example.walkthrough.length>=3,context+' walkthrough');
    assert.match(l.example.filename,/^[\w. -]+$/,context+' safe example filename');
    assert.equal(l.exercises.length,3,context+' exercises');
    const ids=new Set();
    for(const x of l.exercises){assert.match(x.id,/^[\w-]+$/);assert.ok(!ids.has(x.id),context+' unique exercises');ids.add(x.id);for(const key of ['title','difficulty','prompt','starterCode','solution','explanation'])assert.ok(typeof x[key]==='string'&&x[key].trim(),context+' exercise '+key);for(const key of ['requirements','hints','checks'])assert.ok(Array.isArray(x[key])&&x[key].length,context+' exercise '+key);}
    assert.equal(l.quiz.length,5,context+' quiz questions');
    for(const q of l.quiz){assert.equal(q.options.length,4,context+' quiz options');assert.equal(new Set(q.options).size,4,context+' distinct options');assert.ok(Number.isInteger(q.answer)&&q.answer>=0&&q.answer<4,context+' quiz answer');assert.ok(q.question.length>10&&q.explanation.length>30,context+' quiz explanation');}
    assert.ok(l.capstone.title&&l.capstone.steps.length>=2,context+' capstone');
    assert.ok(l.references.length>=2,context+' references');
    for(const r of l.references){const u=new URL(r.url);assert.equal(u.protocol,'https:');assert.ok(['developer.apple.com','docs.swift.org','www.swift.org','swift.org','help.apple.com','support.apple.com','docs.github.com','github.com'].includes(u.hostname),context+' official source '+u.hostname);}
  }
  return {days:lessons.length,sections:lessons.reduce((s,l)=>s+l.sections.length,0),exercises:lessons.reduce((s,l)=>s+l.exercises.length,0),questions:lessons.reduce((s,l)=>s+l.quiz.length,0)};
}
if(process.argv[1]&&import.meta.url.endsWith(process.argv[1].replaceAll('\\','/').split('/').pop())){
 const summary=validateLessons(await loadLessons());console.log('Course content validated:',JSON.stringify(summary));
}
