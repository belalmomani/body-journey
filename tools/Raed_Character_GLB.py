# Raed_Character_GLB.py — يولّد Raed_Character.glb بلغة Python فقط (بلا Blender): جسم مُغطّى بهيكل عظمي،
# 12 حركة حقيقية، 6 Morph Targets للوجه، مادتان فقط. المقاييس بالمتر، Y للأعلى، الوجه نحو +Z.
import numpy as np, json, struct, math, sys
OUT = sys.argv[1] if len(sys.argv) > 1 else "Raed_Character.glb"
S = 1.20 / 2.42
FPS = 30
def to_g(p):  # Blender (x,y,z-up, front=-y) -> glTF (x,y-up, front=+z)
    p = np.asarray(p, dtype=np.float64); return np.stack([p[..., 0], p[..., 2], -p[..., 1]], -1)
COL = dict(blue=(0.025,0.16,0.55), lightblue=(0.03,0.65,0.95), red=(0.8,0.025,0.045), white=(0.88,0.92,0.98),
           skin=(0.92,0.56,0.36), hair=(0.075,0.035,0.025), dark=(0.025,0.04,0.075), glow=(0.0,0.55,1.0),
           eyew=(1,1,1), iris=(0.02,0.25,0.55), pupil=(0.005,0.008,0.015))
BONES = [("Hips",None,(0,0,1.02),(0,0,1.18)),("Spine","Hips",(0,0,1.18),(0,0,1.39)),("Chest","Spine",(0,0,1.39),(0,0,1.56)),
 ("Neck","Chest",(0,0,1.56),(0,0,1.70)),("Head","Neck",(0,0,1.70),(0,0,2.08)),
 ("LeftShoulder","Chest",(-0.20,0,1.48),(-0.32,0,1.44)),("LeftArm","LeftShoulder",(-0.32,0,1.44),(-0.44,0,1.22)),
 ("LeftForeArm","LeftArm",(-0.44,0,1.22),(-0.47,0,1.00)),("LeftHand","LeftForeArm",(-0.47,0,1.00),(-0.47,0,0.91)),
 ("RightShoulder","Chest",(0.20,0,1.48),(0.32,0,1.44)),("RightArm","RightShoulder",(0.32,0,1.44),(0.44,0,1.22)),
 ("RightForeArm","RightArm",(0.44,0,1.22),(0.47,0,1.00)),("RightHand","RightForeArm",(0.47,0,1.00),(0.47,0,0.91)),
 ("LeftUpLeg","Hips",(-0.15,0,1.02),(-0.22,0,0.65)),("LeftLeg","LeftUpLeg",(-0.22,0,0.65),(-0.22,0,0.25)),("LeftFoot","LeftLeg",(-0.22,0,0.25),(-0.22,-0.18,0.10)),
 ("RightUpLeg","Hips",(0.15,0,1.02),(0.22,0,0.65)),("RightLeg","RightUpLeg",(0.22,0,0.65),(0.22,0,0.25)),("RightFoot","RightLeg",(0.22,0,0.25),(0.22,-0.18,0.10))]
BI = {b[0]: i for i, b in enumerate(BONES)}
BPOS = [to_g(np.array(b[2]) * S) for b in BONES]   # موضع مفصل كل عظمة (عالمياً)
def superell(c, r, seg, rings, e1=1.0, e2=1.0):
    sc = lambda w, m: np.sign(np.cos(w)) * np.abs(np.cos(w)) ** m
    ss = lambda w, m: np.sign(np.sin(w)) * np.abs(np.sin(w)) ** m
    V = []
    for i in range(rings + 1):
        v = -np.pi / 2 + np.pi * i / rings
        for j in range(seg):
            u = 2 * np.pi * j / seg
            V.append((r[0]*sc(v,e1)*sc(u,e2), r[1]*sc(v,e1)*ss(u,e2), r[2]*ss(v,e1)))
    V = np.array(V) + np.array(c); T = []
    for i in range(rings):
        for j in range(seg):
            a = i*seg+j; b = i*seg+(j+1)%seg; cc = (i+1)*seg+j; d = (i+1)*seg+(j+1)%seg
            T += [(a,b,d),(a,d,cc)]
    return V*S, np.array(T)
def clean(V, T):
    G = to_g(V); keep = []
    for t in T:
        n = np.cross(G[t[1]]-G[t[0]], G[t[2]]-G[t[0]])
        if np.linalg.norm(n) > 1e-12: keep.append(t)
    return G, np.array(keep)
parts = []   # name, bone, color, G, T, emissive
def add(name, bone, color, c, r, seg=12, rings=8, e=1.0, emissive=False):
    V, T = superell(c, r, seg, rings, e, e); G, T = clean(V, T); parts.append(dict(name=name, bone=bone, color=color, G=G, T=T, em=emissive))
for s, x in (("Left", -1), ("Right", 1)):
    add(f"{s}_Thigh", f"{s}UpLeg", "blue", (x*0.22,0,0.76), (0.17,0.18,0.28))
    add(f"{s}_Shin", f"{s}Leg", "blue", (x*0.22,0,0.37), (0.13,0.14,0.25))
    add(f"{s}_Boot", f"{s}Foot", "white", (x*0.22,-0.075,0.11), (0.125,0.19,0.09), 12, 8, 0.45)
    add(f"{s}_Knee", f"{s}Leg", "dark", (x*0.22,-0.15,0.58), (0.14,0.07,0.12), 10, 6)
    add(f"{s}_UpperArm", f"{s}Arm", "blue", (x*0.40,0,1.38), (0.13,0.14,0.23))
    add(f"{s}_Shoulder", f"{s}Arm", "blue", (x*0.33,0,1.47), (0.15,0.15,0.14))
    add(f"{s}_Forearm", f"{s}ForeArm", "white", (x*0.45,-0.005,1.12), (0.105,0.12,0.20))
    add(f"{s}_Cuff", f"{s}ForeArm", "lightblue", (x*0.45,-0.005,1.02), (0.11,0.125,0.055), 10, 6)
    add(f"{s}_Glove", f"{s}Hand", "dark", (x*0.47,-0.025,0.91), (0.12,0.13,0.11))
add("Pelvis", "Hips", "blue", (0,0,1.02), (0.30,0.19,0.20)); add("Belt", "Hips", "dark", (0,-0.005,1.08), (0.32,0.205,0.055), 14, 6)
add("Torso", "Chest", "white", (0,0,1.34), (0.34,0.22,0.34), 16, 10); add("Hood", "Chest", "blue", (0,0.12,1.56), (0.27,0.17,0.16))
add("Emblem", "Chest", "red", (0,-0.214,1.37), (0.08,0.0125,0.095), 10, 6, 0.4)
add("Backpack", "Chest", "dark", (0,0.235,1.36), (0.25,0.13,0.29)); add("Pack_Ring", "Chest", "lightblue", (0,0.36,1.38), (0.16,0.025,0.17), 12, 6)
add("Pack_Core", "Chest", "glow", (0,0.355,1.38), (0.12,0.035,0.13), 12, 6, emissive=True)
add("Neck", "Neck", "skin", (0,0,1.66), (0.12,0.12,0.12), 10, 6)
add("Head", "Head", "skin", (0,-0.005,1.91), (0.31,0.285,0.34), 20, 14)
add("Hair", "Head", "hair", (0,0.035,2.105), (0.32,0.29,0.19), 16, 10); add("Helmet", "Head", "red", (0,0.025,2.20), (0.34,0.31,0.13), 18, 10)
add("Lamp", "Head", "glow", (0,-0.275,2.19), (0.075,0.045,0.055), 10, 6, emissive=True)
add("Nose", "Head", "skin", (0,-0.30,1.90), (0.04,0.045,0.06), 8, 6)
eye_parts = []
for s, x in (("L", -0.115), ("R", 0.115)):
    for nm, y, z, r, col in (("White",-0.265,1.96,(0.082,0.043,0.095),"eyew"), ("Iris",-0.305,1.955,(0.042,0.025,0.052),"iris"), ("Pupil",-0.327,1.955,(0.021,0.012,0.03),"pupil")):
        add(f"Eye{s}_{nm}", "Head", col, (x,y,z), r, 10, 6); eye_parts.append((len(parts)-1, 1.96))
brow_parts = []
for s, x in (("L", -0.115), ("R", 0.115)):
    add(f"Brow{s}", "Head", "hair", (x,-0.29,2.075), (0.075,0.025,0.018), 10, 6); brow_parts.append((len(parts)-1, -1 if s == "L" else 1))
# الفم: أنبوب على قوس؛ المعاملات تتغير في الـ Morph
MN, MR = 13, 6
def mouth(curv, opn):
    P = []
    for i in range(MN):
        t = i/(MN-1)*2-1; x = 0.09*t; zc = 1.835 + 0.03*curv*(t**2) - 0.012*curv
        rz = 0.012*(1+opn*5.0*(1-t*t)); ry = 0.012
        for k in range(MR):
            a = 2*np.pi*k/MR; P.append((x, -0.292 + ry*np.cos(a), zc + rz*np.sin(a)))
    return np.array(P)*S
mouth_T = []
for i in range(MN-1):
    for k in range(MR):
        a = i*MR+k; b = i*MR+(k+1)%MR; c = (i+1)*MR+k; d = (i+1)*MR+(k+1)%MR; mouth_T += [(a,b,d),(a,d,c)]
mouth_base = mouth(0.55, 0.0)
parts.append(dict(name="Mouth", bone="Head", color="dark", G=to_g(mouth_base), T=np.array(mouth_T), em=False)); MOUTH = len(parts)-1
# ---- تجميع الشبكتين ----
def pack(em):
    P, N, C, J, T, idx0 = [], [], [], [], [], {}
    off = 0
    for pi, p in enumerate(parts):
        if p["em"] != em: continue
        G, Tr = p["G"], p["T"]
        fn = np.cross(G[Tr[:,1]]-G[Tr[:,0]], G[Tr[:,2]]-G[Tr[:,0]]); nn = np.zeros_like(G)
        for k in range(3): np.add.at(nn, Tr[:,k], fn)
        nn /= np.maximum(np.linalg.norm(nn, axis=1, keepdims=True), 1e-12)
        P.append(G); N.append(nn); C.append(np.tile(list(COL[p["color"]])+[1.0], (len(G),1))); J.append(np.full(len(G), BI[p["bone"]]))
        T.append(Tr+off); idx0[pi] = (off, off+len(G)); off += len(G)
    return np.concatenate(P), np.concatenate(N), np.concatenate(C), np.concatenate(J), np.concatenate(T), idx0
mainP, mainN, mainC, mainJ, mainT, mainIdx = pack(False)
emP, emN, emC, emJ, emT, emIdx = pack(True)
# ---- Morph Targets (انزياحات المواضع على الشبكة الرئيسية) ----
TN = ["Smile","Surprised","Worried","Blink","Brows_Up","Mouth_Open"]
D = {n: np.zeros_like(mainP) for n in TN}
def mouth_delta(curv, opn): return to_g(mouth(curv, opn)) - to_g(mouth_base)
m0, m1 = mainIdx[MOUTH]
D["Smile"][m0:m1] = mouth_delta(1.2, 0.0); D["Worried"][m0:m1] = mouth_delta(-0.7, 0.0)
D["Surprised"][m0:m1] = mouth_delta(0.0, 1.0); D["Mouth_Open"][m0:m1] = mouth_delta(0.3, 0.8)
for pi, zc in eye_parts:
    a, b = mainIdx[pi]; Gz = mainP[a:b, 1]; D["Blink"][a:b, 1] = (zc*S - Gz) * 0.92 - 0.0  # يُطبق حول مركز العين
    D["Blink"][a:b, 1] = ((zc*S + (Gz - zc*S)*0.08) - Gz)
for pi, side in brow_parts:
    a, b = mainIdx[pi]
    D["Brows_Up"][a:b, 1] = 0.035*S*1.0; D["Surprised"][a:b, 1] = 0.045*S
    cx = mainP[a:b, 0].mean(); D["Worried"][a:b, 1] = (mainP[a:b, 0] - cx) * (-side) * 0.45 + 0.01*S
# ---- الحركات ----
def ss(x): x = min(1.0, max(0.0, x)); return x*x*(3-2*x)
def tsm(t, a, b): return ss((t-a)/(b-a))
def clip_defs():
    C = {}
    def loopsin(t, k=1.0): return math.sin(2*math.pi*t*k)
    def idle(t):
        s = loopsin(t); return {"Chest": (1.2*s,0,0), "Head": (0.8*s,2.0*loopsin(t),0), "LeftArm": (0,0,-3-1.0*s), "RightArm": (0,0,3+1.0*s)}, (0, 0.004*s, 0)
    def walk(t):
        s = loopsin(t); c = math.cos(2*math.pi*t)
        return {"LeftUpLeg": (-25*s,0,0), "RightUpLeg": (25*s,0,0), "LeftLeg": (30*max(0,c),0,0), "RightLeg": (30*max(0,-c),0,0),
                "LeftArm": (20*s,0,-3), "RightArm": (-20*s,0,3), "LeftForeArm": (-18,0,0), "RightForeArm": (-18,0,0),
                "Chest": (2,4*s,0), "Hips": (0,-4*s,0), "Head": (-2,0,0)}, (0, 0.012*math.cos(4*math.pi*t), 0)
    def run(t):
        s = loopsin(t); c = math.cos(2*math.pi*t)
        return {"LeftUpLeg": (-48*s,0,0), "RightUpLeg": (48*s,0,0), "LeftLeg": (75*max(0,c),0,0), "RightLeg": (75*max(0,-c),0,0),
                "LeftArm": (45*s,0,-6), "RightArm": (-45*s,0,6), "LeftForeArm": (-70,0,0), "RightForeArm": (-70,0,0),
                "Chest": (12,6*s,0), "Hips": (0,-6*s,0), "Head": (-6,0,0)}, (0, 0.03*abs(c)-0.015, 0)
    def turn(t):
        a = ss(t); return {"Hips": (0,90*a,0), "Head": (0,30*math.sin(math.pi*a),0)}, (0,0,0)
    def point(t):
        a = tsm(t, 0, 0.5); return {"RightArm": (-85*a,0,10*a), "RightForeArm": (-8*a,0,0), "Head": (0,-12*a,0), "Chest": (3*a,-6*a,0)}, (0,0,0)
    def joy(t):
        up = tsm(t, 0, 0.35)*(1-tsm(t, 0.7, 1.0)); h = 0.06*math.sin(math.pi*t)**2
        return {"LeftArm": (0,0,-140*up), "RightArm": (0,0,140*up), "Chest": (-8*up,0,0), "Head": (-8*up,0,0)}, (0, h, 0)
    def surprised(t):
        a = tsm(t, 0, 0.4); return {"Head": (-10*a,0,0), "Chest": (-6*a,0,0), "LeftArm": (0,0,-25*a), "RightArm": (0,0,25*a)}, (0,0,0)
    def worried(t):
        a = tsm(t, 0, 0.5); return {"Head": (8*a,0,10*a), "Chest": (4*a,0,0), "LeftArm": (0,0,6*a), "RightArm": (0,0,-6*a), "LeftForeArm": (-25*a,0,0), "RightForeArm": (-25*a,0,0)}, (0,0,0)
    def hit(t):
        a = math.sin(math.pi*t); return {"Chest": (-22*a,0,0), "Head": (-15*a,0,0), "LeftArm": (25*a,0,0), "RightArm": (25*a,0,0)}, (0,0,-0.03*a)
    def collect(t):
        a = math.sin(math.pi*t); return {"Chest": (20*a,0,0), "RightArm": (-55*a,0,0), "RightForeArm": (-30*a,0,0), "Head": (12*a,0,0)}, (0,0,0)
    def celebrate(t):
        up = tsm(t, 0, 0.25)*(1-tsm(t, 0.8, 1.0)); h = 0.05*abs(math.sin(4*math.pi*t))*up
        return {"LeftArm": (0,0,-150*up), "RightArm": (0,0,150*up), "Chest": (-6*up,0,0), "Head": (-6*up,0,0)}, (0, h, 0)
    def talk(t):
        return {"Head": (3*loopsin(t,2), 3*loopsin(t), 0), "RightArm": (-25+6*loopsin(t,3),0,3), "RightForeArm": (-40+10*loopsin(t,3),0,0), "Chest": (0,2*loopsin(t),0)}, (0,0,0)
    return [("idle",60,True,idle),("walk",32,True,walk),("run",24,True,run),("turn",24,False,turn),("point",36,False,point),("joy",30,False,joy),
            ("surprised",18,False,surprised),("worried",30,False,worried),("hit",18,False,hit),("collect",24,False,collect),("celebrate",36,False,celebrate),("talk",60,True,talk)]
def qe(rx, ry, rz):
    def q(ax, ang):
        h = math.radians(ang)/2; s = math.sin(h); v = [0,0,0]; v[ax] = s; return np.array([v[0],v[1],v[2],math.cos(h)])
    def mul(a, b):
        x1,y1,z1,w1 = a; x2,y2,z2,w2 = b
        return np.array([w1*x2+x1*w2+y1*z2-z1*y2, w1*y2-x1*z2+y1*w2+z1*x2, w1*z2+x1*y2-y1*x2+z1*w2, w1*w2-x1*x2-y1*y2-z1*z2])
    return mul(mul(q(2, rz), q(1, ry)), q(0, rx))
# ---- كتابة GLB ----
bin_ = bytearray(); bvs = []; accs = []
def bv(data, target=None):
    while len(bin_) % 4: bin_.append(0)
    o = len(bin_); bin_.extend(data); d = {"buffer":0,"byteOffset":o,"byteLength":len(data)}
    if target: d["target"] = target
    bvs.append(d); return len(bvs)-1
def acc(arr, ctype, typ, target=None, mm=False):
    arr = np.ascontiguousarray(arr); dt = {5126:np.float32, 5123:np.uint16, 5125:np.uint32, 5121:np.uint8}[ctype]
    a = arr.astype(dt); i = bv(a.tobytes(), target)
    d = {"bufferView":i,"componentType":ctype,"count":int(len(a)),"type":typ}
    if mm: d["min"] = a.reshape(len(a), -1).min(0).astype(float).tolist(); d["max"] = a.reshape(len(a), -1).max(0).astype(float).tolist()
    accs.append(d); return len(accs)-1
def prim(P, N, C, J, T, mat, with_targets):
    W = np.zeros((len(P), 4), np.float32); W[:,0] = 1; JJ = np.zeros((len(P), 4), np.uint8); JJ[:,0] = J
    p = {"attributes": {"POSITION": acc(P, 5126, "VEC3", 34962, True), "NORMAL": acc(N, 5126, "VEC3", 34962), "COLOR_0": acc(C, 5126, "VEC4", 34962),
                        "JOINTS_0": acc(JJ, 5121, "VEC4", 34962), "WEIGHTS_0": acc(W, 5126, "VEC4", 34962)},
         "indices": acc(T.reshape(-1), 5123, "SCALAR", 34963), "material": mat}
    if with_targets: p["targets"] = [{"POSITION": acc(D[n] if len(P) == len(mainP) else np.zeros_like(P), 5126, "VEC3", 34962, True)} for n in TN]
    return p
prims = [prim(mainP, mainN, mainC, mainJ, mainT, 0, True), prim(emP, emN, emC, emJ, emT, 1, True)]
nodes = [{"name": "Raed_Armature", "children": []}]
for i, b in enumerate(BONES):
    loc = BPOS[i] - (BPOS[BI[b[1]]] if b[1] else 0)
    nodes.append({"name": b[0], "translation": [float(v) for v in loc], "children": []})
for i, b in enumerate(BONES):
    (nodes[0]["children"] if b[1] is None else nodes[BI[b[1]]+1]["children"]).append(i+1)
for n in nodes:
    if not n["children"]: del n["children"]
IBM = np.zeros((len(BONES), 16), np.float32)
for i, p in enumerate(BPOS): m = np.eye(4); m[:3, 3] = -p; IBM[i] = m.T.reshape(-1)
skin = {"inverseBindMatrices": acc(IBM, 5126, "MAT4"), "joints": [i+1 for i in range(len(BONES))], "skeleton": 1}
nodes.append({"name": "Raed_Body", "mesh": 0, "skin": 0}); nodes[0].setdefault("children", []).append(len(nodes)-1)
anims = []
for name, frames, loop, fn in clip_defs():
    times = np.arange(frames+1)/FPS; ch = []; sp = []
    tacc = acc(times, 5126, "SCALAR", None, True)
    rots = {b[0]: [] for b in BONES}; hip_t = []
    for f in range(frames+1):
        t = f/frames if not loop else (f % frames)/frames
        pose, tr = fn(t)
        for b in BONES: rots[b[0]].append(qe(*pose.get(b[0], (0,0,0))))
        hip_t.append(np.array(tr, float))
    for bn in BONES:
        sp.append({"input": tacc, "output": acc(np.array(rots[bn[0]]), 5126, "VEC4"), "interpolation": "LINEAR"})
        ch.append({"sampler": len(sp)-1, "target": {"node": BI[bn[0]]+1, "path": "rotation"}})
    sp.append({"input": tacc, "output": acc(np.array(hip_t) + 0, 5126, "VEC3"), "interpolation": "LINEAR"})
    # ترجمة الورك = الموضع الأصلي + الانزياح
    base = BPOS[0]; hp = np.array([base + h for h in hip_t]); bvs[-1]; accs[-1] = accs[-1]
    sp[-1]["output"] = acc(hp, 5126, "VEC3")
    ch.append({"sampler": len(sp)-1, "target": {"node": 1, "path": "translation"}})
    anims.append({"name": name, "samplers": sp, "channels": ch})
gl = {"asset": {"version": "2.0", "generator": "Raed_Character_GLB.py"}, "scene": 0, "scenes": [{"nodes": [0]}], "nodes": nodes,
      "meshes": [{"name": "Raed_Body", "primitives": prims, "weights": [0.0]*len(TN), "extras": {"targetNames": TN}}], "skins": [skin],
      "materials": [{"name": "Raed_Body", "pbrMetallicRoughness": {"baseColorFactor": [1,1,1,1], "metallicFactor": 0.0, "roughnessFactor": 0.7}},
                    {"name": "Raed_Glow", "pbrMetallicRoughness": {"baseColorFactor": [0,0.55,1,1], "metallicFactor": 0.0, "roughnessFactor": 0.4}, "emissiveFactor": [0,0.55,1]}],
      "animations": anims, "accessors": accs, "bufferViews": bvs, "buffers": [{"byteLength": len(bin_)}]}
js = json.dumps(gl, separators=(",", ":")).encode()
while len(js) % 4: js += b" "
while len(bin_) % 4: bin_.append(0)
blob = struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(js) + 8 + len(bin_)) + struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(bin_), 0x004E4942) + bytes(bin_)
open(OUT, "wb").write(blob)
tris = len(mainT) + len(emT)
print("OK", OUT, len(blob)//1024, "KB | tris", tris, "| verts", len(mainP)+len(emP), "| bones", len(BONES), "| clips", len(anims), "| morphs", len(TN))
print("height m:", round(float(max(mainP[:,1].max(), emP[:,1].max())), 3))
