import React,{useCallback,useEffect,useMemo,useState} from 'react';
import {supabase} from './lib/supabase';
import {App} from './main.jsx';

const palette=['#e29b46','#4b9b88','#7765d5','#75a567','#438bd1','#c27aa3','#dc7590','#a17e60'];
const localISO=d=>`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
export default function StudentCloudDashboard({session,profile,enrollment,onSignOut}){
 const [deadlines,setDeadlines]=useState([]),[subjects,setSubjects]=useState([]),[progress,setProgress]=useState([]),[error,setError]=useState(''),[loading,setLoading]=useState(true),[revision,setRevision]=useState(0);
 const sectionCode=enrollment?.sections?.code||'Section';
 const load=useCallback(async()=>{
  const [d,s,p]=await Promise.all([
   supabase.from('deadlines').select('*').eq('section_id',enrollment.section_id).order('due_at',{ascending:true}),
   supabase.from('section_subjects').select('subjects(id,code,name)').eq('section_id',enrollment.section_id),
   supabase.from('deadline_progress').select('deadline_id,status').eq('student_id',session.user.id)
  ]);
  const problems=[d.error,s.error,p.error].filter(Boolean).map(x=>x.message);
  setError(problems.join(' · '));setDeadlines(d.data||[]);setSubjects((s.data||[]).map(x=>x.subjects).filter(Boolean));setProgress(p.data||[]);setLoading(false);
 },[enrollment.section_id,session.user.id]);
 useEffect(()=>{load();const channel=supabase.channel(`classflow-student-${session.user.id}`).on('postgres_changes',{event:'*',schema:'public',table:'deadlines'},()=>load()).on('postgres_changes',{event:'*',schema:'public',table:'deadline_progress',filter:`student_id=eq.${session.user.id}`},()=>load()).subscribe();return()=>{supabase.removeChannel(channel)}},[load]);
 const subjectsById=useMemo(()=>Object.fromEntries(subjects.map((s,i)=>[s.id,{id:s.code,name:s.name,short:s.code,color:palette[i%palette.length]}])),[subjects]);
 const profileData=useMemo(()=>({name:profile?.full_name||session.user.email?.split('@')[0]||'Student',role:'student',verified:true,program:enrollment.branch_code==='MNC'?'Mathematics & Computing':enrollment.branch_code==='ECE'?'Electronics & Communication':enrollment.branch_code==='EE'?'Electrical Engineering':'Computer Science',className:sectionCode+' Section',semester:'Semester 1',year:'2026–27',initials:sectionCode,subjects:subjects.map(s=>subjectsById[s.id])}),[profile,session.user.email,enrollment.branch_code,sectionCode,subjects,subjectsById,deadlines]);
 const statusById=useMemo(()=>Object.fromEntries(progress.map(p=>[p.deadline_id,p.status])),[progress]);
 const tasks=useMemo(()=>deadlines.map(d=>{const date=new Date(d.due_at);return {id:d.id,subject:subjectsById[d.subject_id]?.id||'UNKNOWN',title:d.title,description:d.description||'',due:localISO(date),time:`${String(date.getHours()).padStart(2,'0')}:${String(date.getMinutes()).padStart(2,'0')}`,status:statusById[d.id]==='completed'?'done':statusById[d.id]==='in_progress'?'progress':'pending',tier:d.size||'medium',estimate:d.estimated_hours||6,source:'Official · Cloud',official:true,files:[]}}),[deadlines,subjectsById,statusById]);
 const updateProgress=async(id,status)=>{
  const translated=status==='done'?'completed':status==='progress'?'in_progress':'not_started';
  const {error:err}=await supabase.from('deadline_progress').upsert({deadline_id:id,student_id:session.user.id,status:translated,updated_at:new Date().toISOString()},{onConflict:'deadline_id,student_id'});
  if(err)setError(err.message);else await load();
 };
 if(loading)return <div className="student-cloud-loading">Loading your section's cloud deadlines…</div>;
 return <><div className="student-cloud-alert" role="status">{error?`Cloud sync error: ${error}`:''}</div><App cloud={{tasks,profile:profileData,onProgress:updateProgress,onRefresh:()=>{setRevision(x=>x+1);load()},onSignOut}} key={`${session.user.id}-${revision}`}/></>;
}
