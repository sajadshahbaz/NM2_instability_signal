#!/usr/bin/env python3
import argparse,csv,re,sys
from pathlib import Path
p=argparse.ArgumentParser(); p.add_argument('--metadata',required=True); p.add_argument('--fastq-dir',required=True); p.add_argument('--expected',type=int,default=111); p.add_argument('--out',required=True); a=p.parse_args()
meta=Path(a.metadata); fqdir=Path(a.fastq_dir); out=Path(a.out); out.parent.mkdir(parents=True,exist_ok=True)
if not meta.is_file(): sys.exit(f'ERROR metadata missing: {meta}')
if not fqdir.is_dir(): sys.exit(f'ERROR FASTQ directory missing: {fqdir}')
with meta.open(newline='',encoding='utf-8-sig') as f:
 r=csv.DictReader(f); fields=[x.strip() for x in (r.fieldnames or [])]; rows=list(r)
sidcol=next((x for x in ('sample_id','run','run_accession') if x in fields),None)
if not sidcol: sys.exit('ERROR metadata needs sample_id/run/run_accession')
ids=[(x.get(sidcol) or '').strip() for x in rows]; ids=[x for x in ids if x]
if len(ids)!=a.expected or len(set(ids))!=a.expected: sys.exit(f'ERROR metadata has {len(ids)} rows/{len(set(ids))} unique IDs; expected {a.expected}')
fastqs=list(fqdir.glob('*.fastq.gz'))+list(fqdir.glob('*.fq.gz'))
missing=[]; layout=[]
for s in ids:
 r1=[x for x in fastqs if re.search(rf'(^|[^A-Za-z0-9]){re.escape(s)}([^A-Za-z0-9]|$)',x.name) and re.search(r'(_1|_R1)(?:\.trimmed)?\.(fastq|fq)\.gz$',x.name)]
 r2=[x for x in fastqs if re.search(rf'(^|[^A-Za-z0-9]){re.escape(s)}([^A-Za-z0-9]|$)',x.name) and re.search(r'(_2|_R2)(?:\.trimmed)?\.(fastq|fq)\.gz$',x.name)]
 se=[x for x in fastqs if s in x.name and x not in r1+r2]
 if r1 and r2: layout.append((s,'PE',str(r1[0]),str(r2[0])))
 elif se: layout.append((s,'SE',str(se[0]),''))
 else: missing.append(s)
with out.open('w',newline='',encoding='utf-8') as f:
 w=csv.writer(f,delimiter='\t'); w.writerow(['sample_id','layout','fastq_1','fastq_2']); w.writerows(layout)
if missing: sys.exit('ERROR missing FASTQ for: '+','.join(missing))
print(f'PASS: {len(ids)} metadata samples; {len(layout)} FASTQ sample sets; manifest={out}')
