import React,{useMemo,useState} from 'react';
import './planner.css';
const iso=d=>`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
const fromISO=s=>{const [y,m,d]=s.split('-').map(Number);return new Date(y,m-1,d)};
const shift=(date,days)=>{const d=new Date(date);d.setDate(d.getDate()+days);return d};
const monday=d=>shift(d,-((d.getDay()+6)%7));
const monthTitle=d=>d.toLocaleDateString(undefined,{month:'long',year:'numeric'});
const dayTitle=d=>d.toLocaleDateString(undefined,{weekday:'long',day:'numeric',month:'long',year:'numeric'});
const statusLabel={not_started:'Not started',in_progress:'In progress',completed:'Completed'};
export default function CloudPlanner({deadlines,progress,subjects,sections,canTrack,onProgress}){
 const [view,setView]=useState('calendar'),[scale,setScale]=useState('month'),[anchor,setAnchor]=useState(iso(new Date())),[selected,setSelected]=useState(iso(new Date()));
 const active=fromISO(anchor),start=scale==='week'?monday(active):new Date(active.getFullYear(),active.getMonth(),1);
 const end=scale==='week'?shift(start,6):new Date(active.getFullYear(),active.getMonth()+1,0);
 const first=scale==='month'?monday(start):start;
 const last=scale==='month'?shift(end,6-(end.getDay()+6)%7):end;
 const dates=[];for(let d=new Date(first);d<=last;d=shift(d,1))dates.push(iso(d));
 const byDate=useMemo(()=>{const out={};deadlines.forEach(d=>{const day=iso(new Date(d.due_at));(out[day]??=[]).push(d)});return out},[deadlines]);
 const progressById=useMemo(()=>Object.fromEntries(progress.map(p=>[p.deadline_id,p.status])),[progress]);
 const status=d=>progressById[d.id]||'not_started';
 const subject=id=>{const s=subjects.find(x=>x.id===id);return s?.code||s?.name||'Subject'};
 const section=id=>sections.find(x=>x.id===id)?.code||'Section';
 const move=n=>{const d=scale==='week'?shift(active,n*7):new Date(active.getFullYear(),active.getMonth()+n,Math.min(active.getDate(),28));setAnchor(iso(d));setSelected(iso(d))};
 const today=()=>{const d=iso(new Date());setAnchor(d);setSelected(d)};
 const total=dates.reduce((a,day)=>a+(byDate[day]?.length||0),0);
 const completed=dates.reduce((a,day)=>a+(byDate[day]||[]).filter(d=>status(d)==='completed').length,0);
 const pending=total-completed;
 const chosen=byDate[selected]||[];
 return <section className="cloud-panel planner-panel"><div className="planner-top"><div><h3>Cloud calendar & workload</h3><p>Live deadlines from Supabase. Completed tasks stay visible.</p></div><div className="planner-switch"><button className={view==='calendar'?'selected':''} onClick={()=>setView('calendar')}>Calendar</button><button className={view==='heatmap'?'selected':''} onClick={()=>setView('heatmap')}>Heatmap</button></div></div>
 <div className="planner-toolbar"><div className="planner-switch"><button className={scale==='week'?'selected':''} onClick={()=>setScale('week')}>Week</button><button className={scale==='month'?'selected':''} onClick={()=>setScale('month')}>Month</button></div><div className="planner-nav"><button aria-label="Previous period" onClick={()=>move(-1)}>←</button><strong>{scale==='month'?monthTitle(active):`${start.toLocaleDateString()} – ${end.toLocaleDateString()}`}</strong><button aria-label="Next period" onClick={()=>move(1)}>→</button><button onClick={today}>Today</button></div></div>
 <div className="planner-summary"><span>{total} deadlines</span><span>{completed} completed</span><span>{pending} remaining</span></div>
 <div className="planner-grid">{['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map(x=><div className="planner-weekday" key={x}>{x}</div>)}{dates.map(day=>{const items=byDate[day]||[],done=items.filter(d=>status(d)==='completed').length,overdue=items.filter(d=>status(d)!=='completed'&&new Date(d.due_at)<new Date()).length;const intensity=items.length?Math.min(4,items.length):0;return <button key={day} title={`${day}: ${items.length} deadlines, ${done} completed`} onClick={()=>setSelected(day)} className={`planner-day ${day===selected?'active':''} ${day===iso(new Date())?'today':''} ${scale==='month'&&fromISO(day).getMonth()!==active.getMonth()?'outside':''} ${view==='heatmap'?'heat-'+intensity:''}`}><span className="planner-date">{fromISO(day).getDate()}</span>{view==='calendar'?<div className="planner-chips">{items.slice(0,3).map(d=><span className={`planner-chip ${status(d)}`} key={d.id}>{subject(d.subject_id)} · {d.title}</span>)}{items.length>3&&<small>+{items.length-3} more</small>}</div>:<div className="planner-cell-stats">{items.length?`${done}/${items.length} done`:'—'}{overdue>0&&<span className="planner-overdue">{overdue} overdue</span>}</div>}</button>})}</div>
 <div className="planner-detail"><h4>{dayTitle(fromISO(selected))} · {chosen.length} deadline{chosen.length===1?'':'s'}</h4>{!chosen.length?<p>No shared deadlines due on this date.</p>:chosen.map(d=><article className="planner-item" key={d.id}><div><small>{section(d.section_id)} · {subject(d.subject_id)} · {d.size}</small><strong>{d.title}</strong><p>{d.description}</p><small>Due {new Date(d.due_at).toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'})} · {d.estimated_hours} estimated hours</small></div>{canTrack?<label>My progress<select value={status(d)} onChange={e=>onProgress(d.id,e.target.value)}>{Object.entries(statusLabel).map(([v,l])=><option key={v} value={v}>{l}</option>)}</select></label>:<span>{statusLabel[status(d)]}</span>}</article>)}</div>
 <p className="planner-footnote">This view shows live cloud deadlines only. The separate offline demo timetable and college holidays are not yet migrated.</p></section>
}
