// Local static server for the Bloom Maker (so the .glb flowers in this folder load over http).
const http=require('http'),fs=require('fs'),path=require('path');
const ROOT=__dirname, PORT=8780;
const MIME={'.html':'text/html','.js':'text/javascript','.json':'application/json','.glb':'model/gltf-binary','.png':'image/png','.jpg':'image/jpeg','.css':'text/css'};
http.createServer((req,res)=>{
  let p=decodeURIComponent(req.url.split('?')[0]); if(p==='/')p='/index.html';
  const fp=path.join(ROOT,p);
  if(!fp.startsWith(ROOT)){res.writeHead(403);return res.end('no');}
  fs.readFile(fp,(e,buf)=>{
    if(e){res.writeHead(404);return res.end('not found');}
    res.writeHead(200,{'Content-Type':MIME[path.extname(fp).toLowerCase()]||'application/octet-stream','Access-Control-Allow-Origin':'*','Cache-Control':'no-store'});
    res.end(buf);
  });
}).listen(PORT,()=>console.log('Bloom Maker at http://localhost:'+PORT+'/'));
