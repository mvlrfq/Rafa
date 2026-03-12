const embed = {
  sun: function(selectorParent,dbesarInti,dtebalSinar,dcepatRotasi,arah,dwarnaInti,dwarnaSinar) {
  let cn = selectorParent.replaceAll(/[# .]/g, "")
const matahari = '<div class="sun-container'+cn+'"><svg class="sun-beams'+cn+'" viewBox="0 0 100 100" preserveAspectRatio="none"><defs><path id="beam-path" d="M 50,0 C 45,10 55,10 50,20 C 45,30 55,30 50,40" /></defs><use href="#beam-path" transform="rotate(0 50 50)" /><use href="#beam-path" transform="rotate(30 50 50)" /><use href="#beam-path" transform="rotate(60 50 50)" /><use href="#beam-path" transform="rotate(90 50 50)" /><use href="#beam-path" transform="rotate(120 50 50)" /><use href="#beam-path" transform="rotate(150 50 50)" /><use href="#beam-path" transform="rotate(180 50 50)" /><use href="#beam-path" transform="rotate(210 50 50)" /><use href="#beam-path" transform="rotate(240 50 50)" /><use href="#beam-path" transform="rotate(270 50 50)" /><use href="#beam-path" transform="rotate(300 50 50)" /><use href="#beam-path" transform="rotate(330 50 50)" /></svg><div class="sun-core'+cn+'"></div></div>'
document.querySelector(selectorParent).innerHTML += matahari
let head = document.querySelector('head')
if (dbesarInti) {
  if (typeof dbesarInti === "string"){
 dbesarInti = dbesarInti
  } else {
    alert('error : parameter embed.sun(harus string)')
    return
  }
} else {
  dbesarInti = '80px'
}
if (dcepatRotasi) {
  if (typeof dcepatRotasi === "string") {
    dcepatRotasi = dcepatRotasi
  } else {
    alert('error : parameter embed.sun(harus string)')
    return
  }
} else {
  dcepatRotasi = '60'
}
if (dtebalSinar) {
  if(typeof dtebalSinar === "string"){
  dtebalSinar = dtebalSinar
  } else {
    alert('error : parameter embed.sun(harus string)')
    return
  }
} else {
  dtebalSinar = '7'
}
if (arah) {
  if(typeof arah !== "string"){
    alert('error : parameter embed.sun(harus string)')
      return
  } else if (arah === 'r' || arah === 'l'){
    arah = arah
  } else {
    alert('isi parameter arah hanya ada dua pada embed.sun( r dan l )')
    return
  }
} else {
  arah = 'r'
}
if (dwarnaInti) {
  if (typeof dwarnaInti === "string") {
    dwarnaInti = dwarnaInti
  } else {
    alert('error : parameter embed.sun(harus string)')
    return
  }
} else {
  dwarnaInti = '#ffdb1a'
}
if (dwarnaSinar) {
  if (typeof dwarnaSinar === "string") {
    dwarnaSinar = dwarnaSinar
  } else {
    alert('error : parameter embed.sun(harus string)')
    return
  }
} else {
  dwarnaSinar = '#ffdb1a'
}
const csst = '<style>.sun-container'+cn+' {   position: relative;   width: 100%; /* Ukuran total matahari + sinar */   height: 100%; } /* 1. Inti Matahari (Updated dari sebelumnya) */ .sun-core'+cn+' {   position: absolute;   top: 50%;   left: 50%;   transform: translate(-50%, -50%); /* Sentralisasi sempurna */   width: '+dbesarInti+';   height: '+dbesarInti+';   background: '+dwarnaInti+';   border-radius: 50%;   box-shadow: 0 0 20px '+dwarnaInti+', 0 0 40px #ff8c00;   z-index: 2; /* Di atas sinar */ } /* 2. Sinar SVG Bergelombang */ .sun-beams'+cn+' {   position: absolute;   top: 0;   left: 0;   width: 100%;   height: 100%;   z-index: 1; /* Di bawah inti */      /* Animasi Sinar Berputar Lambat */   animation: rotateBeams'+arah+' '+dcepatRotasi+'s linear infinite; } /* Gaya untuk jalur sinar di dalam SVG */ .sun-beams'+cn+' use {   fill: none;   stroke: '+dwarnaSinar+'; /* Warna sinar sama dengan inti */   stroke-width: '+dtebalSinar+'; /* Ketebalan garis gelombang */   stroke-linecap: round; /* Ujung garis tumpul/halus */   opacity: 0.8; } /* Definisi Animasi Putaran */ @keyframes rotateBeamsr {   from { transform: rotate(0deg); }   to { transform: rotate(360deg); } }@keyframes rotateBeamsl {   from { transform: rotate(360deg); }   to { transform: rotate(0deg); } }</style>'
if (head) {
  head.innerHTML += csst
} else {
  head = document.createElement('head');
  head.innerHTML += csst
  document.html.appendChild(head)
}},
  moon: function(selectorParent){
         const m = '<div class="sky"><div class="bmoon"><div class="moon"></div></div></div>'
         document.querySelector(selectorParentParent).innerHTML += m
         const stlMon1 = '<style>.sky {position: relative; width: 100%;height: 100%;overflow: visible;}.moon {position: relative;width: 100%;height: 100%;border-radius: 50%;box-shadow: 30px 10px 0 0 #f6e58d;filter: drop-shadow(0 0 30px #f9ca24);animation: float 6s ease-in-out infinite;}@keyframes float {0% , 100% {transform: translateY(0) rotate(-10deg);}50% {transform: translateY(-20px) rotate(5deg);}}.star {position: absolute;background: white;border-radius: 50%;opacity: 0.5;animation: twinkle 2s infinite ease-in-out;}.s1 { top: 10% ;left: 20% ;width: 3px;height: 3px;}.s2 {top: 30% ;left: 70%;width: 2px;height: 2px;animation-delay: 1s; }.s3 { top: 50% ;left: 15% ;width: 4px;height: 4px;animation-delay: 0.5s; }@keyframes twinkle {0% , 100% { opacity: 0.3;transform: scale(1); }50% { opacity: 1;transform: scale(1.2); }}.bmoon {padding: 20px;width: 95% ;height: 95% ;transform: translateX(-18%);box-sizing: border-box;}</style>'
 let head = document.querySelector('head')
 if (head) {
  head.innerHTML += stlMon1
} else {
  head = document.createElement('head');
  head.innerHTML += stlMon1
  document.html.appendChild(head)
}}
}


const animasi = {
  ketik: function (durasi, idteks, teksAsli, lanjut, idkursor, kursor,) {
  $(idkursor).append(kursor)
  let i = 0;
  function kt() {
    if (i < teksAsli.length) {
      if (teksAsli.substr(i, 4) === "<br>") {
        $(idteks).html(teksAsli.substr(0, i + 4));
        i += 4;
      } else {
        $(idteks).html(teksAsli.substr(0, i + 1));
        i++;
      }
      setTimeout(kt, durasi);
    } else {
      lanjut()
    }
  }
   kt();
 }}
