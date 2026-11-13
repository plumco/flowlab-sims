with open('web/sims/visualizer-embedded.html', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_block = [
    '  const i=fl.sim-1,p=O.tgt[i],y=O.y[i],sl=O.seal[i],lost=sl<25;\n',
    '  const on=TL.act.includes(fl.sim)&&(TL.mode==="hold"||e0>.05);\n',
    '  if(on){\n',
    '   const Lb=polyLen(fl.br);\n',
    '   const alpha=TL.mode==="hold"?0.95:Math.max(0.65,Math.min(1,e0*1.25));\n',
    '   ln(c,fl.br,"rgba(56,189,248,"+(0.6*alpha)+")",lod>0?1.3:1.8);\n',
    '   const nd=Math.max(5,Math.round(Lb/10));\n',
    '   for(let kk=0;kk<nd;kk++){\n',
    '     const ph=(TL.t*TL.speed*50/Lb+kk/nd)%1,pt=polyAt(fl.br,ph*Lb);\n',
    '     if(pt){c.fillStyle="#38bdf8";c.globalAlpha=alpha;c.beginPath();c.arc(pt[0],pt[1],lod>0?.95:.8,0,7);c.fill();c.globalAlpha=1}\n',
    '   }\n',
    '   fl.fx.forEach(([t,x,yy])=>{c.fillStyle="#38bdf8";c.globalAlpha=alpha*.85;c.beginPath();c.ellipse(x,yy+(t==="wb"?3:5),t==="wb"?5:3.6,t==="wb"?2.6:3.6,0,0,7);c.fill();c.globalAlpha=1});\n',
    '  }\n',
    '  if(lod>0){\n',
    '   glow(c,fl.jn[0],fl.jn[1],p);const col=lost?"#ff6b6b":cv2(y);c.fillStyle=col;c.beginPath();c.arc(fl.jn[0],fl.jn[1],lod>1?3:2,0,7);c.fill();\n',
    '   if(on)ci(c,fl.jn[0],fl.jn[1],lod>1?5.5:3.6,"#38bdf8",.9);\n',
    '   if(fl.sim%LK===0||fl.sim===N||fl.sim===1)txt(c,"F"+fl.sim,g.x1-1,fl.t-LS*.6,{s:LS,a:"right",c:col});\n',
    '   return;\n',
    '  }\n'
]

# Find index of g.floors.forEach
target_idx = None
for idx, line in enumerate(lines):
    if 'g.floors.forEach' in line:
        target_idx = idx
        break

if target_idx is not None:
    # lines target_idx + 2 is const i=fl.sim-1...
    start = target_idx + 2
    # End is where glow(c,fl.jn[0] was after return
    # Find next glow
    end = None
    for j in range(start, start + 20):
        if 'glow(c,fl.jn[0]' in lines[j] and 'lod>0' not in lines[j-1]:
            end = j
            break
    if end is not None:
        lines[start:end] = new_block
        with open('web/sims/visualizer-embedded.html', 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f'Successfully replaced lines {start} to {end} in web/sims/visualizer-embedded.html')
    else:
        print('Could not find end line')
else:
    print('Could not find g.floors.forEach')
