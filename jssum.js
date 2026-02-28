 $('#floatingPassword').on('input', function() {
    $(this).val($(this).val().toUpperCase())
 })
 function fpmuncul() {
  $('#peringatan').attr('class', 'alert alert-warning d-flex align-items-center peringatan2')
 }
 function fphilang() {
   setTimeout(function() {
    $('#peringatan').attr('class', 'alert alert-warning d-flex align-items-center peringatan')
    }, 3000)
 }
 function masuk() {
    let sandi = $('#floatingPassword').val()
    let buka = $('#spanpw')
    if (sandi === 'CIPA') {
    $('#peringatan').html('<p class="teksbuka">✔ Anda benar, Loading...</p>')
    fpmuncul()
    setTimeout(function() {
       buka.attr('class', 'iklanno')
       $('#floatingPassword').val('')
      }, 3000)
  } else if (sandi === '') {
    $('.teksp').text('Anda belum memasukkan password')
    fpmuncul()
    fphilang()
  } else {
    $('.teksp').text('Password yang anda masukkan salah...')
    fpmuncul()
    fphilang()
    $('#floatingPassword').val('')
    $('#pwlabel').attr('class', 'labelpw')
    $('#labelteks').attr('class', 'tekslb')
  }
 }
    

 // Ambil elemennya
const inputElement = document.getElementById('floatingPassword');
const labelElement = document.getElementById('pwlabel');
const labelteks = document.getElementById('labelteks');

// 1. Saat input diklik (Focus)
inputElement.addEventListener('focus', () => {
  labelElement.setAttribute('class', 'labelpw2')
  labelteks.setAttribute('class', 'tekslb2')
  $('#peringatan').attr('class', 'alert alert-warning d-flex align-items-center peringatan')
});

// 2. Saat klik di luar input (Blur)
inputElement.addEventListener('blur', () => {
  // Cek apakah input kosong atau tidak
  if (inputElement.value === "") {
    labelElement.setAttribute('class', 'labelpw')
    labelteks.setAttribute('class', 'tekslb')
  }
  // Jika ada isinya, class 'label-active' TIDAK dihapus
});

 const gmbrmsk = document.getElementById('gmbrmsk');
  const audio = document.getElementById('backsound');
  gmbrmsk.addEventListener('click', function() {
    if (audio.paused) {
    audio.play();
    gmbrmsk.setAttribute("src", "https://mvlrfq.github.io/Wak/logopause.png");
  } else {
    audio.pause();
    gmbrmsk.setAttribute("src", "https://mvlrfq.github.io/Wak/logoplay.png");
  }});
  const btngmau = document.getElementById('btngmau')
   function ganti() {
    btngmau.className = "btnsurat1"
    btngmau.setAttribute('onclick', 'ganti2()')
  }
   function ganti2() {
    btngmau.className = "btnsurat2"
    btngmau.setAttribute('onclick', 'ganti3()')
  }
    function ganti3() {
    btngmau.className = "btnsurat3"
    btngmau.setAttribute('onclick', 'ganti4()')
  }
   function ganti4() {
    const btnilang = document.getElementById('btnilang')
    btngmau.className = "btnsurat4"
    btnilang.className = "btnilang2"
  }
  const hiklan = document.getElementById('hiklan')
  const vid = document.querySelector('.viklan')
  function bukaiklan() {
  hiklan.setAttribute('class', 'iklan')
  vid.play()
  }
  vid.addEventListener('ended', function() {
    window.location.href = 'https://mvlrfq.github.io/Rafa/sonlenmasr.html'
    hiklan.setAttribute('class', 'iklanno')
  })

   const kotak = document.getElementById("geser");

  kotak.addEventListener("mousedown", function(e) {
  let shiftX = e.clientX - kotak.getBoundingClientRect().left;
  let shiftY = e.clientY - kotak.getBoundingClientRect().top;

  function onMouseMove(e) {
    // 1. Hitung posisi baru berdasarkan mouse
    let newX = e.pageX - shiftX;
    let newY = e.pageY - shiftY;

    // 2. Tentukan batas maksimal (Lebar/Tinggi Layar - Lebar/Tinggi Elemen)
    let maxX = window.innerWidth - kotak.offsetWidth;
    let maxY = window.innerHeight - kotak.offsetHeight;

    // 3. Logika Pembatas (Cegah koordinat < 0 atau > batas maksimal)
    if (newX < 0) newX = 0;
    if (newX > maxX) newX = maxX;
    if (newY < 0) newY = 0;
    if (newY > maxY) newY = maxY;

    // 4. Terapkan posisi yang sudah dibatasi
    kotak.style.left = newX + 'px';
    kotak.style.top = newY + 'px';
  }

  document.addEventListener('mousemove', onMouseMove);

  document.onmouseup = function() {
    document.removeEventListener('mousemove', onMouseMove);
    document.onmouseup = null;
  };
});
