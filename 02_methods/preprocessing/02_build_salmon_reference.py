#!/usr/bin/env python3
"""Build Salmon reference from genome FASTA + GFF/GTF.
Paper-specific cleaned implementation: CDS-joined transcript reconstruction, tx2gene,
gentrome, decoys, and Salmon index. Historical settings: Salmon k=31.
"""
import argparse,gzip,re,subprocess,sys
from collections import defaultdict
from pathlib import Path

def op(p,m='rt'): return gzip.open(p,m) if str(p).endswith('.gz') else open(p,m)
def revcomp(s): return s.translate(str.maketrans('ACGTNacgtn','TGCANtgcan'))[::-1]
def fasta(path):
 d={}; k=None; b=[]
 with op(path) as f:
  for z in f:
   z=z.strip()
   if not z: continue
   if z.startswith('>'):
    if k: d[k]=''.join(b)
    k=z[1:].split()[0]; b=[]
   else: b.append(z)
  if k: d[k]=''.join(b)
 return d
def attrs(s):
 d={}
 for x in s.strip().split(';'):
  x=x.strip()
  if not x: continue
  if '=' in x: k,v=x.split('=',1); d[k]=v
  elif ' ' in x:
   k,v=x.split(' ',1); d[k]=v.strip().strip('"')
 return d
def main():
 p=argparse.ArgumentParser(); p.add_argument('--genome',required=True); p.add_argument('--annotation',required=True); p.add_argument('--out-dir',required=True); p.add_argument('--prefix',default='Rvar'); p.add_argument('--threads',type=int,default=8); p.add_argument('--k',type=int,default=31); a=p.parse_args()
 out=Path(a.out_dir); out.mkdir(parents=True,exist_ok=True); genome=fasta(a.genome)
 cds=defaultdict(list); txgene={}; mrna_gene={}
 with op(a.annotation) as f:
  for line in f:
   if not line.strip() or line.startswith('#'): continue
   q=line.rstrip('\n').split('\t');
   if len(q)<9: continue
   seqid,_,typ,st,en,_,strand,_,at=q; A=attrs(at); typ=typ.lower()
   if typ in ('mrna','transcript'):
    tx=A.get('ID') or A.get('transcript_id'); g=A.get('gene_id') or A.get('Parent')
    if tx and g: mrna_gene[tx]=g
   if typ!='cds': continue
   tx=A.get('transcript_id') or A.get('Parent') or A.get('ID'); g=A.get('gene_id') or mrna_gene.get(tx,'')
   if not tx: continue
   cds[tx].append((seqid,int(st),int(en),strand));
   if g: txgene[tx]=g
 txseq={}
 for tx,bl in cds.items():
  sid={x[0] for x in bl}; sd={x[3] for x in bl}
  if len(sid)!=1 or len(sd)!=1: continue
  bl=sorted(bl,key=lambda x:x[1]); seq=''.join(genome[x[0]][x[1]-1:x[2]] for x in bl)
  if bl[0][3]=='-': seq=revcomp(seq)
  txseq[tx]=seq
 txfa=out/f'{a.prefix}.transcripts.fa'; tx2=out/f'{a.prefix}.tx2gene.tsv'; dec=out/f'{a.prefix}.decoys.txt'; gent=out/f'{a.prefix}.gentrome.fa'; idx=out/f'{a.prefix}.salmon_index'
 with txfa.open('w') as f:
  for k,v in txseq.items(): f.write(f'>{k}\n'+ '\n'.join(v[i:i+60] for i in range(0,len(v),60))+'\n')
 with tx2.open('w') as f:
  for k in txseq: f.write(f'{k}\t{txgene.get(k,"")}\n')
 with dec.open('w') as f:
  for k in genome: f.write(k+'\n')
 with gent.open('w') as f:
  for src in (txseq,genome):
   for k,v in src.items(): f.write(f'>{k}\n'+'\n'.join(v[i:i+60] for i in range(0,len(v),60))+'\n')
 subprocess.run(['salmon','index','-t',str(gent),'-d',str(dec),'-i',str(idx),'-k',str(a.k),'--threads',str(a.threads)],check=True)
 print(f'PASS: transcripts={len(txseq)} index={idx}')
if __name__=='__main__': main()
