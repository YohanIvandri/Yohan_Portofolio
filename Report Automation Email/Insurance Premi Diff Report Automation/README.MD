# 📊 Report Automation Premi Asuransi DIFF

🚀 Tujuan :Automated Reporting ini bertujuan untuk membantu tim asuransi dalam mengontrol pengajuan cover asuransi dengan 
           mengidentifikasi perbedaan nominal premi yang dibayarkan oleh konsumen saat proses akuisisi dengan premi yang akan 
           dibayarkan oleh PT MCF dan MAF kepada rekan maskapai asuransi.

           
🚀 Assignment : Output dari Automated Reporting ini berupa laporan harian yang dikirimkan secara otomatis melalui email, 
                 menampilkan data perbedaan nominal premi untuk membantu tim asuransi dalam pengawasan dan pengambilan keputusan

📌 Alur Proses

1. Membuat Stored Procedure untuk Generate Data

* Stored Procedure ini bertugas untuk mengambil data dari database dan menyimpannya dalam bentuk tabel yang siap digunakan dalam proses berikutnya.
* Proses ini memastikan bahwa data yang akan dianalisis sudah dalam format yang sesuai dan dapat digunakan

2. Membuat Stored Procedure untuk Proses Kirim Email

   Stored Procedure ini bertugas untuk mengirimkan hasil perbandingan premi melalui email ke tim asuransi. Proses ini mencakup:

* Menjalankan query untuk menghasilkan data premi dalam format CSV.
* Mengompres file hasil query agar lebih ringkas.
* Mengambil informasi penerima email dari tabel, sehingga pengiriman dapat dilakukan secara otomatis ke tujuan yang telah ditentukan tanpa perlu input manual.

3. Menjadwalkan Pengiriman Email dengan Job Schedule

   Proses ini mengotomatiskan pengiriman laporan dengan menjalankan Stored Procedure email menggunakan Job Schedule. Dengan ini, laporan premi dapat dikirim secara berkala tanpa perlu intervensi manual.
   
📂 Struktur Repository


📌 Catatan

💡 Data yang digunakan hanya sampel dan telah dianonimkan.📌 Silakan coba query ini pada dataset lain untuk eksplorasi lebih lanjut.



           
