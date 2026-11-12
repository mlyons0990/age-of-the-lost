"""Plot analytic engine exports, not observed encounter or hardware timings."""
from pathlib import Path
import argparse,csv,os,tempfile
os.environ.setdefault('MPLCONFIGDIR',str(Path(tempfile.gettempdir())/'aotl-matplotlib-cache'))
os.environ.setdefault('XDG_CACHE_HOME',str(Path(tempfile.gettempdir())/'aotl-plot-cache'))
Path(os.environ['MPLCONFIGDIR']).mkdir(parents=True,exist_ok=True)
Path(os.environ['XDG_CACHE_HOME']).mkdir(parents=True,exist_ok=True)
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parent.parent)
 args=parser.parse_args();project=args.project.resolve()
 with (project/'data/mastery_balance_snapshot.csv').open() as f:rows=list(csv.DictReader(f))
 out=project/'docs/figures';out.mkdir(exist_ok=True)
 profiles=[('ungeared','Ungeared','#425b86'),('midpoint_common_staff','Common staff','#2a9d8f'),('staff_and_emberwake','Staff + circlet','#d18b26'),('staff_emberwake_full_mastery','Staff + circlet + full mastery','#b64b45')]
 fig,axes=plt.subplots(1,2,figsize=(11.4,4.6),layout='constrained')
 for key,label,color in profiles:
  data=sorted((r for r in rows if r['loadout']==key and int(r['level'])>=40),key=lambda r:int(r['level']))
  x=[int(r['level']) for r in data]
  axes[0].plot(x,[float(r['aura_noncrit_dps']) for r in data],marker='o',label=label,color=color,linewidth=2)
  if key in ['ungeared','staff_emberwake_full_mastery']:
   axes[1].plot(x,[float(r['net_mana_per_second']) for r in data],marker='o',label='Base aura' if key=='ungeared' else 'Full mastery',color=color,linewidth=2)
 axes[0].set_title('Nominal aura damage');axes[0].set_ylabel('Damage per second (non-crit)')
 axes[1].set_title('Mana pressure without generators');axes[1].set_ylabel('Natural recovery − upkeep (mana/s)')
 axes[1].axhline(0,color='#555',linestyle='--',linewidth=1)
 for ax in axes:
  ax.set_xlabel('Mage level');ax.set_xticks([40,45,50,55,60]);ax.grid(alpha=.2);ax.legend(fontsize=8)
 fig.suptitle('Crownsfall mastery tuning · engine-exported analytic checkpoints',fontsize=13)
 fig.supxlabel('Selected Pyromancer; midpoint common staff. Full mastery spends earned points. Other casts, crit/variance, movement and mitigation excluded.',fontsize=8)
 fig.savefig(out/'mastery_balance.png',dpi=180)
 fig.savefig(out/'mastery_balance.pdf')
 print('Created analytic balance PNG/PDF from',len(rows),'checkpoints')

if __name__=='__main__':main()
