const fs=require('fs'),vm=require('vm'),path=require('path');
const p=path.join(__dirname,'lab.html');
const h=fs.readFileSync(p,'utf8');
const re=/<script\b([^>]*)>([\s\S]*?)<\/script>/gi; let m,i=0,bad=0;
while((m=re.exec(h))){ if(/\bsrc=/i.test(m[1]||''))continue; i++; try{ new vm.Script(m[2],{filename:'lab'+i}); }catch(e){ bad++; console.log('ERR: '+e.message); } }
console.log('lab.html inline scripts: '+i+', errors: '+bad);
