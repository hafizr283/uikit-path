// Run only in an isolated QA browser through agent-browser eval -b <base64>.
// Exercises public DOM interactions. Leaves QA progress for the reload check.
(async () => {
  const checks=[];
  const assert=(condition,message)=>{if(!condition)throw new Error(message);checks.push(message);};
  const frame=()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve)));
  const go=async hash=>{location.hash=hash;await frame();};
  const input=(selector,value)=>{const el=document.querySelector(selector);if(!el)throw new Error('Missing '+selector);el.value=value;el.dispatchEvent(new Event('input',{bubbles:true}));return el;};
  for(let day=1;day<=20;day++){
    for(const tab of ['lesson','example','practice','quiz','notes']){
      await go(`/day/${day}/${tab}`);
      if(!document.title.startsWith(`Day ${String(day).padStart(2,'0')}:`))throw new Error('Wrong day title '+day);
      const selector={lesson:'.teaching-section',example:'.code-block',practice:'.exercise',quiz:'.quiz-question',notes:'#day-notes'}[tab];
      const expected={lesson:5,example:1,practice:3,quiz:5,notes:1}[tab];
      if(document.querySelectorAll(selector).length!==expected)throw new Error(`Incomplete ${day}/${tab}`);
    }
  }
  checks.push('All 100 lesson section routes render their complete content');
  await go('/day/1/notes');
  const journal='QA: value semantics <img src=x onerror=window.bad=true>';
  input('#day-notes',journal);
  await go('/day/1/practice');
  const draft='// QA draft\nlet title = "A useful app"';
  const editor=input('#draft-0',draft);
  document.querySelector('input[data-exercise]').click();
  document.querySelector('.solution summary').click();
  assert(document.querySelector('.solution').open,'Worked solutions expand on request');
  await go('/day/1/notes');
  assert(document.querySelector('#day-notes').value===journal,'Journal survives navigation and renders as text');
  assert(!window.bad,'Journal content cannot execute HTML');
  await go('/day/1/practice');
  assert(document.querySelector('#draft-0').value===draft,'Swift draft survives navigation');
  assert(document.querySelector('input[data-exercise]').checked,'Practice completion survives navigation');
  await go('/day/1/quiz');
  document.querySelector('[data-retake]')?.click();
  const lesson=await fetch('./content/day-01.json').then(r=>r.json());
  for(let i=0;i<5;i++)document.querySelector(`input[name=q${i}][value="${lesson.quiz[i].answer}"]`).click();
  document.querySelector('#quiz-form').requestSubmit();
  assert(document.querySelector('#quiz-result strong').textContent.trim()==='5 / 5','Correct quiz attempt scores five out of five');
  assert(document.querySelectorAll('.answer-explanation').length===5,'Every quiz answer has explained feedback');
  document.querySelector('[data-retake]').click();
  for(let i=0;i<5;i++)document.querySelector(`input[name=q${i}][value="${(lesson.quiz[i].answer+1)%4}"]`).click();
  document.querySelector('#quiz-form').requestSubmit();
  assert(document.querySelector('#quiz-result strong').textContent.trim()==='0 / 5','Wrong quiz attempt scores zero');
  assert(document.querySelector('.quiz-best').textContent.includes('5 / 5'),'Retaking a quiz keeps the best score');
  const complete=document.querySelector('[data-complete]');
  if(!complete.textContent.includes('undo'))complete.click();
  await go('/');
  assert(document.querySelector('.hero-actions .primary').getAttribute('href')==='#/day/2/lesson','Resume points to the next incomplete day');
  input('#topic-search','zzzz-not-a-topic');
  assert(document.querySelector('.search-empty'),'Search shows an empty state');
  input('#topic-search','Auto Layout');
  assert(document.querySelector('#curriculum').textContent.includes('Auto Layout'),'Search locates a relevant topic');
  input('#topic-search','');
  await go('/lab');
  const initial=document.querySelector('#lab-editor').value;
  input('#lab-editor',initial.replace(/titleLabel\.text\s*=\s*"[^"\n]*"/,'titleLabel.text = "My real learning lab"').replace(/stack\.spacing\s*=\s*\d+/,'stack.spacing = 32'));
  document.querySelector('[data-preview]').click();
  assert(document.querySelector('#phone-content h2').textContent==='My real learning lab','UI preview reads the edited Swift title');
  assert(document.querySelector('#phone-content').style.gap==='32px','UI preview reads stack spacing');
  input('#lab-spacing','16');
  assert(document.querySelector('#lab-editor').value.includes('stack.spacing = 16'),'Inspector edits source and preview together');
  document.querySelector('#illustrated-button').click();
  assert(document.querySelector('#preview-feedback').textContent.includes('visual preview'),'Illustrated button never pretends to execute Swift');
  const saved=JSON.parse(localStorage.getItem('uikit-path:v1'));
  assert(saved.completed.includes(1)&&saved.notes['1']===journal&&saved.quiz['1'].best===5,'Completed work and journal are persisted to local storage');
  await go('/day/21');
  assert(document.querySelector('h1').textContent.includes('isn’t on this path'),'Invalid lesson links have a recovery page');
  await go('/');
  return {status:'passed',routeCount:100,checks};
})()
