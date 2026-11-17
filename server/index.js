import http from 'node:http';
import crypto from 'node:crypto';
import { WebSocketServer, WebSocket } from 'ws';
const PORT = Number(process.env.PORT || 10000);
const MAX_PLAYERS = 20;
const rooms = new Map();
const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
function code() { let c; do { c = Array.from({length:6},()=>alphabet[crypto.randomInt(alphabet.length)]).join(''); } while(rooms.has(c)); return c; }
const send = (ws,obj)=> { if(ws.readyState===WebSocket.OPEN) ws.send(JSON.stringify(obj)); };
const broadcast = (room,obj,except)=> { for(const p of room.values()) if(p.ws!==except) send(p.ws,obj); };
const server=http.createServer((req,res)=>{res.writeHead(200,{'Content-Type':'application/json'});res.end(JSON.stringify({status:'ok',rooms:rooms.size}));});
const wss=new WebSocketServer({server,maxPayload:4096});
wss.on('connection',ws=>{
 let current=null, id=crypto.randomUUID();
 const leave=()=>{ if(!current)return; const room=rooms.get(current); if(room){room.delete(id);broadcast(room,{type:'left',id});if(!room.size)rooms.delete(current);}current=null; };
 ws.on('message',raw=>{
  let msg;try{msg=JSON.parse(raw.toString());}catch{return send(ws,{type:'error',message:'Invalid JSON'});}
  if(!msg || typeof msg.type!=='string')return;
  if(msg.type==='create'){
   leave();const c=code();rooms.set(c,new Map([[id,{ws,x:0,y:2,z:0,yaw:0}]]));current=c;
   return send(ws,{type:'joined',code:c,id,players:[{id,x:0,y:2,z:0,yaw:0}]});
  }
  if(msg.type==='join'){
   const c=String(msg.code||'').trim().toUpperCase();const room=rooms.get(c);
   if(!room)return send(ws,{type:'error',message:'Code inconnu'});
   if(room.size>=MAX_PLAYERS)return send(ws,{type:'error',message:'Salon complet'});
   leave();const players=[...room.entries()].map(([pid,p])=>({id:pid,x:p.x,y:p.y,z:p.z,yaw:p.yaw}));
   room.set(id,{ws,x:0,y:2,z:0,yaw:0});current=c;
   send(ws,{type:'joined',code:c,id,players:[...players,{id,x:0,y:2,z:0,yaw:0}]});
   return broadcast(room,{type:'entered',id,x:0,y:2,z:0,yaw:0},ws);
  }
  if(msg.type==='move' && current){
   const room=rooms.get(current);const p=room?.get(id);if(!p)return;
   const nums=['x','y','z','yaw'].map(k=>Number(msg[k]));
   if(nums.some(n=>!Number.isFinite(n)||Math.abs(n)>10000))return;
   [p.x,p.y,p.z,p.yaw]=nums;
   broadcast(room,{type:'moved',id,x:p.x,y:p.y,z:p.z,yaw:p.yaw},ws);
  }
 });
 ws.on('close',leave);ws.on('error',()=>{});
});
server.listen(PORT,'0.0.0.0',()=>console.log('Lobby server listening on',PORT));
