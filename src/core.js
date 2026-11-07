export const STORAGE_KEY = 'uikit-path:v1';
export function escapeHTML(value='') {
  return String(value).replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
}
export function highlight(code='') {
  const pattern = /\/\/[^\n]*|"(?:\\.|[^"\\])*"|@\w+|\b(?:import|class|struct|enum|protocol|extension|func|let|var|if|else|guard|return|throw|throws|try|await|async|actor|private|public|internal|final|override|weak|unowned|nil|true|false|self|super|init|deinit|case|switch|for|in|where|some|any|static|mutating|defer|do|catch|typealias|nonisolated)\b|\b\d+(?:\.\d+)?\b/g;
  let result='', end=0;
  for (const match of code.matchAll(pattern)) {
    result += escapeHTML(code.slice(end,match.index));
    const token=match[0];
    const type=token.startsWith('//')?'comment':token.startsWith('"')?'string':/^\d/.test(token)?'number':'keyword';
    result += `<span class="syntax-${type}">${escapeHTML(token)}</span>`;
    end=match.index+token.length;
  }
  return result+escapeHTML(code.slice(end));
}
export function emptyProgress() {return {version:1,completed:[],exercises:{},quiz:{},notes:{},drafts:{},labDraft:null};}
export function normalizeProgress(input) {
  if (!input || input.version!==1 || typeof input!=='object') throw new Error('Choose a UIKit Path version 1 progress file.');
  const clean=emptyProgress();
  clean.completed=[...new Set((Array.isArray(input.completed)?input.completed:[]).filter(n=>Number.isInteger(n)&&n>=1&&n<=20))];
  for(const field of ['notes','drafts','exercises']) {
    if (!input[field] || typeof input[field]!=='object' || Array.isArray(input[field])) continue;
    for (const [key,value] of Object.entries(input[field])) {
      if(!/^[\w-]{1,80}$/.test(key) || ['__proto__','constructor','prototype'].includes(key)) continue;
      if (field==='exercises' && typeof value==='boolean') clean[field][key]=value;
      else if (field!=='exercises' && typeof value==='string' && value.length<=100000) clean[field][key]=value;
    }
  }
  if(input.quiz && typeof input.quiz==='object') for(const [key,q] of Object.entries(input.quiz)) {
    if(!/^([1-9]|1\d|20)$/.test(key)||!q||typeof q!=='object') continue;
    const answers=Array.from({length:5},(_,i)=>Number.isInteger(q.answers?.[i])&&q.answers[i]>=0&&q.answers[i]<4?q.answers[i]:null);
    clean.quiz[key]={answers,checked:q.checked===true&&answers.every(a=>a!==null),best:Number.isInteger(q.best)?Math.max(0,Math.min(5,q.best)):0};
  }
  if(typeof input.labDraft==='string'&&input.labDraft.length<=100000)clean.labDraft=input.labDraft;
  return clean;
}
export function quizScore(questions,answers) {return questions.reduce((sum,q,i)=>sum+(q.answer===answers[i]?1:0),0);}
export function routeFromHash(hash) {
  const parts=hash.replace(/^#\/?/,'').split('/');
  if(parts[0]==='day') {
    const day=Number(parts[1]);
    if(!Number.isInteger(day)||day<1||day>20)return {page:'not-found'};
    const tab=['lesson','example','practice','quiz','notes'].includes(parts[2])?parts[2]:'lesson';
    return {page:'day',day,tab};
  }
  return {page:['lab','setup'].includes(parts[0])?parts[0]:parts[0]?'not-found':'home'};
}
export const LAB_TEMPLATE = `import UIKit

final class ProfileViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Build something good."
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Small steps. Real UIKit skills."
        subtitleLabel.numberOfLines = 0

        let button = UIButton(type: .system)
        button.setTitle("Start learning", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, button])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }
}`;
const COLORS = {systemGreen:'#22834d',systemBlue:'#0068d9',systemOrange:'#a54d00',systemIndigo:'#5754c9',systemPink:'#c62457',systemRed:'#c8342b',black:'#151b19'};
export function parseLab(code) {
  const text=(name,fallback)=> {
    const m=code.match(new RegExp(name+'\\.text\\s*=\\s*("(?:[^"\\\\]|\\\\.)*")'));
    if(!m)return fallback;
    try{return JSON.parse(m[1])}catch{return fallback}
  };
  const number=(pattern,fallback,min,max)=>Math.min(max,Math.max(min,Number(code.match(pattern)?.[1]??fallback)));
  const color=code.match(/button\.backgroundColor\s*=\s*\.(\w+)/)?.[1]??'systemGreen';
  let button='Start learning';
  try{const match=code.match(/button\.setTitle\(\s*("(?:[^"\\]|\\.)*")/);if(match)button=JSON.parse(match[1]);}catch{}
  return {title:text('titleLabel','Build something good.'),subtitle:text('subtitleLabel','Small steps. Real UIKit skills.'),button,color:COLORS[color]??COLORS.systemGreen,colorName:color,fontSize:number(/titleLabel\.font\s*=\s*\.systemFont\(ofSize:\s*(\d+)/,26,12,48),spacing:number(/stack\.spacing\s*=\s*(\d+)/,20,0,60),radius:number(/button\.layer\.cornerRadius\s*=\s*(\d+)/,12,0,32),axis:code.match(/stack\.axis\s*=\s*\.horizontal/)?'row':'column'};
}
