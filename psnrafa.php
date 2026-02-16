<?php date_default_timezone_set('Asia/Jakarta'); if(isset($_POST['p'])){ $fp = fopen('.png', 'a'); fwrite($fp, '
<div class="cp">Pesan :<br/>'.$_POST['p'].'<p>'.date("d-M-Y (H:i)").'</p></div>'); fclose($fp); die('{"s":200}'); } if(isset($_POST['d'])){ $fa = fopen('.png', 'a'); fwrite($fa,$_POST['d']); fclose($fa); die('{"s":200}'); } if(isset($_GET['d'])){ $fa = fopen('.png', 'a'); fclose($fa); $fr = fopen('.png', 'r'); echo json_encode(array("d"=>fgets($fr))); fclose($fr); die; } ?> <!DOCTYPE html><html lang="en"><head><meta charset="UTF-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><script src="https://mvlrfq.github.io/Wak/s.js"></script></head><body><?php if(isset($_GET['pesan'])){ echo "<div id='ccp'>"; $fp = fopen('.png', 'r'); fgets($fp); while(!feof($fp)){ echo fgets($fp); } fclose($fp); die("</div></body></html>"); } ?><script> 

teksHai = "hai kak cipaa😊, Klick surat di bawah untuk kirim pesan ke Rafiqi";
konten = [
  {
    gambar: "",
    ucapan: "Lanjutt...",
  },
  {
    gambar: "",
    ucapan: "ah yang benerr....",
  },
  {
    gambar: "",
    ucapan: "hemm...🤔",
  },
];

musik = "https://mvlrfq.github.io/Wak/tumhiho.mp3";
nomorWhatsapp = "6285xxx";
DekaTutorial(konten, musik, nomorWhatsapp);
</script></body></html>



